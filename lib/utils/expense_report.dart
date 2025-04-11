import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/currency_formatter.dart';

class ExpenseReportGenerator {
  static Future<File> generateExpenseReport({
    required List<Expense> expenses,
    required String userId,
    required String userEmail,
    required DateTime startDate,
    required DateTime endDate,
    double? totalAmount,
  }) async {
    final pdf = pw.Document();
    
    // Format currency without using ₹ symbol
    String formatCurrency(double amount) {
      return 'Rs ${amount.toStringAsFixed(2)}';
    }
    
    // Calculate total if not provided
    totalAmount ??= expenses.fold<double>(0, (sum, exp) => sum + exp.amount);
    
    // Group expenses by category
    final expensesByCategory = <String, double>{};
    for (var expense in expenses) {
      expensesByCategory[expense.category] = (expensesByCategory[expense.category] ?? 0) + expense.amount;
    }
    
    // Format dates
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedStartDate = dateFormat.format(startDate);
    final formattedEndDate = dateFormat.format(endDate);
    
    // Create PDF content
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
                pw.Text('Expense Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  )
                ),
              ]
            )
          ),
          
          // Report Info
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
                pw.Text('User: $userEmail',
                  style: pw.TextStyle(fontSize: 12)
                ),
                pw.SizedBox(height: 5),
                pw.Text('Date Range: $formattedStartDate to $formattedEndDate',
                  style: pw.TextStyle(fontSize: 12)
                ),
                pw.SizedBox(height: 5),
                pw.Text('Total Expenses: ${formatCurrency(totalAmount ?? 0)}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)
                ),
                pw.SizedBox(height: 5),
                pw.Text('Number of Expenses: ${expenses.length}',
                  style: pw.TextStyle(fontSize: 12)
                ),
              ]
            )
          ),
          
          // Expense Summary by Category
          pw.Header(level: 1, text: 'Expenses by Category'),
          pw.Table.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
            cellPadding: const pw.EdgeInsets.all(5),
            headers: ['Category', 'Amount', 'Percentage'],
            data: expensesByCategory.entries.map((entry) {
              final nonNullTotal = totalAmount ?? 0;
              final percentage = nonNullTotal > 0 ? (entry.value / nonNullTotal) * 100 : 0;
              return [
                entry.key,
                formatCurrency(entry.value),
                '${percentage.toStringAsFixed(1)}%',
              ];
            }).toList(),
          ),
          
          // Expenses List
          pw.Header(level: 1, text: 'Expense Details'),
          expenses.isEmpty 
            ? pw.Text('No expenses recorded', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
            : pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
                cellPadding: const pw.EdgeInsets.all(5),
                headers: ['Date', 'Description', 'Category', 'Amount'],
                data: expenses.map((expense) {
                  return [
                    DateFormat('MMM d, yyyy').format(expense.date),
                    expense.description,
                    expense.category,
                    formatCurrency(expense.amount),
                  ];
                }).toList(),
              ),
              
          // Footer with information
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
    
    // Save the PDF to a file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/expense_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
} 