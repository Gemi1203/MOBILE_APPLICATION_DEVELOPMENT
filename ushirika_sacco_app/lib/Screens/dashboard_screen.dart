import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../store/sacco_store.dart';

class FinanceDashboardScreen extends StatefulWidget {
  final SaccoStore store;
  const FinanceDashboardScreen({super.key, required this.store});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final totalSavings = widget.store.totalSavings;
    final totalLoan = widget.store.activeLoanBalance;
    final eligibility = widget.store.eligibility;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ushirika SACCO'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Screen 3',
              style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome, ${widget.store.memberName}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Your cooperative finance health at a glance.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildMetricCard('Total Savings', totalSavings, Colors.green),
                _buildMetricCard(
                    'Active Loan Balance', totalLoan, Colors.orange),
                _buildMetricCard(
                    'Loan Eligibility (3x)', eligibility, Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.store.setTab(3),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Record Savings'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.store.setTab(4),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply for Loan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed Out')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text('Recent Savings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDataTable(
              columns: const ['Date', 'Amount', 'Channel'],
              rows: widget.store.savingsEntries
                  .take(5)
                  .map<List<String>>((s) => [
                        DateFormat('dd MMM yyyy').format(s.date),
                        'KES ${NumberFormat('#,###').format(s.amount)}',
                        s.channel,
                      ])
                  .toList(),
            ),
            const SizedBox(height: 32),
            const Text('Loan Requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            widget.store.loans.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No loan requests yet.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : _buildDataTable(
                    columns: const ['Amount', 'Period', 'Status'],
                    rows: widget.store.loans
                        .take(5)
                        .map<List<String>>((l) => [
                              'KES ${NumberFormat('#,###').format(l.amount)}',
                              '${l.periodMonths} months',
                              l.status,
                            ])
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, double value, Color accentColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              'KES ${NumberFormat('#,###').format(value)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      {required List<String> columns, required List<List<String>> rows}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
            columns:
                columns.map((col) => DataColumn(label: Text(col))).toList(),
            rows: rows.map((row) {
              return DataRow(
                cells: row.map((cell) => DataCell(Text(cell))).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
