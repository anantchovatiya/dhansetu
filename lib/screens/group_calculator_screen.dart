import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/group.dart';
import '../providers/group_provider.dart';
import 'package:intl/intl.dart';

class GroupCalculatorScreen extends StatefulWidget {
  const GroupCalculatorScreen({super.key});

  @override
  State<GroupCalculatorScreen> createState() => _GroupCalculatorScreenState();
}

class _GroupCalculatorScreenState extends State<GroupCalculatorScreen> {
  final _groupNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _expenseDescriptionController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  String? _selectedPayer;
  final Set<String> _selectedSharedBy = {};
  final _formKey = GlobalKey<FormState>();

  // Helper function to format currency with ₹ symbol in UI and Rs in PDF
  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberNameController.dispose();
    _expenseDescriptionController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GroupProvider>(context, listen: false).reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group reset')),
              );
            },
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, child) {
          if (provider.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.error!)),
              );
              provider.reset();
            });
          }

          return provider.currentGroup == null
              ? _buildCreateGroupForm()
              : _buildGroupContent(provider);
        },
      ),
      floatingActionButton: Consumer<GroupProvider>(
        builder: (context, provider, child) {
          if (provider.currentGroup != null && provider.currentGroup!.expenses.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: () => _generatePdfReport(provider),
              icon: const Icon(Icons.download),
              label: const Text('Download Report'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCreateGroupForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create a new group to split expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createGroup,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContent(GroupProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.currentGroup!.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${provider.currentGroup!.members.length} members · ${provider.currentGroup!.expenses.length} expenses',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (provider.currentGroup!.expenses.isNotEmpty)
                      Text(
                        'Total: ₹${provider.currentGroup!.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMembersList(provider),
            const SizedBox(height: 16),
            _buildExpenseForm(provider),
            const SizedBox(height: 24),
            if (provider.currentGroup!.expenses.isNotEmpty) ...[
              _buildExpensesList(provider),
              const SizedBox(height: 24),
              _buildSettlements(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(GroupProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add'),
                  onPressed: () => _showAddMemberDialog(context),
                ),
              ],
            ),
            const Divider(),
            if (provider.currentGroup!.members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('No members added yet'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.currentGroup!.members.length,
                itemBuilder: (context, index) {
                  final member = provider.currentGroup!.members[index];
                  return ListTile(
                    title: Text(member.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (member.totalPaid > 0) 
                          Chip(
                            label: Text(
                              'Paid: ${formatCurrency(member.totalPaid)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.green.withOpacity(0.1),
                          ),
                        const SizedBox(width: 4),
                        if (member.totalShare > 0)
                          Chip(
                            label: Text(
                              'Owes: ${formatCurrency(member.totalShare)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.orange.withOpacity(0.1),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseForm(GroupProvider provider) {
    final hasMembers = provider.currentGroup!.members.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Expense',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            if (!hasMembers)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('Add members before adding expenses'),
                ),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _expenseDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expenseAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        try {
                          final amount = double.parse(value);
                          if (amount <= 0) {
                            return 'Amount must be greater than zero';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Paid by',
                        prefixIcon: Icon(Icons.person),
                      ),
                      value: _selectedPayer,
                      items: provider.currentGroup!.members.map((member) {
                        return DropdownMenuItem(
                          value: member.name,
                          child: Text(member.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPayer = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select who paid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Shared by:'),
                    Wrap(
                      spacing: 8,
                      children: provider.currentGroup!.members.map((member) {
                        return FilterChip(
                          label: Text(member.name),
                          selected: _selectedSharedBy.contains(member.name),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSharedBy.add(member.name);
                              } else {
                                _selectedSharedBy.remove(member.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addExpense,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Add Expense'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(GroupProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Expenses',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.currentGroup!.expenses.length,
              itemBuilder: (context, index) {
                final expense = provider.currentGroup!.expenses[index];
                return ListTile(
                  title: Text(expense.description),
                  subtitle: Text(
                    'Paid by ${expense.paidByName} · Shared by ${expense.sharedByNames.length} members',
                  ),
                  trailing: Text(
                    '${formatCurrency(expense.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlements(GroupProvider provider) {
    final settlements = provider.calculateSettlements();
    
    if (settlements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Settlements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('No settlements needed'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Settlements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settlements.keys.length,
              itemBuilder: (context, index) {
                final debtor = settlements.keys.elementAt(index);
                final debtorSettlements = settlements[debtor]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        debtor,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...debtorSettlements.map((settlement) {
                      return ListTile(
                        leading: const Icon(Icons.arrow_forward, size: 18),
                        title: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: 'Pay ',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              TextSpan(
                                text: '${settlement['to']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: ' ${formatCurrency(settlement['amount'])}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const Divider(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<GroupProvider>(context, listen: false);
      provider.createGroup(_groupNameController.text.trim());
      _groupNameController.clear();
    }
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: _memberNameController,
          decoration: const InputDecoration(
            labelText: 'Member Name',
            prefixIcon: Icon(Icons.person_add),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _memberNameController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_memberNameController.text.trim().isNotEmpty) {
                Provider.of<GroupProvider>(context, listen: false)
                    .addMember(_memberNameController.text.trim());
                Navigator.pop(context);
                _memberNameController.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSharedBy.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select members to share the expense')),
        );
        return;
      }

      Provider.of<GroupProvider>(context, listen: false).addExpense(
        description: _expenseDescriptionController.text.trim(),
        amount: double.parse(_expenseAmountController.text.trim()),
        paidByName: _selectedPayer!,
        sharedByNames: _selectedSharedBy.toList(),
      );

      _expenseDescriptionController.clear();
      _expenseAmountController.clear();
      setState(() {
        _selectedPayer = null;
        _selectedSharedBy.clear();
      });
    }
  }

  Future<void> _generatePdfReport(GroupProvider provider) async {
    try {
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
                Text('Generating PDF report...'),
              ],
            ),
          );
        },
      );
      
      // Helper function to format currency with Rs for PDF
      String formatPdfCurrency(double amount) {
        return 'Rs ${amount.toStringAsFixed(2)}';
      }
      
      final pdf = pw.Document();
      
      // Get settlements for the report
      final settlements = provider.calculateSettlements();
      
      // PDF Content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            // Header with branding
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('DHANSETU',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    )
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Group Expense Report',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    )
                  ),
                ]
              )
            ),
            
            // Group Info
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Group: ${provider.currentGroup!.name}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Members: ${provider.currentGroup!.members.length}',
                    style: pw.TextStyle(fontSize: 12)
                  ),
                  pw.Text('Expenses: ${provider.currentGroup!.expenses.length}',
                    style: pw.TextStyle(fontSize: 12)
                  ),
                  pw.Text('Total Amount: ${formatPdfCurrency(provider.currentGroup!.totalAmount)}',
                    style: pw.TextStyle(fontSize: 12)
                  ),
                ]
              )
            ),
            
            // Members Section
            pw.Header(level: 1, text: 'Members'),
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
              cellPadding: const pw.EdgeInsets.all(5),
              headers: ['Name', 'Paid', 'Owes', 'Balance'],
              data: provider.currentGroup!.members.map((member) {
                final balance = member.totalPaid - member.totalShare;
                return [
                  member.name,
                  formatPdfCurrency(member.totalPaid),
                  formatPdfCurrency(member.totalShare),
                  formatPdfCurrency(balance),
                ];
              }).toList(),
            ),
            
            // Expenses Section
            pw.Header(level: 1, text: 'Expenses'),
            provider.currentGroup!.expenses.isEmpty 
              ? pw.Text('No expenses recorded', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
              : pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  cellPadding: const pw.EdgeInsets.all(5),
                  headers: ['Description', 'Paid By', 'Amount', 'Shared By'],
                  data: provider.currentGroup!.expenses.map((expense) {
                    return [
                      expense.description,
                      expense.paidByName,
                      formatPdfCurrency(expense.amount),
                      expense.sharedByNames.join(', '),
                    ];
                  }).toList(),
                ),
            
            // Settlements Section
            pw.Header(level: 1, text: 'Settlements'),
            settlements.isEmpty
              ? pw.Text('No settlements needed', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
              : pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: settlements.entries.map((entry) {
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(entry.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        ...entry.value.map((settlement) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
                            child: pw.Text(
                              'Pay ${settlement['to']}: ${formatPdfCurrency(settlement['amount'])}',
                            ),
                          );
                        }).toList(),
                        pw.Divider(),
                      ],
                    );
                  }).toList(),
                ),
                
            // Footer with developer info
            pw.Footer(
              trailing: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Developed by: Anant Chovatiya', 
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)
                  ),
                  pw.Text('Generated on: ${DateTime.now().toString().substring(0, 19)}', 
                    style: pw.TextStyle(fontSize: 8)
                  ),
                ]
              )
            ),
          ],
        ),
      );
      
      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dhansetu_group_report.pdf');
      await file.writeAsBytes(await pdf.save());
      
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
        const SnackBar(content: Text('PDF report saved successfully')),
      );
    } catch (e) {
      // Dismiss dialog if error occurs
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); 
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF report: $e')),
      );
    }
  }
} 