// t.dart — Translation Engine
import 'translations_ar.dart';
import 'translations_en.dart';

enum Lang { ar, en }

class T {
  final Lang lang;
  const T(this.lang);

  String of(String key) {
    final map = lang == Lang.ar ? ar : en;
    return map[key] ?? en[key] ?? key;
  }

  bool get isRTL => lang == Lang.ar;

  String get langLabel => lang == Lang.ar ? 'EN' : 'AR';
  String get langFull  => lang == Lang.ar ? 'English' : 'العربية';

  T toggle() => T(lang == Lang.ar ? Lang.en : Lang.ar);
}
