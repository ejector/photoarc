import 'package:flutter/material.dart';

class FolderListTile extends StatelessWidget {
  final String path;
  final String label;
  final bool isSelected;
  final bool isDefault;
  final ValueChanged<bool?> onChanged;

  const FolderListTile({
    super.key,
    required this.path,
    required this.label,
    required this.isSelected,
    this.isDefault = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      value: isSelected,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(
            Icons.folder,
            color: isDefault
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  path,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isDefault)
            Chip(
              label: Text(
                'Default',
                style: theme.textTheme.labelSmall,
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
