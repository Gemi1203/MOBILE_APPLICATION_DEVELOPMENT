import 'package:flutter/material.dart';
import 'store/sacco_store.dart';
import 'screens/home_screen.dart';
import 'screens/member_access_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/savings_ledger_screen.dart';
import 'screens/loan_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;
  final SaccoStore _store = SaccoStore();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _store.addListener(() {
      setState(() {
        _selectedIndex = _store.currentTab;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(store: _store),
      MemberAccessScreen(store: _store),
      FinanceDashboardScreen(store: _store),
      SavingsLedgerScreen(store: _store),
      LoanScreen(store: _store),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.request_page), label: 'Loans'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }
}
