import 'package:flutter/material.dart';
import 'constants.dart';

class BloodGroupDropdown extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  final String label;

  const BloodGroupDropdown({
    Key? key,
    required this.selected,
    required this.onChanged,
    this.label = "Blood Group",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      items: bloodGroups.map((group) {
        return DropdownMenuItem(
          value: group,
          child: Text(group),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please select a blood group";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: "Select $label",
        prefixIcon: const Icon(Icons.bloodtype, color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}