import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../store/sacco_store.dart';
import '../widgets/glass_card.dart';

String money(double amount) => 'KES ${NumberFormat('#,###').format(amount)}';

void showAddLoanSheet(BuildContext context, SaccoStore store) {
  final amountController = TextEditingController();
  final purposeController = TextEditingController();
  int selectedMonths = 12;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Loan Request',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Max eligible: ${money(store.eligibility)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Loan Amount (KES)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: purposeController,
              decoration: InputDecoration(
                labelText: 'Purpose',
                hintText: 'e.g. Business capital',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedMonths,
              decoration: InputDecoration(
                labelText: 'Repayment Period',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [3, 6, 12, 18, 24]
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text('$m months')))
                  .toList(),
              onChanged: (val) => setModalState(() => selectedMonths = val!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim());
                  final purpose = purposeController.text.trim();
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid amount')),
                    );
                    return;
                  }
                  if (amount > store.eligibility) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Amount exceeds eligibility of ${money(store.eligibility)}')),
                    );
                    return;
                  }
                  store.addLoan(LoanRequest(
                    amount: amount,
                    periodMonths: selectedMonths,
                    purpose: purpose.isEmpty ? 'General' : purpose,
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '✅ Loan request of ${money(amount)} submitted!')),
                  );
                },
                child: const Text('Submit Loan Request'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoanScreen extends StatefulWidget {
  final SaccoStore store;
  const LoanScreen({super.key, required this.store});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxEligibility = widget.store.eligibility;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Screen 5',
          style: TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loan Application',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit your loan request',
                style: TextStyle(color: Color(0xFFBED7CC)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => showAddLoanSheet(context, widget.store),
                icon: const Icon(Icons.send_outlined),
                label: const Text('New Loan Request'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Eligibility Rule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Maximum request is 3× your total savings.',
                style: TextStyle(color: Color(0xFFBED7CC)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2019),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Current Max Loan',
                      style: TextStyle(color: Color(0xFFBED7CC)),
                    ),
                    const Spacer(),
                    Text(
                      money(maxEligibility),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF8D47A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Loan History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (widget.store.loans.isEmpty)
          const GlassCard(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No loan requests yet.',
                  style: TextStyle(color: Color(0xFFBED7CC)),
                ),
              ),
            ),
          )
        else
          ...widget.store.loans.reversed.map((loan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: ListTile(
                    title: Text(
                      money(loan.amount),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    subtitle:
                        Text('${loan.periodMonths} months • ${loan.purpose}'),
                    trailing: Chip(
                      label: Text(loan.status),
                      backgroundColor: loan.status.contains('Approved')
                          ? Colors.green.withOpacity(0.2)
                          : loan.status.contains('Rejected')
                              ? Colors.red.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                    ),
                  ),
                ),
              )),
        const SizedBox(height: 24),
      ],
    );
  }
}
