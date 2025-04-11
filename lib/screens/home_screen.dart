import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../widgets/expense_list.dart';
import '../widgets/summary_card.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/expense_report.dart';
import 'add_expense_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'groups_screen.dart';
import 'debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const ExpenseListTab(),
    const AnalyticsScreen(),
    const GroupsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserAuthProvider>(context).user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('DhanSetu'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Expense Report',
            onPressed: () => _downloadExpenseReport(context),
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundImage: user?.photoURL != null 
                ? NetworkImage(user!.photoURL!) 
                : null,
              child: user?.photoURL == null 
                ? const Icon(Icons.person, size: 16)
                : null,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  _showDateRangeFilter(context);
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
                case 'debug':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DebugScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filter by Date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Debug Tools'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddExpenseDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
        ],
      ),
    );
  }

  void _showDateRangeFilter(BuildContext context) async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final initialDateRange = DateTimeRange(
      start: expenseProvider.startDate,
      end: expenseProvider.endDate,
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDateRange != null) {
      expenseProvider.setDateRange(
        pickedDateRange.start,
        pickedDateRange.end,
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'DhanSetu',
        applicationVersion: 'Version 1.0.0',
        applicationLegalese: '© 2024',
        children: const [
          SizedBox(height: 16),
          Text(
            'DhanSetu is a comprehensive expense tracking app that helps you manage your finances with ease.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 16),
          Text(
            'This app features expense tracking and analytics.',
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
  }

  Future<void> _downloadExpenseReport(BuildContext context) async {
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final authProvider = Provider.of<UserAuthProvider>(context, listen: false);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating expense report...'),
              ],
            ),
          );
        },
      );
      
      // Get expenses based on current date range
      final expenses = await expenseProvider.getExpensesByDateRange(
        expenseProvider.startDate, 
        expenseProvider.endDate
      );
      
      // Get total expenses for the date range
      final total = await expenseProvider.getTotalExpenses(
        expenseProvider.startDate, 
        expenseProvider.endDate
      );
      
      // Generate PDF report
      final userEmail = authProvider.user?.email ?? 'No Email';
      final userId = authProvider.user?.uid ?? 'No User ID';
      
      final file = await ExpenseReportGenerator.generateExpenseReport(
        expenses: expenses,
        userId: userId,
        userEmail: userEmail,
        startDate: expenseProvider.startDate,
        endDate: expenseProvider.endDate,
        totalAmount: total,
      );
      
      // Close loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Try to open the file
      try {
        final result = await OpenFile.open(file.path);
        
        if (result.type != 'done') {
          // If opening failed, show a dialog with the file path
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('PDF Saved'),
                content: Text('PDF saved at: ${file.path}\n\nUnable to open automatically: ${result.message}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        // If opening fails, just show where the file is saved
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('PDF Saved'),
              content: Text('PDF saved at: ${file.path}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense report saved successfully')),
      );
    } catch (e) {
      // Dismiss dialog if error occurs
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); 
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate expense report: $e')),
      );
    }
  }
}

class ExpenseListTab extends StatelessWidget {
  const ExpenseListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SummaryCard(),
        Expanded(
          child: Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final expenses = provider.expenses;
              if (expenses.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No expenses found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap + to add a new expense',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              
              return const ExpenseList();
            },
          ),
        ),
      ],
    );
  }
} 