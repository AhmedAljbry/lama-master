import 'package:flutter/material.dart';

class AppL10n {
  final Locale locale;

  const AppL10n(this.locale);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ??
        const AppL10n(Locale('ar'));
  }

  static const Map<String, String> _ar = <String, String>{
    'app_title': 'AI STUDIO',
    'lang_switch': 'English',
    'workspace_label': 'مساحة العمل',
    'workspace_hero_title': 'طوّر صورتك بخطوات إبداعية موجهة',
    'workspace_hero_sub':
        'أضف صورتك الأساسية، ثم المرجع، وبعدها فعّل الذكاء الاصطناعي أو حسّن القناع قبل التطبيق.',
    'workspace_tip': 'أداة الرسم تفتح فقط بعد تفعيل الذكاء الاصطناعي.',
    'workspace_need_reference_title': 'أضف صورة مرجعية',
    'workspace_need_reference_desc':
        'اختر مرجعاً بصرياً حتى يتمكن الاستوديو من بناء النتيجة ومطابقة الاتجاه المطلوب.',
    'workspace_result_ready_title': 'النتيجة جاهزة',
    'workspace_result_ready_desc':
        'يمكنك الحفظ أو المشاركة من الأعلى، أو العودة للوحة الأدوات إذا أردت صقلاً إضافياً.',
    'workspace_style_hint':
        'الأسلوب الحالي جاهز. راجع عناصر التحكم أو اضغط تطبيق لبدء المعالجة بهذا الاتجاه.',
    'status_ready': 'جاهز',
    'status_missing': 'ناقص',
    'editor_state_setup': 'إعداد',
    'editor_state_processing': 'جاري المعالجة',
    'editor_state_result': 'النتيجة جاهزة',
    'your_photo': 'صورتك',
    'filter_ref': 'الصورة المرجعية',
    'manual_select': 'تحسين القناع',
    'manual_locked': 'فعّل AI أولاً',
    'ai_mode_label': 'عزل ذكي بالذكاء الاصطناعي',
    'ai_mode_sub':
        'فعّل AI ثم افتح أداة الرسم لتحسين القناع قبل تطبيق المعالجة النهائية. إذا كان القناع ضعيفًا فسيتم تجاوزه لحماية الخلفية.',
    'style_label': 'الأسلوب البصري',
    'apply_btn': 'تطبيق المعالجة الآن',
    'add_photo_hint': 'أضف صورتك للبدء',
    'section_workflow': 'تسلسل العمل',
    'section_workflow_desc':
        'ابدأ بالصورة الأساسية، أضف المرجع، ثم فعّل العزل الذكي أو حسّن القناع قبل التطبيق.',
    'section_sources': 'المصادر',
    'section_sources_desc':
        'ابدأ بالصورة الأساسية ثم أضف المرجع الذي تريد نقل ألوانه أو طابعه.',
    'section_masking': 'العزل والقناع',
    'section_masking_desc':
        'فعّل العزل الذكي، ثم استخدم أداة الرسم لتحسين الحواف عندما تحتاج دقة إضافية.',
    'section_themes': 'الأساليب',
    'section_themes_desc':
        'اختر الأسلوب الأقرب للنتيجة التي تريدها قبل الانتقال إلى التعديلات الدقيقة.',
    'section_adjust': 'الضبط الدقيق',
    'section_adjust_desc':
        'افتح أي أداة لضبط القوة، التباين، اللون، والملمس النهائي بدون إرباك بصري.',
    'current_style_label': 'الأسلوب الحالي',
    'current_style_desc':
        'كل أسلوب يغيّر طريقة نقل الضوء واللون، وبعدها يمكنك صقل النتيجة يدوياً.',
    'current_style_ai_on': 'العزل الذكي مفعل لدعم معالجة أكثر وعياً بالموضوع',
    'current_style_ai_off': 'المعالجة ستعتمد على المرجع فقط بدون عزل ذكي',
    'workflow_step_photo': 'الصورة',
    'workflow_step_reference': 'المرجع',
    'workflow_step_mask': 'القناع',
    'workflow_step_apply': 'التطبيق',
    'workflow_workspace_ready': 'جاهز',
    'adjust_title': 'تحكم أدق في المعالجة',
    'adjust_desc':
        'اختر أي متغير لفتح أداة تحكم مركزة ثم عد مباشرة إلى بقية الإعدادات.',
    'adjust_active': 'تعديلات نشطة',
    'adjust_none': 'لا توجد تعديلات إضافية بعد',
    'apply_ready_hint':
        'الصورة والمرجع جاهزان. اضغط تطبيق لبدء المعالجة الحالية.',
    'apply_missing_hint': 'أدخل الصورة والمرجع أولاً لفتح زر التطبيق.',
    'apply_processing_hint':
        'يتم تنفيذ المعالجة الحالية. انتظر حتى تكتمل قبل إعادة المحاولة.',
    'manual_select_hint':
        'عندما يكون AI مفعلاً يمكنك تحسين حواف الموضوع يدوياً قبل التنفيذ النهائي.',
    'manual_ready': 'تم حفظ القناع اليدوي',
    'manual_draw': 'افتح الرسام لتحسين التحديد',
    'slider_strength': 'قوة المعالجة',
    'slider_skin': 'حماية البشرة',
    'slider_luma': 'نقل الإضاءة',
    'slider_color': 'نقل اللون',
    'slider_contrast': 'التباين السينمائي',
    'slider_vignette': 'تغميق الأطراف',
    'slider_grain': 'الحبيبات',
    'result_title': 'اكتملت المعالجة',
    'result_desc':
        'تم تجهيز النتيجة الجديدة. احفظها أو شاركها من الأعلى، أو عد للتعديل إذا أردت صقلاً إضافياً.',
    'result_actions_hint': 'الإخراج جاهز للمراجعة أو التصدير',
    'btn_edit': 'تعديل',
    'btn_compare': 'مقارنة',
    'btn_original': 'الأصل',
    'btn_share': 'مشاركة',
    'btn_save': 'حفظ الصورة',
    'btn_undo': 'رجوع',
    'btn_redo': 'إعادة',
    'btn_back': 'رجوع',
    'compare_hold': 'اضغط مطولاً للمقارنة',
    'fullscreen_label': 'ملء الشاشة',
    'mask_title': 'محرر القناع الدقيق',
    'mask_ai_hint': 'تم تجهيز القناع الذكي. الفرشاة الآن جاهزة للتحسين.',
    'mask_not_found': 'لم يتم العثور على شخص واضح.',
    'mask_saving': 'جاري استخراج القناع...',
    'mask_error': 'خطأ في القناع',
    'mask_no_draw': 'شغّل AI أولاً ثم ارسم أو احفظ القناع.',
    'mask_booting': 'جاري تجهيز القناع الذكي...',
    'mask_unlock_hint': 'ابدأ بتحليل AI ثم استخدم الفرشاة لتنظيف الحواف بدقة.',
    'mask_ai_required': 'شغّل AI أولاً لفتح الفرشاة.',
    'mask_ready': 'الفرشاة جاهزة',
    'snack_saving': 'جاري الحفظ...',
    'snack_saved': 'تم الحفظ بنجاح',
    'snack_save_fail': 'فشل الحفظ',
    'snack_preparing_share': 'جاري تجهيز الملف...',
    'snack_share_fail': 'فشلت المشاركة',
    'snack_no_output': 'لا يوجد ناتج بعد',
    'snack_need_both': 'يرجى إدراج صورتك والصورة المرجعية أولاً',
    'snack_need_target': 'يرجى إدراج صورتك أولاً',
    'snack_ai_conflict': 'فعّل AI أولاً لفتح أداة الرسم',
    'snack_processing': 'جاري المعالجة...',
    'snack_done': 'اكتملت المعالجة بنجاح',
    'snack_error_prefix': 'خطأ في المعالجة: ',
    'snack_received_mask': 'تم استلام القناع، جاري المعالجة...',
    'snack_no_person': 'تنبيه: لم يتم العثور على شخص واضح في الصورة.',
    'snack_ai_mask_skipped':
        'تم تجاوز العزل الذكي لأن جودة القناع لم تكن كافية، لذلك تم الحفاظ على الخلفية الأصلية.',
    'snack_convert_fail': 'فشل تحويل صيغة الصورة.',
    'proc_init': 'تجهيز محرك المعالجة...',
    'proc_extract': 'استخراج البصمة اللونية...',
    'proc_analyze': 'تحليل الطبقات والتفاصيل...',
    'proc_blend': 'مزج الإضاءة والظلال...',
    'proc_magic': 'تطبيق اللمسات النهائية...',
    'original_label': 'الأصل',
    'manual_tag': 'قناع يدوي',
  };

  static const Map<String, String> _en = <String, String>{
    'app_title': 'AI STUDIO',
    'lang_switch': 'العربية',
    'workspace_label': 'Workspace',
    'workspace_hero_title': 'Shape your photo with guided creative editing',
    'workspace_hero_sub':
        'Add your main photo, load a reference, then enable AI or refine the mask before applying.',
    'workspace_tip': 'The painter unlocks only after AI mode is enabled.',
    'workspace_need_reference_title': 'Add a style reference',
    'workspace_need_reference_desc':
        'Load a reference image so the editor can build the result and match the intended direction.',
    'workspace_result_ready_title': 'Render ready',
    'workspace_result_ready_desc':
        'Save or share from the header, or head back into the tools for one more refinement pass.',
    'workspace_style_hint':
        'Your current look is ready. Review the controls or press apply to process with this direction.',
    'status_ready': 'Ready',
    'status_missing': 'Missing',
    'editor_state_setup': 'Setup',
    'editor_state_processing': 'Processing',
    'editor_state_result': 'Result Ready',
    'your_photo': 'Your Photo',
    'filter_ref': 'Style Reference',
    'manual_select': 'Refine Mask',
    'manual_locked': 'Enable AI first',
    'ai_mode_label': 'AI Smart Isolation',
    'ai_mode_sub':
        'Enable AI, then open the painter to refine the mask before the final render. If the mask is weak, the editor skips it to protect the background.',
    'style_label': 'Visual Style',
    'apply_btn': 'Apply Processing',
    'add_photo_hint': 'Add your photo to begin',
    'section_workflow': 'Workflow',
    'section_workflow_desc':
        'Load your photo, add a reference, then enable smart isolation or refine the mask before applying.',
    'section_sources': 'Sources',
    'section_sources_desc':
        'Start with the main photo, then add the visual reference that should guide the final look.',
    'section_masking': 'Masking',
    'section_masking_desc':
        'Enable smart isolation, then refine the edges manually whenever you need a cleaner subject.',
    'section_themes': 'Themes',
    'section_themes_desc':
        'Choose the closest look family before moving into detailed tuning.',
    'section_adjust': 'Adjustments',
    'section_adjust_desc':
        'Open any control to fine-tune strength, contrast, color transfer, and the finishing texture.',
    'current_style_label': 'Current look',
    'current_style_desc':
        'Each look changes the transfer profile first, then you can shape the final result with manual controls.',
    'current_style_ai_on':
        'AI isolation is enabled to support more subject-aware processing',
    'current_style_ai_off':
        'Processing will rely on the reference only without AI isolation',
    'workflow_step_photo': 'Photo',
    'workflow_step_reference': 'Reference',
    'workflow_step_mask': 'Mask',
    'workflow_step_apply': 'Apply',
    'workflow_workspace_ready': 'Ready',
    'adjust_title': 'Precision control',
    'adjust_desc':
        'Open any parameter to tune the render in a focused way, then jump back to the rest instantly.',
    'adjust_active': 'active tweaks',
    'adjust_none': 'No extra tuning yet',
    'apply_ready_hint':
        'Your photo and reference are ready. Apply the current processing stack when you are set.',
    'apply_missing_hint':
        'Add both your photo and a style reference to unlock apply.',
    'apply_processing_hint':
        'The current render is processing. Wait for it to finish before running again.',
    'manual_select_hint':
        'When AI is enabled you can refine subject edges manually before the final render.',
    'manual_ready': 'Manual mask saved',
    'manual_draw': 'Open the painter to refine the selection',
    'slider_strength': 'Processing Strength',
    'slider_skin': 'Skin Protection',
    'slider_luma': 'Light Transfer',
    'slider_color': 'Color Transfer',
    'slider_contrast': 'Cinematic Contrast',
    'slider_vignette': 'Edge Vignette',
    'slider_grain': 'Film Grain',
    'result_title': 'Render complete',
    'result_desc':
        'Your new render is ready. Save or share it from the header, or reopen the tools for another pass.',
    'result_actions_hint': 'Output ready for review or export',
    'btn_edit': 'Edit',
    'btn_compare': 'Compare',
    'btn_original': 'Original',
    'btn_share': 'Share',
    'btn_save': 'Save Photo',
    'btn_undo': 'Undo',
    'btn_redo': 'Redo',
    'btn_back': 'Back',
    'compare_hold': 'Hold to Compare',
    'fullscreen_label': 'Fullscreen',
    'mask_title': 'Precision Mask Editor',
    'mask_ai_hint': 'AI mask ready. The brush is now unlocked.',
    'mask_not_found': 'No clear person detected.',
    'mask_saving': 'Extracting mask...',
    'mask_error': 'Mask error',
    'mask_no_draw': 'Run AI first, then paint or save the mask.',
    'mask_booting': 'Building the AI mask...',
    'mask_unlock_hint':
        'Start with AI analysis, then use the brush to clean the edges.',
    'mask_ai_required': 'Run AI first to unlock the brush.',
    'mask_ready': 'Brush unlocked',
    'snack_saving': 'Saving...',
    'snack_saved': 'Saved successfully',
    'snack_save_fail': 'Save failed',
    'snack_preparing_share': 'Preparing file...',
    'snack_share_fail': 'Share failed',
    'snack_no_output': 'No output yet',
    'snack_need_both': 'Please add your photo and the style reference first',
    'snack_need_target': 'Please add your photo first',
    'snack_ai_conflict': 'Enable AI mode first to unlock the painter',
    'snack_processing': 'Processing...',
    'snack_done': 'Processing complete',
    'snack_error_prefix': 'Processing error: ',
    'snack_received_mask': 'Mask received, processing...',
    'snack_no_person': 'Warning: No clear person found in your photo.',
    'snack_ai_mask_skipped':
        'AI isolation was skipped because the mask was not reliable enough, so the original background was preserved.',
    'snack_convert_fail': 'Image format conversion failed.',
    'proc_init': 'Initializing processing core...',
    'proc_extract': 'Extracting color fingerprint...',
    'proc_analyze': 'Analyzing layers and detail...',
    'proc_blend': 'Blending light and shadow...',
    'proc_magic': 'Applying final touches...',
    'original_label': 'Original',
    'manual_tag': 'Manual Mask',
  };

  String get(String key) {
    final map = locale.languageCode == 'en' ? _en : _ar;
    return map[key] ?? key;
  }

  bool get isAr => locale.languageCode == 'ar';

  List<String> get processingPhrases => <String>[
        get('proc_init'),
        get('proc_extract'),
        get('proc_analyze'),
        get('proc_blend'),
        get('proc_magic'),
      ];
}

class AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const AppL10nDelegate();

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(
        locale.languageCode,
      );

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale);

  @override
  bool shouldReload(AppL10nDelegate old) => false;
}
