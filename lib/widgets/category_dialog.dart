import 'package:flutter/material.dart';

class CategoryDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final Color? initialColor;
  final IconData? initialIcon;
  final Function(String name, Color color, IconData icon) onSubmit;
  final bool showDelete;
  final VoidCallback? onDelete;

  const CategoryDialog({
    super.key,
    required this.title,
    this.initialName,
    this.initialColor,
    this.initialIcon,
    required this.onSubmit,
    this.showDelete = false,
    this.onDelete,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  late IconData _selectedIcon;
  
  final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
  
  final List<IconData> _icons = [
    Icons.shopping_cart,
    Icons.fastfood,
    Icons.restaurant,
    Icons.home,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.local_gas_station,
    Icons.local_hospital,
    Icons.school,
    Icons.book,
    Icons.movie,
    Icons.music_note,
    Icons.sports_esports,
    Icons.fitness_center,
    Icons.shopping_bag,
    Icons.flight,
    Icons.hotel,
    Icons.celebration,
    Icons.attach_money,
    Icons.account_balance,
    Icons.credit_card,
    Icons.receipt_long,
    Icons.pets,
    Icons.child_care,
    Icons.phone_android,
    Icons.laptop,
    Icons.wifi,
    Icons.electrical_services,
    Icons.water_drop,
    Icons.family_restroom,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColor = widget.initialColor ?? Colors.blue;
    _selectedIcon = widget.initialIcon ?? Icons.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        width: 300,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 18,
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Select Icon'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final icon = _icons[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: _selectedIcon == icon
                            ? _selectedColor
                            : Colors.grey.shade200,
                        child: Icon(
                          icon,
                          color: _selectedIcon == icon
                              ? Colors.white
                              : Colors.grey.shade700,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.showDelete)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onSubmit(
                _nameController.text.trim(),
                _selectedColor,
                _selectedIcon,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 