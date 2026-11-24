import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CineBookLogo extends StatelessWidget {
  final bool compact;
  final bool showTagline;
  final VoidCallback? onTap;

  const CineBookLogo({
    super.key,
    this.compact = false,
    this.showTagline = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.cineColors;
    final wordmark = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        'CINEBOOK',
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          color: colors.textPrimary,
          fontSize: compact ? 17 : 21,
          fontWeight: FontWeight.w800,
          letterSpacing: compact ? 1.1 : 1.5,
          height: 1,
        ),
      ),
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          color: colors.accent,
          alignment: Alignment.center,
          child: Text(
            'CB',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              color: colors.onAccent,
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wordmark,
              if (showTagline && !compact) ...[
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LE CINÉMA, PAR ATMOSPHÈRE',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      color: colors.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return Semantics(
      label: 'CineBook — Accueil',
      button: onTap != null,
      image: true,
      child: FittedBox(fit: BoxFit.scaleDown, child: content),
    );
  }
}
