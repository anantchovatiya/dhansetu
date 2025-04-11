import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import 'dart:math' as Math;

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId;
  
  // Fixed test UID for debugging purposes
  static const String DEBUG_TEST_UID = "ulwuhYNDZBcliSbdlBhyKGa4OQt2"; // The UID that all expenses show up for

  ExpenseService(this._userId) {
    print('ExpenseService initialized with userId: $_userId');
    print('Is this the DEBUG_TEST_UID? ${_userId == DEBUG_TEST_UID ? "YES" : "NO"}');
  }

  // Get expenses stream with diagnostic logging
  Stream<List<Expense>> get expenses {
    print('Fetching expenses stream for userId: $_userId');
    
    if (_userId.isEmpty) {
      print('ERROR: Empty userId in expenses stream, returning empty list');
      return Stream.value([]);
    }
    
    // Log if we're using the special debug UID
    if (_userId == DEBUG_TEST_UID) {
      print('ATTENTION: Using the debug test UID that always shows expenses');
    }
    
    // First log all expenses to see what's going on
    _firestore
        .collection('expenses')
        .get()
        .then((snapshot) {
          print('DIAGNOSTIC: Found ${snapshot.docs.length} total expenses in Firestore');
          
          // Count expenses by userId to see distribution
          final countByUserId = <String, int>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final expenseUserId = data['userId'] as String? ?? 'MISSING_USER_ID';
            countByUserId[expenseUserId] = (countByUserId[expenseUserId] ?? 0) + 1;
            
            // Log only the debug UID expenses
            if (expenseUserId == DEBUG_TEST_UID) {
              print('DEBUG UID EXPENSE: ${doc.id} - ${data.toString()}');
            }
          }
          
          // Show counts by user ID
          print('EXPENSE COUNTS BY USER ID:');
          countByUserId.forEach((userId, count) {
            print('  - $userId: $count expenses${userId == _userId ? " (current user)" : ""}${userId == DEBUG_TEST_UID ? " (debug UID)" : ""}');
          });
        })
        .catchError((e) => print('Error in diagnostic query: $e'));
    
    // Now perform our filtered query
    print('Running filtered query with userId: $_userId');
    
    // For debugging, try querying with the debug UID as well
    if (_userId != DEBUG_TEST_UID) {
      _firestore
          .collection('expenses')
          .where('userId', isEqualTo: DEBUG_TEST_UID)
          .get()
          .then((snapshot) {
            print('DEBUG: Query with DEBUG_TEST_UID returned ${snapshot.docs.length} expenses');
          });
    }
    
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Got ${snapshot.docs.length} expenses from Firestore for user $_userId');
      
      // Debug: print each document to check data
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Verify this expense belongs to the current user
        final expenseUserId = data['userId'] as String? ?? '';
        if (expenseUserId != _userId) {
          print('WARNING: Found expense with mismatched userId: ${doc.id} - belongs to $expenseUserId but current user is $_userId');
          continue; // Skip this expense
        }
        print('Expense found for $_userId: ${doc.id} - ${doc.data()}');
      }
      
      return snapshot.docs
        .map((doc) {
          final data = doc.data();
          // Double-check that this expense belongs to the current user
          if (data['userId'] != _userId) {
            print('Skipping expense ${doc.id} - wrong userId');
            return null;
          }
          data['id'] = doc.id; // Add document ID to the data
          return Expense.fromFirestore(data);
        })
        .where((expense) => expense != null) // Filter out null values
        .cast<Expense>() // Cast to non-nullable Expense
        .toList();
    });
  }

  // Add new expense
  Future<void> addExpense(Expense expense) async {
    try {
      print('Adding expense for userId: $_userId');
      
      if (_userId.isEmpty) {
        print('ERROR: Cannot add expense - userId is empty');
        throw Exception('User ID is required to add an expense');
      }
      
      // Always override the userId with the current user's ID to ensure security
      String actualUserId = _userId;
      
      // Debug original expense
      print('Original expense userId: ${expense.userId}');
      if (expense.userId != actualUserId && expense.userId.isNotEmpty) {
        print('WARNING: Expense has incorrect userId. Replacing ${expense.userId} with $actualUserId');
      }
      
      // Ensure the date includes time component (set to noon if not specified)
      final date = expense.date;
      final dateWithTime = DateTime(
        date.year, 
        date.month, 
        date.day,
        date.hour > 0 || date.minute > 0 ? date.hour : 12,
        date.minute,
        date.second
      );
      
      print('Original date: ${date.toString()}, with time: ${dateWithTime.toString()}');
      
      final expenseData = {
        'userId': actualUserId,  // Always use the service's userId
        'amount': expense.amount,
        'description': expense.description,
        'category': expense.category,
        'date': Timestamp.fromDate(dateWithTime),
        'type': expense.type.toString().split('.').last,
      };
      print('Expense data to be added: $expenseData');
      
      final docRef = await _firestore.collection('expenses').add(expenseData);
      print('Expense added successfully with ID: ${docRef.id} for user: $actualUserId');
      
      // Verify it was added correctly
      final addedDoc = await docRef.get();
      if (addedDoc.exists) {
        final data = addedDoc.data()!;
        print('Verification - Added expense data: ${data.toString()}');
        final storedUserId = data['userId'] as String? ?? 'MISSING';
        if (storedUserId != actualUserId) {
          print('ERROR: Stored userId ($storedUserId) doesn\'t match expected userId ($actualUserId)');
        } else {
          print('SUCCESS: Expense was added with correct userId: $storedUserId');
        }
      }
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  // Update expense
  Future<void> updateExpense(String expenseId, Expense expense) async {
    try {
      print('Updating expense with ID: $expenseId for user: $_userId');
      
      // First verify this expense belongs to the current user
      final docSnap = await _firestore.collection('expenses').doc(expenseId).get();
      if (!docSnap.exists) {
        throw Exception('Expense not found');
      }
      
      final data = docSnap.data()!;
      final expenseUserId = data['userId'] as String? ?? '';
      
      if (expenseUserId != _userId) {
        print('ERROR: Cannot update expense belonging to another user: $expenseUserId');
        throw Exception('Cannot update expense belonging to another user');
      }
      
      // Now update the expense, making sure to keep the userId
      await _firestore.collection('expenses').doc(expenseId).update({
        'userId': _userId, // Ensure userId stays the same and matches current user
        'amount': expense.amount,
        'description': expense.description,
        'category': expense.category,
        'date': Timestamp.fromDate(expense.date),
        'type': expense.type.toString().split('.').last,
      });
      print('Expense updated successfully for user: $_userId');
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      print('Attempting to delete expense with ID: $expenseId for user: $_userId');
      
      // First verify this expense belongs to the current user
      final docSnap = await _firestore.collection('expenses').doc(expenseId).get();
      if (!docSnap.exists) {
        throw Exception('Expense not found');
      }
      
      final data = docSnap.data()!;
      final expenseUserId = data['userId'] as String? ?? '';
      
      if (expenseUserId != _userId) {
        print('ERROR: Cannot delete expense belonging to another user: $expenseUserId');
        throw Exception('Cannot delete expense belonging to another user');
      }
      
      // Now delete the expense
      await _firestore.collection('expenses').doc(expenseId).delete();
      print('Expense deleted successfully for user: $_userId');
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      print('Getting expenses by date range for userId: $_userId');
      print('Date range: ${start.toString()} to ${end.toString()}');
      
      if (_userId.isEmpty) {
        print('ERROR: userId is empty, cannot fetch expenses');
        return [];
      }
      
      // Normalize start date to beginning of day
      final normalizedStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
      
      // Normalize end date to end of day
      final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
      
      print('Normalized date range: ${normalizedStart.toString()} to ${normalizedEnd.toString()}');
      
      final query = _firestore
          .collection('expenses')
          .where('userId', isEqualTo: _userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(normalizedEnd))
          .orderBy('date', descending: true);
          
      print('Executing Firestore query for user: $_userId');
      
      final snapshot = await query.get();
      
      print('Got ${snapshot.docs.length} expenses by date range');
      
      if (snapshot.docs.isEmpty) {
        print('No expenses found in date range for user: $_userId');
      } else {
        // Debug log first few expenses
        for (var i = 0; i < Math.min(3, snapshot.docs.length); i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          // Verify this expense belongs to the current user
          if (data['userId'] != _userId) {
            print('WARNING: Found expense with mismatched userId: ${doc.id}');
            continue;
          }
          print('Sample expense $i: ${doc.id} - ${doc.data()}');
        }
      }

      return snapshot.docs
        .map((doc) {
          final data = doc.data();
          // Double-check that this expense belongs to the current user
          if (data['userId'] != _userId) {
            print('Skipping expense ${doc.id} - wrong userId');
            return null;
          }
          data['id'] = doc.id; // Add document ID to the data
          return Expense.fromFirestore(data);
        })
        .where((expense) => expense != null) // Filter out null values
        .cast<Expense>() // Cast to non-nullable Expense
        .toList();
    } catch (e) {
      print('Error getting expenses by date range: $e');
      // Return empty list instead of throwing to prevent UI crashes
      return [];
    }
  }

  // Get total expenses for a specific period
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    try {
      print('Getting total expenses for user: $_userId');
      print('Date range for total: ${start.toString()} to ${end.toString()}');
      
      if (_userId.isEmpty) {
        print('ERROR: userId is empty, cannot calculate total expenses');
        return 0;
      }
      
      final expenses = await getExpensesByDateRange(start, end);
      final total = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
      print('Total expenses for $_userId: $total from ${expenses.length} expenses');
      return total;
    } catch (e) {
      print('Error getting total expenses: $e');
      // Return 0 instead of throwing
      return 0;
    }
  }

  // Get expenses by category
  Future<Map<String, double>> getExpensesByCategory(DateTime start, DateTime end) async {
    try {
      print('Getting expenses by category for user: $_userId');
      final expenses = await getExpensesByDateRange(start, end);
      final categoryTotals = <String, double>{};
      
      for (var expense in expenses) {
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
      
      print('Category totals: $categoryTotals');
      return categoryTotals;
    } catch (e) {
      print('Error getting expenses by category: $e');
      // Return empty map instead of throwing
      return {};
    }
  }

  // Utility method to fix expense user IDs (call this only when needed for debugging)
  Future<void> debugFixExpenseUserIds() async {
    try {
      print('DEBUG UTILITY: Starting fix of expense user IDs');
      
      final correctUserId = _userId; // The current user's ID
      final wrongUserId = DEBUG_TEST_UID; // The hardcoded UID that shows expenses for all users
      
      print('Will update expenses from wrong UID: $wrongUserId to correct UID: $correctUserId');
      
      // If current user is already the debug UID, we can't fix the expenses
      if (correctUserId == wrongUserId) {
        print('ERROR: Current user is the debug UID, cannot fix expenses');
        return;
      }
      
      // Get all expenses from wrong user ID
      final snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: wrongUserId)
          .get();
      
      print('Found ${snapshot.docs.length} expenses with wrong userId to fix');
      
      // Keep track of changes
      int updatedCount = 0;
      int errorCount = 0;
      
      // Process each expense
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('Updating expense: ${doc.id} - ${data.toString()}');
          
          // Update the expense with the correct userId
          await doc.reference.update({'userId': correctUserId});
          print('Updated expense ${doc.id} from $wrongUserId to $correctUserId');
          updatedCount++;
        } catch (e) {
          print('Error processing expense ${doc.id}: $e');
          errorCount++;
        }
      }
      
      print('DEBUG UTILITY COMPLETE:');
      print('  - Total expenses with wrong userId: ${snapshot.docs.length}');
      print('  - Updated: $updatedCount');
      print('  - Errors: $errorCount');
      
    } catch (e) {
      print('Error in debugFixExpenseUserIds: $e');
    }
  }
} 