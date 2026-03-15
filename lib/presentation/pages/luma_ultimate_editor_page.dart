import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lama/core/i18n/t.dart';
import 'package:lama/core/ui/tokens.dart';
import 'package:lama/features/luma_editor/domain/entities/ai_filter_insight.dart';
import 'package:lama/features/luma_editor/domain/entities/filter_item.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_bloc.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_event.dart';
import 'package:lama/features/luma_editor/presentation/bloc/editor_state.dart';
import 'package:lama/features/luma_editor/presentation/pages/luma_editor_scope.dart';
import 'package:lama/features/luma_editor/presentation/services/luma_editor_toolkit.dart';

import 'package:lama/presentation/widgets/LumaUltimateEditorWidgets/ai_creative_panel.dart';
import 'package:lama/presentation/widgets/LumaUltimateEditorWidgets/ai_tool_button.dart';
import 'package:lama/presentation/widgets/LumaUltimateEditorWidgets/style_name_dialog.dart';

import 'package:lama/presentation/widgets/luma_editor/luma_editor_components.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_app_bar.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_preview_panel.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_editor_hero.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_filter_strip.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_adjustment_panel.dart';
import 'package:lama/presentation/widgets/luma_editor/luma_tools_panel.dart';

enum _ImageAction { gallery, camera, files }

class LumaUltimateEditorPage extends StatelessWidget {
  const LumaUltimateEditorPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const LumaEditorScope(child: _LumaWorkspace());
}

class _LumaWorkspace extends StatefulWidget {
  const _LumaWorkspace();

  @override
  State<_LumaWorkspace> createState() => _LumaWorkspaceState();
}

class _LumaWorkspaceState extends State<_LumaWorkspace>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  final _picker = ImagePicker();
  final _search = TextEditingController();
  late final AnimationController _ambientController;
  var _lang = Lang.en;
  var _seededLang = false;
  var _tab = LumaPanelTab.ai;
  var _scope = LumaFilterScope.all;
  var _query = '';
  var _holdCompare = false;
  var _picking = false;
  var _saving = false;
  var _enhancing = false;
  var _aiLoading = false;
  var _autoAi = true;
  var _session = 0;
  AiFilterInsight? _insight;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    _search.addListener(() {
      if (_query == _search.text) return;
      setState(() => _query = _search.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededLang) return;
    _seededLang = true;
    _lang = Localizations.localeOf(context).languageCode == 'ar'
        ? Lang.ar
        : Lang.en;
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _search.dispose();
    super.dispose();
  }

  T get _t => T(_lang);
  LumaEditorToolkit _toolkit(BuildContext c) => c.read<LumaEditorToolkit>();
  FilterItem _selected(EditorState s) =>
      s.filters.firstWhere((f) => f.id == s.snapshot.selectedId,
          orElse: () => s.filters.first);

  List<FilterItem> _visibleFilters(EditorState s) {
    final q = _query.trim().toLowerCase();
    return s.filtersSorted.where((f) {
      final inScope = switch (_scope) {
        LumaFilterScope.all => true,
        LumaFilterScope.favorites => f.isFavorite,
        LumaFilterScope.cinema => f.id.startsWith('base_cinema_'),
        LumaFilterScope.retro => f.id.startsWith('base_retro_'),
        LumaFilterScope.pro => f.id.startsWith('pro_'),
        LumaFilterScope.custom => f.isCustom,
      };
      return inScope && (q.isEmpty || f.name.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _toggleLang(EditorState s) async {
    setState(() => _lang = _lang == Lang.ar ? Lang.en : Lang.ar);
    if (s.imageBytes != null) await _generateInsight(s.imageBytes!, s.filters);
  }

  Future<void> _pickImage(EditorState s) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final action = await _resolveAction();
      if (!mounted || action == null) return;
      final payload = await _loadPayload(action);
      if (!mounted || payload == null) return;
      context
          .read<EditorBloc>()
          .add(ImageLoaded(path: payload.path, bytes: payload.bytes));
      setState(() {
        _tab = LumaPanelTab.ai;
        _scope = LumaFilterScope.all;
        _query = '';
        _insight = null;
      });
      _search.clear();
      if (_autoAi) {
        await _generateInsight(payload.bytes, s.filters);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<_ImageAction?> _resolveAction() async {
    final desktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (desktop) return _ImageAction.files;
    return showModalBottomSheet<_ImageAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTokens.primary),
                title: Text(_t.of('pick_gallery'),
                    style: const TextStyle(color: AppTokens.text)),
                onTap: () => Navigator.pop(c, _ImageAction.gallery)),
            ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppTokens.primary),
                title: Text(_t.of('pick_camera'),
                    style: const TextStyle(color: AppTokens.text)),
                onTap: () => Navigator.pop(c, _ImageAction.camera)),
            ListTile(
                leading: const Icon(Icons.folder_open_rounded,
                    color: AppTokens.primary),
                title: Text(_t.of('tap_to_open'),
                    style: const TextStyle(color: AppTokens.text)),
                onTap: () => Navigator.pop(c, _ImageAction.files)),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Future<_PickedImage?> _loadPayload(_ImageAction action) async {
    if (action == _ImageAction.files) {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: true);
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.single;
      final bytes = file.bytes ?? await XFile(file.path!).readAsBytes();
      return _PickedImage(
          file.path ?? 'memory://${DateTime.now().millisecondsSinceEpoch}',
          bytes);
    }
    final picked = await _picker.pickImage(
        source: action == _ImageAction.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 100);
    if (picked == null) return null;
    return _PickedImage(picked.path, await picked.readAsBytes());
  }

  Future<void> _generateInsight(
      Uint8List bytes, List<FilterItem> filters) async {
    final id = ++_session;
    setState(() => _aiLoading = true);
    try {
      final insight = await _toolkit(context)
          .generateCreativeInsight(bytes, filters, _lang.name);
      if (mounted && id == _session) setState(() => _insight = insight);
    } catch (_) {
      if (mounted && id == _session) setState(() => _insight = null);
    } finally {
      if (mounted && id == _session) setState(() => _aiLoading = false);
    }
  }

  void _toggleAutoAi() {
    HapticFeedback.selectionClick();
    setState(() => _autoAi = !_autoAi);
  }

  Future<void> _runAi(EditorState s) async {
    if (s.imageBytes == null || _aiLoading) return;
    HapticFeedback.mediumImpact();
    await _generateInsight(s.imageBytes!, s.filters);
  }

  Future<void> _autoEnhance(EditorState s) async {
    if (s.imageBytes == null || _enhancing) return;
    setState(() => _enhancing = true);
    try {
      final p = await _toolkit(context).analyze(s.imageBytes!);
      if (!mounted) return;
      context.read<EditorBloc>().add(SetAdjustments(
          brightness: p.brightness,
          contrast: p.contrast,
          saturation: p.saturation,
          warmth: p.warmth,
          fade: p.fade));
    } finally {
      if (mounted) setState(() => _enhancing = false);
    }
  }

  void _randomize(EditorState s) {
    if (!s.hasImage) return;
    final p = _toolkit(context).generateRandomProfile(s.filters);
    context.read<EditorBloc>()
      ..add(SelectFilter(p.filterId))
      ..add(SetIntensity(p.intensity))
      ..add(SetAdjustments(
          brightness: p.brightness,
          contrast: p.contrast,
          saturation: p.saturation,
          warmth: p.warmth,
          fade: p.fade));
  }

  void _applyInsight(EditorState s) {
    final i = _insight;
    if (i == null) return;
    context.read<EditorBloc>()
      ..add(SelectFilter(i.recommendedFilterIds.isEmpty
          ? s.snapshot.selectedId
          : i.recommendedFilterIds.first))
      ..add(SetIntensity(i.intensity))
      ..add(SetAdjustments(
          brightness: i.brightness,
          contrast: i.contrast,
          saturation: i.saturation,
          warmth: i.warmth,
          fade: i.fade));
  }

  Future<void> _saveStyle(EditorState s) async {
    if (!s.hasImage) return;
    final name = await showStyleNameDialog(context,
        t: _t,
        title: _t.of('create_filter'),
        actionLabel: _t.of('save_style'),
        initialValue: _insight?.suggestedName ?? '');
    if (!mounted || name == null) return;
    final selected = _selected(s);
    final now = DateTime.now().millisecondsSinceEpoch;
    context.read<EditorBloc>().add(AddCustomFilter(FilterItem(
        id: 'custom_$now',
        name: name,
        matrix: context.read<EditorBloc>().buildFinalMatrix(),
        indicatorColor: selected.indicatorColor,
        isCustom: true,
        createdAtMs: now)));
  }

  Future<void> _renameCustomStyle(FilterItem filter) async {
    if (!filter.isCustom) return;
    final name = await showStyleNameDialog(context,
        t: _t,
        title: _t.of('rename_style'),
        actionLabel: _t.of('save'),
        initialValue: filter.name);
    if (!mounted || name == null || name == filter.name) return;
    context.read<EditorBloc>().add(RenameCustomFilter(filter.id, name));
    _showFeedback(_t.of('style_renamed'), color: AppTokens.info);
  }

  Future<void> _deleteCustomStyle(FilterItem filter) async {
    if (!filter.isCustom) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          _t.of('delete_style'),
          style: const TextStyle(
            color: AppTokens.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          _t.of('delete_style_desc'),
          style: const TextStyle(
            color: AppTokens.text2,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              _t.of('cancel'),
              style: const TextStyle(color: AppTokens.text2),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(_t.of('delete')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    context.read<EditorBloc>().add(DeleteCustomFilter(filter.id));
    _showFeedback(_t.of('style_deleted'), color: AppTokens.danger);
  }

  void _showFeedback(String message, {required Color color}) {
    final foreground =
        color.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Future<void> _saveResult(EditorState s) async {
    if (!s.hasImage || _saving) return;
    setState(() => _saving = true);
    try {
      final ok = await _toolkit(context).saveRenderedResult(_repaintKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: ok ? AppTokens.primary : AppTokens.danger,
          content: Text(ok ? _t.of('saved_ok') : _t.of('save_failed'),
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w800))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _t.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTokens.bg,
        body: BlocBuilder<EditorBloc, EditorState>(
          builder: (context, s) {
            final selected = _selected(s);
            final matrix = context.read<EditorBloc>().buildFinalMatrix();
            final filters = _visibleFilters(s);
            final accent =
                _insight == null ? selected.indicatorColor : AppTokens.primary;
            return Stack(children: [
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) => _LumaGlowBackgroundWrapper(
                  progress: _ambientController.value,
                  accent: accent,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final wide = c.maxWidth >= 1080;
                      final preview = LumaPreviewPanel(
                        repaintKey: _repaintKey,
                        bytes: s.imageBytes,
                        matrix: matrix,
                        selected: selected,
                        insight: _insight,
                        aiLoading: _aiLoading,
                        accentColor: accent,
                        t: _t,
                        showOriginal: _holdCompare || s.compareMode,
                        onHoldStart: () => setState(() => _holdCompare = true),
                        onHoldEnd: () => setState(() => _holdCompare = false),
                        onToggleCompare: s.hasImage
                            ? () =>
                                context.read<EditorBloc>().add(ToggleCompare())
                            : null,
                        onToggleFavorite: s.hasImage
                            ? () => context
                                .read<EditorBloc>()
                                .add(ToggleFavorite(selected))
                            : null,
                        onPick: () => _pickImage(s),
                        onRunAi: s.hasImage ? () => _runAi(s) : null,
                        onApplyAi:
                            _insight == null ? null : () => _applyInsight(s),
                      );
                      
                      final panel = _buildPanel(s, filters);
                      
                      return Column(children: [
                        LumaAppBar(
                          t: _t,
                          hasImage: s.hasImage,
                          saving: _saving,
                          aiLoading: _aiLoading,
                          autoAi: _autoAi,
                          hasInsight: _insight != null,
                          currentLook: s.hasImage ? selected.name : null,
                          onToggleLang: () => _toggleLang(s),
                          onToggleAutoAi: _toggleAutoAi,
                          onPick: () => _pickImage(s),
                          onRunAi: s.hasImage ? () => _runAi(s) : null,
                          onSave: s.hasImage ? () => _saveResult(s) : null,
                        ),
                        const SizedBox(height: 16),
                        if (wide)
                          Expanded(
                              child: Row(children: [
                            Expanded(flex: 12, child: preview),
                            const SizedBox(width: 18),
                            SizedBox(width: 430, child: panel)
                          ]))
                        else ...[
                          Expanded(child: preview),
                          const SizedBox(height: 16),
                          SizedBox(height: 430, child: panel)
                        ],
                      ]);
                    },
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildPanel(EditorState s, List<FilterItem> filters) {
    if (!s.hasImage) {
      return Container(
        decoration: BoxDecoration(
            color: AppTokens.surface.withValues(alpha: .92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10)),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    gradient: AppTokens.gradientPrimary,
                    borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.add_photo_alternate_rounded,
                    color: Colors.black, size: 32)),
            const SizedBox(height: 16),
            Text(_t.of('pick_hint'),
                style: const TextStyle(
                    color: AppTokens.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_t.of('insight_pending'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTokens.text2, fontSize: 13)),
            const SizedBox(height: 18),
            FilledButton.icon(
                onPressed: () => _pickImage(s),
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(_t.of('tap_to_open')),
                style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.primary,
                    foregroundColor: Colors.black)),
          ]),
        ),
      );
    }
    
    final selected = _selected(s);
    final accent =
        _insight == null ? selected.indicatorColor : AppTokens.primary;
    final favoriteCount = s.filters.where((f) => f.isFavorite).length;
    final recommendedCount = _insight?.recommendedFilterIds.length ?? 0;
    
    final tabBar = LumaPanelTabs(
      t: _t,
      activeTab: _tab,
      accentColor: accent,
      hasInsight: _insight != null,
      onSelect: (tab) => setState(() => _tab = tab),
    );
    
    final hero = LumaEditorHero(
      t: _t,
      accentColor: accent,
      aiLoading: _aiLoading,
      autoAi: _autoAi,
      currentLook: selected.name,
      insight: _insight,
      onRunAi: () => _runAi(s),
      onApplyAi: _insight == null ? null : () => _applyInsight(s),
      onToggleAutoAi: _toggleAutoAi,
    );
    
    Widget body = switch (_tab) {
      LumaPanelTab.ai => SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AiCreativePanel(
              insight: _insight,
              isLoading: _aiLoading,
              filters: s.filters,
              selectedId: s.snapshot.selectedId,
              onApplyInsight: () => _applyInsight(s),
              onSelectRecommendation: (id) =>
                  context.read<EditorBloc>().add(SelectFilter(id)),
              onCreateStyle: () => _saveStyle(s),
              t: _t),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final item in [
              (
                Icons.play_circle_fill_rounded,
                _t.of('run_ai'),
                AppTokens.primary,
                () => _runAi(s)
              ),
              (
                Icons.auto_fix_high_rounded,
                _enhancing ? _t.of('loading') : _t.of('enhance'),
                AppTokens.info,
                _enhancing ? null : () => _autoEnhance(s)
              ),
              (
                Icons.casino_rounded,
                _t.of('random'),
                AppTokens.warning,
                () => _randomize(s)
              ),
              (
                Icons.bookmark_add_outlined,
                _t.of('save_style'),
                accent,
                () => _saveStyle(s)
              ),
            ])
              SizedBox(
                  width: 180,
                  child: AIToolButton(
                      icon: item.$1,
                      label: item.$2,
                      iconColor: item.$3,
                      surface: AppTokens.card,
                      textColor: AppTokens.text,
                      onTap: item.$4)),
          ]),
        ])),
      LumaPanelTab.filters =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LumaSelectedLookCard(
            t: _t,
            filter: selected,
            bytes: s.imageBytes!,
            insight: _insight,
            onToggleFavorite: () =>
                context.read<EditorBloc>().add(ToggleFavorite(selected)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: LumaOverviewStat(
                icon: Icons.grid_view_rounded,
                value: '${filters.length}',
                label: _t.of('all_filters'),
                color: AppTokens.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LumaOverviewStat(
                icon: Icons.star_rounded,
                value: '$favoriteCount',
                label: _t.of('favorites'),
                color: AppTokens.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LumaOverviewStat(
                icon: Icons.auto_awesome_rounded,
                value: '$recommendedCount',
                label: _t.of('ai_match'),
                color: AppTokens.primary,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          LumaSearchBox(controller: _search, hint: _t.of('search')),
          const SizedBox(height: 10),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final item in [
                  (LumaFilterScope.all, _t.of('all_filters')),
                  (LumaFilterScope.favorites, _t.of('favorites')),
                  (LumaFilterScope.cinema, _t.of('cinema')),
                  (LumaFilterScope.retro, _t.of('retro')),
                  (LumaFilterScope.pro, _t.of('pro_pack')),
                  (LumaFilterScope.custom, _t.of('my_styles'))
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(item.$2,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800)),
                      selected: _scope == item.$1,
                      onSelected: (_) => setState(() => _scope = item.$1),
                      selectedColor: AppTokens.primary.withValues(alpha: 0.16),
                      labelStyle: TextStyle(
                          color: _scope == item.$1
                              ? AppTokens.primary
                              : AppTokens.text2),
                      side: BorderSide(
                          color: _scope == item.$1
                              ? AppTokens.primary
                              : Colors.white12),
                      backgroundColor: Colors.white10,
                    ),
                  ),
              ])),
          const SizedBox(height: 10),
          Expanded(
              child: filters.isEmpty
                  ? Center(
                      child: Text(_t.of('no_styles'),
                          style: const TextStyle(color: AppTokens.text2)))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: .86),
                      itemCount: filters.length,
                      itemBuilder: (_, i) => LumaFilterTile(
                          filter: filters[i],
                          bytes: s.imageBytes!,
                          t: _t,
                          active: filters[i].id == s.snapshot.selectedId,
                          onTap: () => context
                              .read<EditorBloc>()
                              .add(SelectFilter(filters[i].id)),
                          onStar: () => context
                              .read<EditorBloc>()
                              .add(ToggleFavorite(filters[i])),
                          onRename: filters[i].isCustom
                              ? () => _renameCustomStyle(filters[i])
                              : null,
                          onDelete: filters[i].isCustom
                              ? () => _deleteCustomStyle(filters[i])
                              : null),
                    )),
        ]),
      LumaPanelTab.adjust => LumaAdjustmentPanel(
          s: s,
          t: _t,
          enhancing: _enhancing,
          onAutoEnhance: () => _autoEnhance(s),
        ),
      LumaPanelTab.tools => SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LumaSectionLabel(
            title: _t.of('quick_actions'),
            subtitle: _t.of('studio_control'),
            accentColor: accent,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: LumaOverviewStat(
                icon: Icons.undo_rounded,
                value: '${s.undo.length}',
                label: _t.of('undo'),
                color: AppTokens.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LumaOverviewStat(
                icon: Icons.redo_rounded,
                value: '${s.redo.length}',
                label: _t.of('redo'),
                color: AppTokens.info,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LumaOverviewStat(
                icon: s.clipboard == null
                    ? Icons.content_paste_off_rounded
                    : Icons.content_paste_go_rounded,
                value: s.clipboard == null
                    ? _t.of('none')
                    : _t.of('ai_ready_short'),
                label: _t.of('paste'),
                color:
                    s.clipboard == null ? AppTokens.text2 : AppTokens.primary,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          LumaActionDeck(actions: [
            LumaToolAction(
              icon: Icons.auto_fix_high_rounded,
              label: _enhancing ? _t.of('loading') : _t.of('enhance'),
              color: AppTokens.primary,
              onTap: _enhancing ? null : () => _autoEnhance(s),
            ),
            LumaToolAction(
              icon: Icons.casino_rounded,
              label: _t.of('random'),
              color: AppTokens.info,
              onTap: () => _randomize(s),
            ),
            LumaToolAction(
              icon: Icons.bookmark_add_outlined,
              label: _t.of('save_style'),
              color: AppTokens.warning,
              onTap: () => _saveStyle(s),
            ),
            LumaToolAction(
              icon: s.compareMode
                  ? Icons.visibility_rounded
                  : Icons.compare_rounded,
              label: _t.of('compare'),
              color: selected.indicatorColor,
              onTap: () => context.read<EditorBloc>().add(ToggleCompare()),
            ),
            LumaToolAction(
              icon: Icons.content_copy_rounded,
              label: _t.of('copy'),
              color: AppTokens.info,
              onTap: () => context.read<EditorBloc>().add(CopySettings()),
            ),
            LumaToolAction(
              icon: Icons.content_paste_go_rounded,
              label: _t.of('paste'),
              color: AppTokens.info,
              onTap: s.clipboard == null
                  ? null
                  : () => context.read<EditorBloc>().add(PasteSettings()),
            ),
            LumaToolAction(
              icon: Icons.undo_rounded,
              label: _t.of('undo'),
              color: AppTokens.warning,
              onTap: s.undo.isEmpty
                  ? null
                  : () => context.read<EditorBloc>().add(Undo()),
            ),
            LumaToolAction(
              icon: Icons.redo_rounded,
              label: _t.of('redo'),
              color: AppTokens.warning,
              onTap: s.redo.isEmpty
                  ? null
                  : () => context.read<EditorBloc>().add(Redo()),
            ),
            LumaToolAction(
              icon: Icons.restart_alt_rounded,
              label: _t.of('reset_all'),
              color: AppTokens.danger,
              onTap: () => context.read<EditorBloc>().add(ResetAll()),
            ),
            LumaToolAction(
              icon: _saving
                  ? Icons.hourglass_top_rounded
                  : Icons.download_rounded,
              label: _t.of('save'),
              color: AppTokens.primary,
              onTap: _saving ? null : () => _saveResult(s),
            ),
          ]),
        ])),
    };
    
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.white.withValues(alpha: .05),
            AppTokens.surface.withValues(alpha: .95),
            accent.withValues(alpha: .10)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withValues(alpha: .20))),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        hero,
        const SizedBox(height: 14),
        tabBar,
        const SizedBox(height: 14),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppTokens.normal,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_tab), child: body),
          ),
        )
      ]),
    );
  }
}

class _PickedImage {
  final String path;
  final Uint8List bytes;
  const _PickedImage(this.path, this.bytes);
}

class _LumaGlowBackgroundWrapper extends StatelessWidget {
  final double progress;
  final Color accent;
  const _LumaGlowBackgroundWrapper({required this.progress, required this.accent});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(
            top: -140 + (progress * 70),
            left: -80 + (progress * 24),
            child: LumaGlowBlob(
                color: AppTokens.primary.withValues(alpha: .16), size: 280)),
        Positioned(
            top: 110 + ((1 - progress) * 50),
            right: -100 + (progress * 34),
            child: LumaGlowBlob(color: accent.withValues(alpha: .16), size: 300)),
        Positioned(
            bottom: -150 + ((1 - progress) * 60),
            left: 30 + (progress * 30),
            child: LumaGlowBlob(
                color: AppTokens.info.withValues(alpha: .12), size: 320)),
      ]);
}
