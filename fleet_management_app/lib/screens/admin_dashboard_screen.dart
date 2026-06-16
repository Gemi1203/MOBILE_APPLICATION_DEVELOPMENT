import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'analytics_screen.dart';
import 'fleet_overview_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<void> _deleteUser(String uid, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _firestore.collection('users').doc(uid).delete();
      await _logAction('Deleted user', email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$email deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeRole(
    String uid,
    String currentRole,
    String newRole,
    String email,
  ) async {
    if (currentRole == newRole) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Role'),
        content: Text('Set $email as $newRole?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      await _logAction('Changed role', '$email from $currentRole to $newRole');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated to $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logAction(String action, String details) async {
    await _firestore.collection('admin_logs').add({
      'action': action,
      'details': details,
      'adminId': FirebaseAuth.instance.currentUser?.uid,
      'adminEmail': FirebaseAuth.instance.currentUser?.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.amber;
      case 'manager':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppTheme.appName} · Admin',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey[900],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard, color: Colors.white70),
                title: const Text(
                  'User Management',
                  style: TextStyle(color: Colors.white),
                ),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
              // ✅ Fleet Overview – added and working
              ListTile(
                leading: const Icon(
                  Icons.directions_car,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Fleet Overview',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FleetOverviewScreen(),
                    ),
                  );
                },
              ),
              // ✅ Analytics – added and working
              ListTile(
                leading: const Icon(Icons.analytics, color: Colors.white70),
                title: const Text(
                  'Analytics',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs;
          List<QueryDocumentSnapshot> filteredUsers = users;
          if (_searchQuery.isNotEmpty) {
            filteredUsers = users.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toLowerCase();
              final email = (data['email'] ?? '').toLowerCase();
              final query = _searchQuery.toLowerCase();
              return name.contains(query) || email.contains(query);
            }).toList();
          }

          int total = users.length;
          int admins = 0, managers = 0, drivers = 0;
          for (var doc in users) {
            final role = doc.get('role');
            if (role == 'admin') {
              admins++;
            } else if (role == 'manager') {
              managers++;
            } else {
              drivers++;
            }
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade800,
                      Colors.purple.shade700,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    _buildStatCard(
                      'Total Users',
                      total.toString(),
                      Icons.people,
                      Colors.white70,
                    ),
                    _buildStatCard(
                      'Admins',
                      admins.toString(),
                      Icons.admin_panel_settings,
                      Colors.amber.shade300,
                    ),
                    _buildStatCard(
                      'Managers',
                      managers.toString(),
                      Icons.manage_accounts,
                      Colors.lightBlue.shade300,
                    ),
                    _buildStatCard(
                      'Drivers',
                      drivers.toString(),
                      Icons.directions_car,
                      Colors.lightGreen.shade300,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: filteredUsers.length,
                        itemBuilder: (_, i) {
                          final doc = filteredUsers[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final uid = doc.id;
                          final email = data['email'] ?? '';
                          final name = data['name'] ?? 'No name';
                          final role = data['role'] ?? 'driver';
                          final currentUserUid = _auth.currentUser?.uid;
                          final isSelf = uid == currentUserUid;

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: _getRoleColor(
                                      role,
                                    ).withValues(alpha: 0.2),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _getRoleColor(role),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(
                                              role,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            role.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getRoleColor(role),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'delete' && !isSelf) {
                                        await _deleteUser(uid, email);
                                      } else if (value == 'make_admin') {
                                        await _changeRole(
                                          uid,
                                          role,
                                          'admin',
                                          email,
                                        );
                                      } else if (value == 'make_manager') {
                                        await _changeRole(
                                          uid,
                                          role,
                                          'manager',
                                          email,
                                        );
                                      } else if (value == 'make_driver') {
                                        await _changeRole(
                                          uid,
                                          role,
                                          'driver',
                                          email,
                                        );
                                      } else if (value == 'delete' && isSelf) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You cannot delete yourself.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      if (!isSelf)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            'Delete User',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      const PopupMenuItem(
                                        value: 'make_admin',
                                        child: Text('Set as Admin'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'make_manager',
                                        child: Text('Set as Manager'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'make_driver',
                                        child: Text('Set as Driver'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
