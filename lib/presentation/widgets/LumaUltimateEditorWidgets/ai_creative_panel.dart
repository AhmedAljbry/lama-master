import 'package:flutter/material.dart';

import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';

class AiCreativePanel extends StatelessWidget {
  final AiFilterInsight? insight;
  final bool isLoading;
  final List<FilterItem> filters;
  final String selectedId;
  final VoidCallback onApplyInsight;
  final ValueChanged<String> onSelectRecommendation;
  final VoidCallback onCreateStyle;
  final T t;

  const AiCreativePanel({
    super.key,
    required this.insight,
    required this.isLoading,
    required this.filters,
    required this.selectedId,
    required this.onApplyInsight,
    required this.onSelectRecommendation,
    required this.onCreateStyle,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final recommendedFilters = insight == null
        ? const <FilterItem>[]
        : insight!.recommendedFilterIds
            .map(_findFilter)
            .whereType<FilterItem>()
            .toList();

    return Container(
      margin: EdgeInsets.fromLTRB(6, 6, 6, 4),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF132432),
            const Color(0xFF0F1720),
            AppTokens.primary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.r24),
        border: Border.all(color: AppTokens.primary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppTokens.primary.withValues(alpha: 0.10),
            blurRadius: 34,
            spreadRadius: 1,
          ),
        ],
      ),
      child: isLoading
          ? _LoadingState(t: t)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppTokens.gradientPrimary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.primary.withValues(alpha: 0.20),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.of('ai_assistant'),
                            style: TextStyle(
                              color: AppTokens.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            insight?.headline ?? t.of('ai_idle'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTokens.text2,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StateBadge(
                      label:
                          insight == null ? t.of('run_ai') : t.of('ai_ready'),
                      color:
                          insight == null ? AppTokens.info : AppTokens.primary,
                    ),
                  ],
                ),
                SizedBox(height: 14),
                if (insight != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTokens.r20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaChip(
                              label: '${t.of('scene')}: ${insight!.sceneLabel}',
                              color: AppTokens.info,
                            ),
                            _MetaChip(
                              label: '${t.of('mood')}: ${insight!.moodLabel}',
                              color: AppTokens.warning,
                            ),
                            _MetaChip(
                              label: insight!.suggestedName,
                              color: AppTokens.primary,
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          insight!.summary,
                          style: TextStyle(
                            color: AppTokens.text2,
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _InsightStat(
                          label: t.of('magic'),
                          value: '${(insight!.intensity * 100).round()}%',
                          color: AppTokens.primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _InsightStat(
                          label: t.of('contrast'),
                          value: insight!.contrast.toStringAsFixed(2),
                          color: AppTokens.info,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _InsightStat(
                          label: t.of('warmth'),
                          value: insight!.warmth.toStringAsFixed(2),
                          color: AppTokens.warning,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Text(
                      t.of('ai_recommendations'),
                      style: TextStyle(
                        color: AppTokens.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onCreateStyle,
                      icon: Icon(Icons.bookmark_add_outlined, size: 16),
                      label: Text(t.of('save_style')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTokens.warning,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                if (recommendedFilters.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppTokens.r20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      t.of('no_ai_recommendations'),
                      style: TextStyle(
                        color: AppTokens.text2,
                        fontSize: 12,
                        height: 1.55,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recommendedFilters
                        .map(
                          (filter) => _RecommendationChip(
                            label: filter.name,
                            color: filter.indicatorColor,
                            isSelected: filter.id == selectedId,
                            onTap: () => onSelectRecommendation(filter.id),
                          ),
                        )
                        .toList(),
                  ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: insight == null ? null : onApplyInsight,
                    icon: Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: Text(t.of('ai_apply')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.r16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  FilterItem? _findFilter(String id) {
    for (final filter in filters) {
      if (filter.id == id) {
        return filter;
      }
    }
    return null;
  }
}

class _LoadingState extends StatelessWidget {
  final T t;

  const _LoadingState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppTokens.primary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              t.of('ai_loading'),
              style: TextStyle(
                color: AppTokens.text2,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StateBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InsightStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InsightStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTokens.text2,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecommendationChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppTokens.fast,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTokens.text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
