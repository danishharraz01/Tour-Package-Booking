import 'package:flutter/material.dart';

import '../core/theme.dart';

/// The SSB logo. [withWordmark] shows "SSB" under the emblem.
///
/// [onDark] places the logo on a cream badge so the brown outline stays
/// visible over photos and dark backgrounds.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 64, this.withWordmark = false, this.onDark = false});

  final double size;
  final bool withWordmark;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      withWordmark ? 'assets/logo.png' : 'assets/logo_mark.png',
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'SSB Tour logo',
    );
    if (!onDark) return image;
    return Container(
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        shape: withWordmark ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: withWordmark ? BorderRadius.circular(size * 0.2) : null,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: image,
    );
  }
}
