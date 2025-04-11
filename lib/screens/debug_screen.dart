import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../services/expense_service.dart';
import '../services/auth_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _logOutput = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addToLog('Debug screen initialized');
    _loadUserInfo();
  }

  void _addToLog(String message) {
    setState(() {
      _logOutput = '$message\n$_logOutput';
    });
    print(message);
  }

  Future<void> _loadUserInfo() async {
    final authProvider = Provider.of<UserAuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      _addToLog('Current user:');
      _addToLog('- UID: ${user.uid}');
      _addToLog('- Email: ${user.email}');
      _addToLog('- Display Name: ${user.displayName}');
      _addToLog('- Is Anonymous: ${user.isAnonymous}');
      
      // Check if this is the debug test UID
      if (user.uid == ExpenseService.DEBUG_TEST_UID) {
        _addToLog('WARNING: This is the DEBUG_TEST_UID!');
      } else {
        _addToLog('ISSUE: Your expenses may be showing under UID: ${ExpenseService.DEBUG_TEST_UID}');
      }
    } else {
      _addToLog('No user is currently logged in');
    }
  }

  Future<void> _diagnoseExpenses() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        _addToLog('Error: No user logged in');
        return;
      }
      
      _addToLog('Diagnosing expenses for user: $userId');
      
      // Create a temporary service
      final expenseService = ExpenseService(userId);
      
      // Get counts of expenses by user ID
      _addToLog('Fetching expense counts...');
      
      // This will log to console
      expenseService.expenses.first.then((expenses) {
        _addToLog('Found ${expenses.length} expenses for current user');
      });
      
    } catch (e) {
      _addToLog('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fixExpenseUserIds() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        _addToLog('Error: No user logged in');
        return;
      }
      
      _addToLog('Starting to fix expenses for user: $userId');
      _addToLog('Will move expenses from ${ExpenseService.DEBUG_TEST_UID} to $userId');
      
      final expenseService = ExpenseService(userId);
      await expenseService.debugFixExpenseUserIds();
      
      _addToLog('Fix complete! Your expenses should now appear under your user ID.');
      _addToLog('Please go back to the Expenses screen to see the fixed data.');
      
    } catch (e) {
      _addToLog('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      _addToLog('Refreshing expenses...');
      
      await expenseProvider.refreshExpenses();
      
      _addToLog('Expenses refreshed');
      
    } catch (e) {
      _addToLog('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserAuthProvider>(context).user;
    final isCurrentUserDebugId = user?.uid == ExpenseService.DEBUG_TEST_UID;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Data Fix'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ID Issue Detected',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your expenses may be showing under a different user ID (${ExpenseService.DEBUG_TEST_UID}).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current User ID: ${user?.uid ?? "Not logged in"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            if (isCurrentUserDebugId)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'You are currently logged in as the problematic user ID. Please log in with a different account to fix your expenses.',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
              
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isCurrentUserDebugId || _isLoading ? null : _fixExpenseUserIds,
              icon: const Icon(Icons.build_circle),
              label: const Text('FIX MY EXPENSES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _diagnoseExpenses,
              icon: const Icon(Icons.search),
              label: const Text('Run Diagnostics'),
            ),
            
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _refreshExpenses,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
              
            const SizedBox(height: 24),
            Text(
              'Log Output',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black87,
                child: SingleChildScrollView(
                  child: Text(
                    _logOutput,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
} 