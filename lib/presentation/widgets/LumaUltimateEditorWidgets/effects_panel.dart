import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lama/domain/filter_item.dart';
import 'package:lama/presentation/bloc/editor_bloc.dart';
import 'package:lama/presentation/bloc/editor_event.dart';
import 'package:lama/presentation/widgets/LumaUltimateEditorWidgets/premium_effects.dart';
 // إذا FilterItem موجود هناك عدّل حسب مشروعك

class EffectsPanel {
  static void open(BuildContext context, {required bool isDark}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final surface = isDark ? const Color(0xFF0F1720) : Colors.white;
        final text = isDark ? Colors.white : Colors.black87;

        return Container(
          height: 350,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("تأثيرات احترافية", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: PremiumEffects.allEffects.length,
                  itemBuilder: (context, index) {
                    final effect = PremiumEffects.allEffects[index];
                    return InkWell(
                      onTap: () {
                        final bloc = ctx.read<EditorBloc>();
                        final item = FilterItem(
                          id: 'effect_$index',
                          name: effect['name'],
                          matrix: effect['matrix'],
                          isCustom: true,
                          indicatorColor: effect['color'],
                          createdAtMs: DateTime.now().millisecondsSinceEpoch,
                        );
                        bloc.add(AddCustomFilter(item));
                        bloc.add(SelectFilter(item.id));
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (effect['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (effect['color'] as Color).withOpacity(0.5)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: effect['color']),
                            const SizedBox(height: 8),
                            Text(
                              effect['name'],
                              style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
