import 'package:flutter/material.dart';

import 'package:lama/core/Responsive_Helper/ResponsiveHelper.dart';
import 'package:lama/core/Stayl/Them.dart';
import 'package:lama/core/i18n/t.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Lang lang;

  const SectionTitle({
    super.key,
    required this.title,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: R.sp(context, 8)),
      child: Text(
        title.toUpperCase(),
        style: R.t(
          context,
          12,
          w: FontWeight.w900,
          color: AppUI.sub,
        ),
      ),
    );
  }
}
