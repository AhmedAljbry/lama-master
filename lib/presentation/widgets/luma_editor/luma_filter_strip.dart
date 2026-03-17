import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lama/core/ui/AppL10n.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';

enum LumaFilterScope { all, favorites, cinema, retro, pro, custom }

enum CustomStyleAction { rename, delete }

// ─────────────────────────────────────────────────────────────────────────────
// LumaHorizontalFilterStrip — quick-access preset thumbnails.
//
// Appears as a horizontal scroll row below the preview canvas.
// Tapping a thumbnail instantly selects the filter without opening the
// Presets tab. The active filter is highlighted with an accent border.
// ─────────────────────────────────────────────────────────────────────────────

class LumaHorizontalFilterStrip extends StatelessWidget {
  final List<FilterItem> filters;
  final Uint8List bytes;
  final String selectedId;
  final AiFilterInsight? insight;
  final ValueChanged<String> onSelect;

  const LumaHorizontalFilterStrip({
    super.key,
    required this.filters,
    required this.bytes,
    required this.selectedId,
    required this.insight,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: .0),
            Colors.black.withValues(alpha: .72),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final isActive = filter.id == selectedId;
          final isRecommended =
              insight?.recommendedFilterIds.contains(filter.id) ?? false;
          return _FilterThumb(
            filter: filter,
            bytes: bytes,
            isActive: isActive,
            isRecommended: isRecommended,
            onTap: () => onSelect(filter.id),
          );
        },
      ),
    );
  }
}

class _FilterThumb extends StatelessWidget {
  final FilterItem filter;
  final Uint8List bytes;
  final bool isActive;
  final bool isRecommended;
  final VoidCallback onTap;

  const _FilterThumb({
    required this.filter,
    required this.bytes,
    required this.isActive,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isRecommended ? AppTokens.primary : filter.indicatorColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.normal,
        width: 60,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? effectiveColor
                : Colors.white.withValues(alpha: .15),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: .30),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(fit: StackFit.expand, children: [
            ColorFiltered(
              colorFilter: ColorFilter.matrix(filter.matrix),
              child: Image.memory(bytes,
                  fit: BoxFit.cover, gaplessPlayback: true),
            ),
            // Name overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Text(
                  filter.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Active check mark
            if (isActive)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 9, color: Colors.black),
                ),
              ),
            // AI star if recommended
            if (isRecommended && !isActive)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTokens.primary.withValues(alpha: .85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      size: 9, color: Colors.black),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class LumaSelectedLookCard extends StatelessWidget {
  final AppL10n l10n;
  final FilterItem filter;
  final Uint8List bytes;
  final AiFilterInsight? insight;
  final VoidCallback onToggleFavorite;

  const LumaSelectedLookCard({
    super.key,
    required this.l10n,
    required this.filter,
    required this.bytes,
    required this.insight,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isMatched =
        insight?.recommendedFilterIds.contains(filter.id) ?? false;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            filter.indicatorColor.withValues(alpha: .18),
            AppTokens.card.withValues(alpha: .96),
            Colors.white.withValues(alpha: .05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: filter.indicatorColor.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(
            color: filter.indicatorColor.withValues(alpha: .10),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(filter.matrix),
                    child: Image.memory(bytes,
                        fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          filter.indicatorColor.withValues(alpha: .12),
                          Colors.black.withValues(alpha: .24),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.get('active_look'),
                  style: const TextStyle(
                      color: AppTokens.text2,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text(filter.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppTokens.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text(
                insight?.headline ?? l10n.get('studio_ready'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppTokens.text2, fontSize: 11, height: 1.45),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  LumaTag(
                    icon: filter.isCustom
                        ? Icons.layers_rounded
                        : Icons.auto_awesome_rounded,
                    label: filter.isCustom
                        ? l10n.get('custom_style')
                        : l10n.get('preset_style'),
                    color: filter.indicatorColor,
                  ),
                  if (isMatched)
                    LumaTag(
                      icon: Icons.bolt_rounded,
                      label: l10n.get('ai_match'),
                      color: AppTokens.primary,
                    ),
                ],
              ),
            ]),
          ),
          SizedBox(width: 8),
          LumaTinyIcon(
            icon: filter.isFavorite
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            active: filter.isFavorite,
            color: AppTokens.warning,
            onTap: onToggleFavorite,
          ),
        ],
      ),
    );
  }
}

class LumaFilterTile extends StatelessWidget {
  final FilterItem filter;
  final Uint8List bytes;
  final AppL10n l10n;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onStar;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  
  const LumaFilterTile({
    super.key,
    required this.filter,
    required this.bytes,
    required this.l10n,
    required this.active,
    required this.onTap,
    required this.onStar,
    required this.onRename,
    required this.onDelete
  });
  
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: AppTokens.normal,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  filter.indicatorColor.withValues(alpha: active ? .20 : .10),
                  AppTokens.card.withValues(alpha: .96),
                  Colors.white.withValues(alpha: .03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: active
                      ? filter.indicatorColor
                      : Colors.white.withValues(alpha: .10),
                  width: active ? 1.5 : 1),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: filter.indicatorColor.withValues(alpha: .12),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ]
                  : null),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(fit: StackFit.expand, children: [
                  ColorFiltered(
                      colorFilter: ColorFilter.matrix(filter.matrix),
                      child: Image.memory(bytes,
                          fit: BoxFit.cover, gaplessPlayback: true)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          filter.indicatorColor.withValues(alpha: .10),
                          Colors.black.withValues(alpha: .28),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color:
                                filter.indicatorColor.withValues(alpha: .24)),
                      ),
                      child: Text(
                          filter.isCustom
                              ? l10n.get('custom_style')
                              : l10n.get('preset_style'),
                          style: TextStyle(
                              color: filter.indicatorColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Positioned(
                      top: 8,
                      right: 8,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (filter.isCustom)
                          Container(
                            width: 28,
                            height: 28,
                            margin: EdgeInsetsDirectional.only(end: 6),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(999)),
                            child: PopupMenuButton<CustomStyleAction>(
                              padding: EdgeInsets.zero,
                              tooltip: '',
                              color: AppTokens.surface,
                              icon: Icon(Icons.more_horiz_rounded,
                                  color: Colors.white70, size: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (action) {
                                switch (action) {
                                  case CustomStyleAction.rename:
                                    onRename?.call();
                                    break;
                                  case CustomStyleAction.delete:
                                    onDelete?.call();
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<CustomStyleAction>(
                                  value: CustomStyleAction.rename,
                                  child: Text(
                                    l10n.get('rename_style'),
                                    style:
                                        TextStyle(color: AppTokens.text),
                                  ),
                                ),
                                PopupMenuItem<CustomStyleAction>(
                                  value: CustomStyleAction.delete,
                                  child: Text(
                                    l10n.get('delete_style'),
                                    style: TextStyle(
                                        color: AppTokens.danger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        InkWell(
                            onTap: onStar,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(999)),
                                child: Icon(
                                    filter.isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: filter.isFavorite
                                        ? AppTokens.warning
                                        : Colors.white70,
                                    size: 16))),
                      ])),
                  if (active)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: filter.indicatorColor.withValues(alpha: .20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color:
                                  filter.indicatorColor.withValues(alpha: .30)),
                        ),
                        child: Text(l10n.get('instant_apply'),
                            style: TextStyle(
                                color: filter.indicatorColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                ]),
              ),
            ),
            SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Text(filter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppTokens.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
              if (active)
                Icon(Icons.check_circle_rounded,
                    size: 16, color: filter.indicatorColor),
            ]),
            SizedBox(height: 4),
            Row(children: [
              Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: filter.indicatorColor, shape: BoxShape.circle)),
              SizedBox(width: 6),
              Expanded(
                  child: Text(
                      active
                          ? l10n.get('studio_ready')
                          : filter.isCustom
                              ? l10n.get('custom_style')
                              : l10n.get('preset_style'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTokens.text2, fontSize: 11)))
            ]),
          ]),
        ),
      );
}
