import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.colorValue,
                  child: Icon(category.iconData, color: Colors.white),
                ),
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditCategoryDialog(context, category),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: 'Add Category',
        onSubmit: (name, color, icon) {
          final category = ExpenseCategory(
            name: name,
            color: color.value,
            icon: icon.codePoint,
          );
          
          Provider.of<ExpenseProvider>(context, listen: false)
              .addCategory(category);
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        title: 'Edit Category',
        initialName: category.name,
        initialColor: category.colorValue,
        initialIcon: category.iconData,
        onSubmit: (name, color, icon) {
          final updatedCategory = ExpenseCategory(
            id: category.id,
            name: name,
            color: color.value,
            icon: icon.codePoint,
          );
          
          Provider.of<ExpenseProvider>(context, listen: false)
              .updateCategory(updatedCategory);
        },
        showDelete: true,
        onDelete: () {
          if (category.id != null) {
            Provider.of<ExpenseProvider>(context, listen: false)
                .deleteCategory(category.id!);
          }
        },
      ),
    );
  }
} 