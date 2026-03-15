import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/core/utils/Responsive.dart';
import 'package:lama/domain/filter_item.dart';

enum _FilterLibrarySegment {
  all,
  ai,
  favorites,
  cinema,
  retro,
  proPack,
}

class BottomPanel extends StatefulWidget {
  final Uint8List? imageBytes;
  final List<FilterItem> filtersSorted;
  final List<String> recommendedFilterIds;
  final String selectedId;
  final ValueChanged<String> onSelectById;
  final ValueChanged<FilterItem> onToggleFavorite;
  final ValueChanged<FilterItem> onRename;
  final ValueChanged<FilterItem> onDelete;
  final VoidCallback onCreateStyle;
  final double intensity;
  final ValueChanged<double> onIntensityChanged;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double fade;
  final void Function({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? fade,
  }) onAdjustChanged;
  final VoidCallback onResetAdjustments;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final bool canPaste;
  final VoidCallback onResetAll;
  final VoidCallback onToggleCompare;
  final bool compareEnabled;
  final Lang currentLang;

  const BottomPanel({
    super.key,
    this.imageBytes,
    required this.filtersSorted,
    required this.recommendedFilterIds,
    required this.selectedId,
    required this.onSelectById,
    required this.onToggleFavorite,
    required this.onRename,
    required this.onDelete,
    required this.onCreateStyle,
    required this.intensity,
    required this.onIntensityChanged,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.fade,
    required this.onAdjustChanged,
    required this.onResetAdjustments,
    required this.onCopy,
    required this.onPaste,
    required this.canPaste,
    required this.onResetAll,
    required this.onToggleCompare,
    required this.compareEnabled,
    this.currentLang = Lang.en,
  });

  @override
  State<BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<BottomPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final TextEditingController _search = TextEditingController();

  String _query = '';
  _FilterLibrarySegment _segment = _FilterLibrarySegment.all;

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTokens.surface : Colors.white;
    final card = isDark ? AppTokens.card : const Color(0xFFF2F5F7);
    final text = isDark ? AppTokens.text : Colors.black87;
    final text2 = isDark ? AppTokens.text2 : Colors.black54;
    final t = T(widget.currentLang);

    final baseFilters =
        widget.filtersSorted.where((filter) => !filter.isCustom);
    final visibleFilters = baseFilters
        .where(_matchesSegment)
        .where(
          (filter) =>
              _query.isEmpty ||
              filter.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final customFilters =
        widget.filtersSorted.where((filter) => filter.isCustom).toList();

    return Directionality(
      textDirection: t.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        height: Responsive.bottomPanelHeight(context),
        decoration: BoxDecoration(
          color: surface.withOpacity(0.98),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.r24),
          ),
          boxShadow: AppTokens.defaultShadow,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: text2.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            _PanelTabBar(
              controller: _tabs,
              primary: AppTokens.primary,
              text2: text2,
              tabs: [
                t.of('filters'),
                t.of('adjust'),
                t.of('tools'),
                t.of('my_styles'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const ClampingScrollPhysics(),
                children: [
                  _FiltersTab(
                    filters: visibleFilters,
                    imageBytes: widget.imageBytes,
                    selectedId: widget.selectedId,
                    recommendedFilterIds: widget.recommendedFilterIds,
                    intensity: widget.intensity,
                    search: _search,
                    query: _query,
                    segment: _segment,
                    onQueryChanged: (value) => setState(() => _query = value),
                    onSegmentChanged: (segment) =>
                        setState(() => _segment = segment),
                    onSelect: widget.onSelectById,
                    onToggleFavorite: widget.onToggleFavorite,
                    onIntensityChanged: widget.onIntensityChanged,
                    onCreateStyle: widget.onCreateStyle,
                    primary: AppTokens.primary,
                    card: card,
                    text: text,
                    text2: text2,
                    t: t,
                  ),
                  _AdjustTab(
                    brightness: widget.brightness,
                    contrast: widget.contrast,
                    saturation: widget.saturation,
                    warmth: widget.warmth,
                    fade: widget.fade,
                    onChanged: widget.onAdjustChanged,
                    onReset: widget.onResetAdjustments,
                    primary: AppTokens.primary,
                    text2: text2,
                    t: t,
                  ),
                  _ToolsTab(
                    onCopy: widget.onCopy,
                    onPaste: widget.canPaste ? widget.onPaste : null,
                    onReset: widget.onResetAll,
                    onCompare: widget.onToggleCompare,
                    compareEnabled: widget.compareEnabled,
                    onCreateStyle: widget.onCreateStyle,
                    primary: AppTokens.primary,
                    card: card,
                    text: text,
                    text2: text2,
                    t: t,
                  ),
                  _CustomStylesTab(
                    customFilters: customFilters,
                    selectedId: widget.selectedId,
                    onSelect: widget.onSelectById,
                    onCreateStyle: widget.onCreateStyle,
                    onRename: widget.onRename,
                    onDelete: widget.onDelete,
                    primary: AppTokens.primary,
                    card: card,
                    text: text,
                    text2: text2,
                    t: t,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSegment(FilterItem filter) {
    switch (_segment) {
      case _FilterLibrarySegment.all:
        return true;
      case _FilterLibrarySegment.ai:
        return widget.recommendedFilterIds.contains(filter.id);
      case _FilterLibrarySegment.favorites:
        return filter.isFavorite;
      case _FilterLibrarySegment.cinema:
        return filter.id.startsWith('base_cinema');
      case _FilterLibrarySegment.retro:
        return filter.id.startsWith('base_retro');
      case _FilterLibrarySegment.proPack:
        return filter.id.startsWith('pro_');
    }
  }
}

class _PanelTabBar extends StatelessWidget {
  final TabController controller;
  final Color primary;
  final Color text2;
  final List<String> tabs;

  const _PanelTabBar({
    required this.controller,
    required this.primary,
    required this.text2,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.center,
      labelColor: primary,
      unselectedLabelColor: text2,
      indicatorColor: primary,
      indicatorWeight: 2.2,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      unselectedLabelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      tabs: tabs.map((label) => Tab(height: 36, child: Text(label))).toList(),
    );
  }
}

class _FiltersTab extends StatelessWidget {
  final List<FilterItem> filters;
  final Uint8List? imageBytes;
  final List<String> recommendedFilterIds;
  final String selectedId;
  final double intensity;
  final TextEditingController search;
  final String query;
  final _FilterLibrarySegment segment;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_FilterLibrarySegment> onSegmentChanged;
  final ValueChanged<String> onSelect;
  final ValueChanged<FilterItem> onToggleFavorite;
  final ValueChanged<double> onIntensityChanged;
  final VoidCallback onCreateStyle;
  final Color primary;
  final Color card;
  final Color text;
  final Color text2;
  final T t;

  const _FiltersTab({
    required this.filters,
    required this.imageBytes,
    required this.recommendedFilterIds,
    required this.selectedId,
    required this.intensity,
    required this.search,
    required this.query,
    required this.segment,
    required this.onQueryChanged,
    required this.onSegmentChanged,
    required this.onSelect,
    required this.onToggleFavorite,
    required this.onIntensityChanged,
    required this.onCreateStyle,
    required this.primary,
    required this.card,
    required this.text,
    required this.text2,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: search,
                    style: TextStyle(color: text, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: t.of('search'),
                      hintStyle: TextStyle(
                          color: text2.withOpacity(0.55), fontSize: 12),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: text2, size: 18),
                      suffixIcon: query.isEmpty
                          ? null
                          : GestureDetector(
                              onTap: () {
                                search.clear();
                                onQueryChanged('');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: text2,
                                size: 16,
                              ),
                            ),
                      filled: true,
                      fillColor: card,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: onQueryChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SquareActionButton(
                icon: Icons.playlist_add_rounded,
                color: primary,
                background: primary.withOpacity(0.10),
                onTap: onCreateStyle,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SegmentChip(
                  label: t.of('all_filters'),
                  isSelected: segment == _FilterLibrarySegment.all,
                  onTap: () => onSegmentChanged(_FilterLibrarySegment.all),
                  color: text,
                  selectedColor: primary,
                ),
                _SegmentChip(
                  label: t.of('ai_picks'),
                  isSelected: segment == _FilterLibrarySegment.ai,
                  onTap: () => onSegmentChanged(_FilterLibrarySegment.ai),
                  color: text,
                  selectedColor: primary,
                ),
                _SegmentChip(
                  label: t.of('favorites'),
                  isSelected: segment == _FilterLibrarySegment.favorites,
                  onTap: () =>
                      onSegmentChanged(_FilterLibrarySegment.favorites),
                  color: text,
                  selectedColor: primary,
                ),
                _SegmentChip(
                  label: t.of('cinema'),
                  isSelected: segment == _FilterLibrarySegment.cinema,
                  onTap: () => onSegmentChanged(_FilterLibrarySegment.cinema),
                  color: text,
                  selectedColor: primary,
                ),
                _SegmentChip(
                  label: t.of('retro'),
                  isSelected: segment == _FilterLibrarySegment.retro,
                  onTap: () => onSegmentChanged(_FilterLibrarySegment.retro),
                  color: text,
                  selectedColor: primary,
                ),
                _SegmentChip(
                  label: t.of('pro_pack'),
                  isSelected: segment == _FilterLibrarySegment.proPack,
                  onTap: () => onSegmentChanged(_FilterLibrarySegment.proPack),
                  color: text,
                  selectedColor: primary,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: text2, size: 16),
              const SizedBox(width: 6),
              Text(
                '${t.of('filters')} ${t.of('advanced')}',
                style: TextStyle(
                  color: text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(intensity * 100).round()}%',
                style: TextStyle(
                  color: text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primary,
              inactiveTrackColor: card,
              thumbColor: primary,
              trackHeight: 2.4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: intensity,
              min: 0,
              max: 1,
              onChanged: onIntensityChanged,
            ),
          ),
        ),
        Expanded(
          child: filters.isEmpty
              ? _EmptyListState(
                  icon: Icons.filter_alt_off_rounded,
                  title: segment == _FilterLibrarySegment.ai
                      ? t.of('no_ai_recommendations')
                      : t.of('search'),
                  subtitle: segment == _FilterLibrarySegment.ai
                      ? t.of('ai_loading')
                      : t.of('advanced'),
                  color: text2,
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                  itemCount: filters.length,
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    return _FilterCard(
                      filter: filter,
                      imageBytes: imageBytes,
                      isSelected: filter.id == selectedId,
                      isAiPick: recommendedFilterIds.contains(filter.id),
                      primary: primary,
                      card: card,
                      text: text,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelect(filter.id);
                      },
                      onToggleFavorite: () => onToggleFavorite(filter),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AdjustTab extends StatelessWidget {
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double fade;
  final void Function({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? fade,
  }) onChanged;
  final VoidCallback onReset;
  final Color primary;
  final Color text2;
  final T t;

  const _AdjustTab({
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.fade,
    required this.onChanged,
    required this.onReset,
    required this.primary,
    required this.text2,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          _AdjustSlider(
            icon: Icons.brightness_6_rounded,
            label: t.of('brightness'),
            value: brightness,
            min: -1,
            max: 1,
            primary: primary,
            text2: text2,
            onChanged: (value) => onChanged(brightness: value),
          ),
          _AdjustSlider(
            icon: Icons.contrast_rounded,
            label: t.of('contrast'),
            value: contrast,
            min: -1,
            max: 1,
            primary: primary,
            text2: text2,
            onChanged: (value) => onChanged(contrast: value),
          ),
          _AdjustSlider(
            icon: Icons.color_lens_rounded,
            label: t.of('saturation'),
            value: saturation,
            min: -1,
            max: 1,
            primary: primary,
            text2: text2,
            onChanged: (value) => onChanged(saturation: value),
          ),
          _AdjustSlider(
            icon: Icons.wb_sunny_rounded,
            label: t.of('warmth'),
            value: warmth,
            min: -1,
            max: 1,
            primary: primary,
            text2: text2,
            onChanged: (value) => onChanged(warmth: value),
          ),
          _AdjustSlider(
            icon: Icons.blur_on_rounded,
            label: t.of('fade'),
            value: fade,
            min: 0,
            max: 1,
            primary: primary,
            text2: text2,
            onChanged: (value) => onChanged(fade: value),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onReset,
            icon: Icon(
              Icons.restore_rounded,
              size: 16,
              color: text2.withOpacity(0.75),
            ),
            label: Text(
              t.of('reset'),
              style: TextStyle(
                color: text2.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsTab extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback? onPaste;
  final VoidCallback onReset;
  final VoidCallback onCompare;
  final bool compareEnabled;
  final VoidCallback onCreateStyle;
  final Color primary;
  final Color card;
  final Color text;
  final Color text2;
  final T t;

  const _ToolsTab({
    required this.onCopy,
    required this.onPaste,
    required this.onReset,
    required this.onCompare,
    required this.compareEnabled,
    required this.onCreateStyle,
    required this.primary,
    required this.card,
    required this.text,
    required this.text2,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              _ToolButton(
                icon: Icons.copy_all_rounded,
                label: t.of('copy'),
                color: primary,
                card: card,
                text: text,
                onTap: onCopy,
              ),
              const SizedBox(width: 10),
              _ToolButton(
                icon: Icons.content_paste_rounded,
                label: t.of('paste'),
                color: onPaste != null ? primary : text2.withOpacity(0.35),
                card: card,
                text: text,
                onTap: onPaste,
              ),
              const SizedBox(width: 10),
              _ToolButton(
                icon: Icons.restart_alt_rounded,
                label: t.of('reset_all'),
                color: AppTokens.warning,
                card: card,
                text: text,
                onTap: onReset,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ToolButton(
                icon: compareEnabled
                    ? Icons.visibility_off_rounded
                    : Icons.compare_arrows_rounded,
                label: t.of('compare'),
                color: compareEnabled ? primary : text,
                card: compareEnabled ? primary.withOpacity(0.10) : card,
                text: text,
                onTap: onCompare,
              ),
              const SizedBox(width: 10),
              _ToolButton(
                icon: Icons.playlist_add_rounded,
                label: t.of('add_filter'),
                color: primary,
                card: card,
                text: text,
                onTap: onCreateStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomStylesTab extends StatelessWidget {
  final List<FilterItem> customFilters;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreateStyle;
  final ValueChanged<FilterItem> onRename;
  final ValueChanged<FilterItem> onDelete;
  final Color primary;
  final Color card;
  final Color text;
  final Color text2;
  final T t;

  const _CustomStylesTab({
    required this.customFilters,
    required this.selectedId,
    required this.onSelect,
    required this.onCreateStyle,
    required this.onRename,
    required this.onDelete,
    required this.primary,
    required this.card,
    required this.text,
    required this.text2,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    if (customFilters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.style_outlined,
                size: 36,
                color: text2.withOpacity(0.28),
              ),
              const SizedBox(height: 12),
              Text(
                t.of('no_styles'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text2.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreateStyle,
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: Text(t.of('save_current_style')),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                t.of('my_styles'),
                style: TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCreateStyle,
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: Text(t.of('add_filter')),
                style: TextButton.styleFrom(foregroundColor: primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: customFilters.length,
            itemBuilder: (context, index) {
              final filter = customFilters[index];
              final isSelected = filter.id == selectedId;

              return Dismissible(
                key: Key(filter.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTokens.danger.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: AppTokens.danger,
                  ),
                ),
                onDismissed: (_) => onDelete(filter),
                child: AnimatedContainer(
                  duration: AppTokens.fast,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primary.withOpacity(0.08) : card,
                    borderRadius: BorderRadius.circular(AppTokens.r12),
                    border: Border.all(
                      color: isSelected ? primary : text2.withOpacity(0.10),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: filter.indicatorColor.withOpacity(0.24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.palette_rounded,
                        color: filter.indicatorColor,
                        size: 17,
                      ),
                    ),
                    title: Text(
                      filter.name,
                      style: TextStyle(
                        color: text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      t.of('save_current_style'),
                      style: TextStyle(color: text2, fontSize: 10),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => onRename(filter),
                          icon: Icon(
                            Icons.edit_rounded,
                            color: text2,
                            size: 18,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 18,
                          ),
                      ],
                    ),
                    onTap: () => onSelect(filter.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  final FilterItem filter;
  final Uint8List? imageBytes;
  final bool isSelected;
  final bool isAiPick;
  final Color primary;
  final Color card;
  final Color text;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _FilterCard({
    required this.filter,
    required this.imageBytes,
    required this.isSelected,
    required this.isAiPick,
    required this.primary,
    required this.card,
    required this.text,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.fast,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: isSelected ? 92 : 80,
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.09) : card,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isAiPick
              ? [
                  BoxShadow(
                    color: filter.indicatorColor.withOpacity(0.16),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTokens.r16 - 2),
                      ),
                      child: imageBytes == null
                          ? Container(
                              color: filter.indicatorColor.withOpacity(0.34),
                              child: Center(
                                child: Icon(
                                  Icons.palette_outlined,
                                  color: filter.indicatorColor,
                                  size: 24,
                                ),
                              ),
                            )
                          : ColorFiltered(
                              colorFilter: ColorFilter.matrix(filter.matrix),
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                gaplessPlayback: true,
                                cacheWidth: 220,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: AnimatedOpacity(
                      duration: AppTokens.fast,
                      opacity: isAiPick ? 1 : 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.62),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onToggleFavorite,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.42),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          filter.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: filter.isFavorite
                              ? const Color(0xFFFFD166)
                              : Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 7),
              child: Text(
                filter.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: text,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final Color primary;
  final Color text2;
  final ValueChanged<double> onChanged;

  const _AdjustSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.primary,
    required this.text2,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = max == 1 && min == -1
        ? ((value + 1) * 50).round()
        : (value * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: text2.withOpacity(0.75)),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: TextStyle(
                color: text2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primary,
                inactiveTrackColor: text2.withOpacity(0.15),
                thumbColor: primary,
                trackHeight: 1.8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$normalized',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: text2,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color card;
  final Color text;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.card,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: AnimatedContainer(
          duration: AppTokens.fast,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppTokens.r16),
            border: Border.all(color: color.withOpacity(0.16)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null ? color.withOpacity(0.45) : color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final Color selectedColor;

  const _SegmentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: AppTokens.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? selectedColor.withOpacity(0.35)
                  : color.withOpacity(0.10),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : color.withOpacity(0.86),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _SquareActionButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.r12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTokens.r12),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyListState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color.withOpacity(0.35)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withOpacity(0.88),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withOpacity(0.55),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
