import 'package:flutter/material.dart';

class LoanRequest {
  final double amount;
  final int periodMonths;
  final String purpose;
  String status;

  LoanRequest({
    required this.amount,
    required this.periodMonths,
    required this.purpose,
    this.status = 'Pending',
  });
}

class SavingsEntry {
  final double amount;
  final String channel;
  final DateTime date;

  SavingsEntry({
    required this.amount,
    required this.channel,
    required this.date,
  });
}

class SaccoStore extends ChangeNotifier {
  int _currentTab = 0;
  int get currentTab => _currentTab;

  String memberName = 'Amina Wanjiku';
  String memberNumber = 'SAC-1023';
  String phone = '+254712345678';

  final List<SavingsEntry> savingsEntries = [
    SavingsEntry(amount: 5000, channel: 'M-Pesa', date: DateTime(2026, 6, 5)),
    SavingsEntry(amount: 3000, channel: 'Bank', date: DateTime(2026, 5, 28)),
    SavingsEntry(amount: 4500, channel: 'M-Pesa', date: DateTime(2026, 5, 15)),
    SavingsEntry(amount: 2500, channel: 'Cash', date: DateTime(2026, 5, 1)),
  ];

  final List<LoanRequest> loans = [];

  double get totalSavings =>
      savingsEntries.fold(0.0, (sum, e) => sum + e.amount);

  double get eligibility => totalSavings * 3;

  double get activeLoanBalance => loans
      .where((l) => l.status == 'Approved')
      .fold(0.0, (sum, l) => sum + l.amount);

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  void addSavings(double amount, String channel) {
    savingsEntries.insert(
      0,
      SavingsEntry(amount: amount, channel: channel, date: DateTime.now()),
    );
    notifyListeners();
  }

  void addLoan(LoanRequest loan) {
    loans.add(loan);
    notifyListeners();
  }
}
