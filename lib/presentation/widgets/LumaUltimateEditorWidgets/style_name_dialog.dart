import 'package:flutter/material.dart';

import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/tokens.dart';

Future<String?> showStyleNameDialog(
  BuildContext context, {
  required AppL10n l10n,
  required String title,
  required String actionLabel,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTokens.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTokens.text),
          decoration: InputDecoration(
            hintText: l10n.get('filter_name'),
            hintStyle: const TextStyle(color: AppTokens.text2),
            filled: true,
            fillColor: AppTokens.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.r12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.get('cancel'),
              style: const TextStyle(color: AppTokens.text2),
            ),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );
}
