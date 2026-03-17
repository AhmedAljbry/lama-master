import 'package:flutter/material.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/presentation/widgets/LumaUltimateEditorWidgets/ai_tool_button.dart';

class LumaToolAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const LumaToolAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class LumaActionDeck extends StatelessWidget {
  final List<LumaToolAction> actions;

  const LumaActionDeck({super.key, required this.actions});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 320;
          final itemWidth = twoColumns
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in actions)
                SizedBox(
                  width: itemWidth,
                  child: AIToolButton(
                    icon: item.icon,
                    label: item.label,
                    iconColor: item.color,
                    surface: AppTokens.card,
                    textColor: AppTokens.text,
                    onTap: item.onTap,
                  ),
                ),
            ],
          );
        },
      );
}
