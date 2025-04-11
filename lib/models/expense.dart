import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { income, expense }

class Expense {
  final String? id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final ExpenseType type;
  final String userId;

  Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.type,
    this.userId = '',
  });

  factory Expense.fromFirestore(Map<String, dynamic> data) {
    try {
      final date = (data['date'] as Timestamp).toDate();
      print('Parsing expense date: ${date.toString()} at ${date.hour}:${date.minute}:${date.second}');
      
      return Expense(
        id: data['id'] as String?,
        amount: (data['amount'] as num).toDouble(),
        description: data['description'] as String,
        category: data['category'] as String,
        date: date,
        type: ExpenseType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => ExpenseType.expense,
        ),
        userId: data['userId'] as String? ?? '',
      );
    } catch (e) {
      print('Error parsing Expense from Firestore: $e');
      return Expense(
        amount: 0,
        description: 'Error loading expense',
        category: 'Unknown',
        date: DateTime.now(),
        type: ExpenseType.expense,
        userId: '',
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'type': type.toString().split('.').last,
      'userId': userId,
    };
  }

  Expense copyWith({
    String? id,
    double? amount,
    String? description,
    String? category,
    DateTime? date,
    ExpenseType? type,
    String? userId,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }
} 