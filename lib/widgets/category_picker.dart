import 'package:flutter/material.dart';

class CategoryPicker extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryPicker({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
      ),
      items: const [
        DropdownMenuItem(value: 'Food', child: Text('Food')),
        DropdownMenuItem(value: 'Transport', child: Text('Transport')),
        DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
        DropdownMenuItem(value: 'Bills', child: Text('Bills')),
        DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        if (value != null) {
          onCategorySelected(value);
        }
      },
    );
  }
} 