import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String name;
  final List<GroupMember> members;
  final List<GroupExpense> expenses;

  Group({
    required this.name,
    required this.members,
    required this.expenses,
  });

  double get totalAmount => expenses.fold(0, (sum, expense) => sum + expense.amount);
}

class GroupMember {
  final String name;
  double totalPaid;
  double totalShare;

  GroupMember({
    required this.name,
    this.totalPaid = 0,
    this.totalShare = 0,
  });
}

class GroupExpense {
  final String description;
  final double amount;
  final String paidByName;
  final List<String> sharedByNames;
  final Map<String, double> individualShares;

  GroupExpense({
    required this.description,
    required this.amount,
    required this.paidByName,
    required this.sharedByNames,
    required this.individualShares,
  });
} 