import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/auth_service.dart';

class ExpenseProvider with ChangeNotifier {
  final AuthService _authService;
  late ExpenseService _expenseService;
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _error;
  
  // Filters
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365)); // Show last year
  DateTime _endDate = DateTime.now().add(const Duration(days: 1)); // Include today and tomorrow
  
  ExpenseProvider(this._authService) {
    print('ExpenseProvider constructor called');
    _initialize();
  }
  
  // Getters
  List<Expense> get expenses => _expenses;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize provider
  Future<void> _initialize() async {
    print('Initializing ExpenseProvider');
    try {
      final user = _authService.currentUser;
      if (user != null) {
        print('Current user found: ${user.uid}, email: ${user.email}');
        
        // Add debug info about the user
        print('DEBUG User Info:');
        print('  - UID: ${user.uid}');
        print('  - Email: ${user.email}');
        print('  - Display Name: ${user.displayName}');
        print('  - Is Anonymous: ${user.isAnonymous}');
        print('  - Provider Data: ${user.providerData.map((p) => '${p.providerId}:${p.uid}').join(', ')}');
        
        _expenseService = ExpenseService(user.uid);
        
        // Listen for auth state changes
        _authService.authStateChanges.listen((user) {
          if (user != null) {
            print('Auth state changed, new user: ${user.uid}, email: ${user.email}');
            _expenseService = ExpenseService(user.uid);
            _setupExpenseListener();
          } else {
            print('User signed out');
            _expenses = [];
            _isLoading = false;
            notifyListeners();
          }
        });
        
        _setupExpenseListener();
      } else {
        print('No current user found');
        _isLoading = false;
        _error = 'Please sign in to view expenses';
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing expense provider: $e');
      _isLoading = false;
      _error = 'Failed to initialize: $e';
      notifyListeners();
    }
  }
  
  void _setupExpenseListener() {
    print('Setting up expense listener');
    _expenseService.expenses.listen(
      (expenses) {
        print('Received ${expenses.length} expenses from listener');
        _expenses = expenses;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        print('Error in expense stream: $e');
        _isLoading = false;
        _error = 'Error loading expenses: $e';
        notifyListeners();
      }
    );
  }
  
  // Expense methods
  Future<void> addExpense(Expense expense) async {
    try {
      print('Adding expense: ${expense.description}');
      await _expenseService.addExpense(expense);
      
      // Manually reload expenses to ensure UI updates
      print('Expense added, refreshing expenses list');
      await _refreshExpenses();
    } catch (e) {
      print('Error adding expense: $e');
      _error = 'Failed to add expense: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> updateExpense(String expenseId, Expense expense) async {
    try {
      print('Updating expense: $expenseId');
      await _expenseService.updateExpense(expenseId, expense);
    } catch (e) {
      print('Error updating expense: $e');
      _error = 'Failed to update expense: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> deleteExpense(String expenseId) async {
    try {
      print('Deleting expense: $expenseId');
      await _expenseService.deleteExpense(expenseId);
    } catch (e) {
      print('Error deleting expense: $e');
      _error = 'Failed to delete expense: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  // Filter methods
  void setDateRange(DateTime start, DateTime end) {
    print('Setting date range: ${start.toString()} to ${end.toString()}');
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }
  
  // Analytics methods
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    try {
      print('Getting total expenses from: ${start.toString()} to: ${end.toString()}');
      
      // Check if user is logged in
      final user = _authService.currentUser;
      if (user == null) {
        print('No user is signed in, returning 0');
        return 0;
      }
      
      print('Current user ID: ${user.uid}');
      
      final total = await _expenseService.getTotalExpenses(start, end);
      print('Total expenses returned: $total');
      return total;
    } catch (e) {
      print('Error getting total expenses: $e');
      return 0;
    }
  }
  
  Future<Map<String, double>> getExpensesByCategory(DateTime start, DateTime end) async {
    try {
      print('Getting expenses by category');
      return await _expenseService.getExpensesByCategory(start, end);
    } catch (e) {
      print('Error getting expenses by category: $e');
      return {};
    }
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    try {
      print('Getting expenses by date range');
      return await _expenseService.getExpensesByDateRange(start, end);
    } catch (e) {
      print('Error getting expenses by date range: $e');
      return [];
    }
  }

  // Add a method to force refresh expenses
  Future<void> refreshExpenses() async {
    try {
      print('Manually refreshing expenses list');
      _isLoading = true;
      notifyListeners();
      
      final user = _authService.currentUser;
      if (user != null) {
        print('Refreshing expenses for user: ${user.uid}');
        
        // Try to get expenses directly for a wide date range
        final expenses = await _expenseService.getExpensesByDateRange(
          DateTime(2000), // Far past date
          DateTime.now().add(const Duration(days: 365)), // Far future date
        );
        
        print('Refresh found ${expenses.length} expenses');
        
        if (expenses.isNotEmpty) {
          print('Found ${expenses.length} expenses directly from Firestore');
          _expenses = expenses;
        } else {
          print('No expenses found during refresh');
        }
        
        _isLoading = false;
        _error = null;
        notifyListeners();
      } else {
        print('Cannot refresh expenses: No user logged in');
        _isLoading = false;
        _error = 'Please sign in to view expenses';
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing expenses: $e');
      _isLoading = false;
      _error = 'Error refreshing: $e';
      notifyListeners();
    }
  }
  
  // Private version for internal use
  Future<void> _refreshExpenses() async {
    return refreshExpenses();
  }
} 