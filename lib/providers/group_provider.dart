import 'package:flutter/foundation.dart';
import '../models/group.dart';

class GroupProvider with ChangeNotifier {
  Group? _currentGroup;
  String? _error;

  Group? get currentGroup => _currentGroup;
  String? get error => _error;

  void createGroup(String name) {
    try {
      _currentGroup = Group(
        name: name,
        members: [],
        expenses: [],
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create group: $e';
      notifyListeners();
    }
  }

  void addMember(String name) {
    try {
      if (_currentGroup == null) {
        throw Exception('No group created');
      }

      if (_currentGroup!.members.any((m) => m.name == name)) {
        throw Exception('Member already exists');
      }

      _currentGroup!.members.add(GroupMember(name: name));
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add member: $e';
      notifyListeners();
    }
  }

  void addExpense({
    required String description,
    required double amount,
    required String paidByName,
    required List<String> sharedByNames,
  }) {
    try {
      if (_currentGroup == null) {
        throw Exception('No group created');
      }

      final payer = _currentGroup!.members.firstWhere(
        (m) => m.name == paidByName,
        orElse: () => throw Exception('Payer not found'),
      );

      final sharedBy = sharedByNames.map((name) {
        return _currentGroup!.members.firstWhere(
          (m) => m.name == name,
          orElse: () => throw Exception('Member not found: $name'),
        );
      }).toList();

      if (sharedBy.isEmpty) {
        throw Exception('No members selected to share the expense');
      }

      // Calculate equal shares
      final share = amount / sharedBy.length;
      final individualShares = {
        for (var member in sharedBy) member.name: share,
      };

      // Create and add the expense
      final expense = GroupExpense(
        description: description,
        amount: amount,
        paidByName: paidByName,
        sharedByNames: sharedByNames,
        individualShares: individualShares,
      );

      _currentGroup!.expenses.add(expense);

      // Update member totals
      payer.totalPaid += amount;
      for (var member in sharedBy) {
        member.totalShare += share;
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add expense: $e';
      notifyListeners();
    }
  }

  Map<String, List<Map<String, dynamic>>> calculateSettlements() {
    try {
      if (_currentGroup == null) {
        throw Exception('No group created');
      }

      if (_currentGroup!.expenses.isEmpty) {
        return {};
      }

      final settlements = <String, List<Map<String, dynamic>>>{};

      // Calculate net amounts (paid - share) for each member
      final netAmounts = <String, double>{};
      for (var member in _currentGroup!.members) {
        netAmounts[member.name] = member.totalPaid - member.totalShare;
      }

      // Find who owes whom
      for (var debtor in _currentGroup!.members) {
        if (netAmounts[debtor.name]! < -0.01) { // Negative means they owe money
          final debtorSettlements = <Map<String, dynamic>>[];

          for (var creditor in _currentGroup!.members) {
            if (netAmounts[creditor.name]! > 0.01) { // Positive means they are owed money
              final debtAmount = -netAmounts[debtor.name]!;
              final creditAmount = netAmounts[creditor.name]!;
              final settlementAmount = debtAmount < creditAmount ? debtAmount : creditAmount;

              if (settlementAmount > 0.01) {
                debtorSettlements.add({
                  'to': creditor.name,
                  'amount': settlementAmount,
                });

                netAmounts[debtor.name] = netAmounts[debtor.name]! + settlementAmount;
                netAmounts[creditor.name] = netAmounts[creditor.name]! - settlementAmount;
              }
            }
          }

          if (debtorSettlements.isNotEmpty) {
            settlements[debtor.name] = debtorSettlements;
          }
        }
      }

      _error = null;
      return settlements;
    } catch (e) {
      _error = 'Failed to calculate settlements: $e';
      notifyListeners();
      return {};
    }
  }

  void reset() {
    _currentGroup = null;
    _error = null;
    notifyListeners();
  }
} 