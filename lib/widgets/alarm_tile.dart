import 'package:flutter/material.dart';

class AlarmTile extends StatelessWidget {

  const AlarmTile({
    required this.title, required this.subtitle, required this.isActive, required this.onPressed, required this.onToggle, super.key,
  });
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onPressed;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: isActive,
        onChanged: onToggle,
      ),
      onTap: onPressed,
    );
  }
}