import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_utils.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return InkWell(
          onTap: () => _refreshData(context, provider),
          child: FutureBuilder<double>(
            future: provider.getTotalExpenses(provider.startDate, provider.endDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  margin: EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  margin: EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              }

              final totalExpenses = snapshot.data ?? 0.0;
              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${DateFormat('MMM d').format(provider.startDate)} - ${DateFormat('MMM d').format(provider.endDate)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyFormatter.format(totalExpenses),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to refresh',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickFilterButton(
                            context,
                            'Today',
                            () => _filterToday(context),
                          ),
                          _buildQuickFilterButton(
                            context,
                            'Week',
                            () => _filterThisWeek(context),
                          ),
                          _buildQuickFilterButton(
                            context,
                            'Month',
                            () => _filterThisMonth(context),
                          ),
                          _buildQuickFilterButton(
                            context,
                            'Year',
                            () => _filterThisYear(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickFilterButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(label),
    );
  }

  void _filterToday(BuildContext context) {
    final today = DateTime.now();
    
    // Create start of day (midnight)
    final startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
    
    // Create end of day (just before midnight tomorrow)
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    print('Setting today filter: ${startOfDay.toString()} to ${endOfDay.toString()}');
    Provider.of<ExpenseProvider>(context, listen: false).setDateRange(startOfDay, endOfDay);
  }

  void _filterThisWeek(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = DateUtil.getWeekStart(now);
    Provider.of<ExpenseProvider>(context, listen: false).setDateRange(startOfWeek, now);
  }

  void _filterThisMonth(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateUtil.getMonthStart(now);
    Provider.of<ExpenseProvider>(context, listen: false).setDateRange(startOfMonth, now);
  }

  void _filterThisYear(BuildContext context) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    Provider.of<ExpenseProvider>(context, listen: false).setDateRange(startOfYear, now);
  }

  void _refreshData(BuildContext context, ExpenseProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing expense data...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    await provider.refreshExpenses();
  }
} 