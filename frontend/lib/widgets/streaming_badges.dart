import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

class StreamingBadges extends StatelessWidget {
  final List<WatchProvider> providers;
  final bool showHeader;
  final int maxBadges;
  final double logoSize;

  const StreamingBadges({
    super.key,
    required this.providers,
    this.showHeader = true,
    this.maxBadges = 4,
    this.logoSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    final colors = context.cineColors;
    final displayProviders = providers.take(maxBadges).toList();
    final remainingCount = providers.length - displayProviders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tv_outlined, size: 12, color: colors.textMuted),
              const SizedBox(width: 5),
              Text(
                'DISPONIBLE SUR',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: 7,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...displayProviders.map(
              (provider) => _buildProviderBadge(context, colors, provider),
            ),
            if (remainingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '+$remainingCount autre${remainingCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderBadge(
    BuildContext context,
    CineBookColors colors,
    WatchProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _getPlatformStyle(provider.name, colors, isDark);
    final pixelSize = (logoSize * MediaQuery.devicePixelRatioOf(context)).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: style.borderColor.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: provider.logoUrl != null
                ? Image.network(
                    provider.logoUrl!,
                    width: logoSize,
                    height: logoSize,
                    cacheWidth: pixelSize,
                    fit: BoxFit.contain,
                    semanticLabel: provider.name,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackIcon(style, logoSize),
                  )
                : _buildFallbackIcon(style, logoSize),
          ),
          const SizedBox(width: 6),
          Text(
            style.displayName,
            style: TextStyle(
              color: style.textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(_PlatformStyle style, double size) {
    return Container(
      width: size,
      height: size,
      color: style.borderColor.withValues(alpha: 0.16),
      alignment: Alignment.center,
      child: Text(
        style.displayName.isNotEmpty ? style.displayName.substring(0, 1) : '▶',
        style: TextStyle(
          color: style.borderColor,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  _PlatformStyle _getPlatformStyle(
    String rawName,
    CineBookColors colors,
    bool isDark,
  ) {
    final lower = rawName.toLowerCase();
    const netflixRed = Color(0xFFE50914);
    const primeBlue = Color(0xFF00A8E1);
    const appleGrey = Color(0xFF8E8E93);
    const disneyBlue = Color(0xFF3E63DD);
    const maxPurple = Color(0xFF9E47FF);
    const canalGold = Color(0xFFD7B32C);
    const paramountBlue = Color(0xFF0064FF);

    if (lower.contains('netflix')) {
      return _PlatformStyle(
        displayName: 'Netflix',
        borderColor: netflixRed,
        backgroundColor: isDark ? const Color(0xFF2A090B) : colors.surface,
        textColor: isDark ? const Color(0xFFFFEEEE) : colors.textPrimary,
      );
    }
    if (lower.contains('prime') || lower.contains('amazon')) {
      return _PlatformStyle(
        displayName: 'Prime Video',
        borderColor: primeBlue,
        backgroundColor: isDark ? const Color(0xFF071E30) : colors.surface,
        textColor: isDark ? const Color(0xFFDDF5FF) : colors.textPrimary,
      );
    }
    if (lower.contains('apple')) {
      return _PlatformStyle(
        displayName: 'Apple TV',
        borderColor: appleGrey,
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : colors.surface,
        textColor: isDark ? const Color(0xFFF2F2F7) : colors.textPrimary,
      );
    }
    if (lower.contains('disney')) {
      return _PlatformStyle(
        displayName: 'Disney+',
        borderColor: disneyBlue,
        backgroundColor: isDark ? const Color(0xFF0B183B) : colors.surface,
        textColor: isDark ? const Color(0xFFE5EDFF) : colors.textPrimary,
      );
    }
    if (lower.contains('max') || lower.contains('hbo')) {
      return _PlatformStyle(
        displayName: 'Max',
        borderColor: maxPurple,
        backgroundColor: isDark ? const Color(0xFF211033) : colors.surface,
        textColor: isDark ? const Color(0xFFF4EBFF) : colors.textPrimary,
      );
    }
    if (lower.contains('canal')) {
      return _PlatformStyle(
        displayName: 'Canal+',
        borderColor: canalGold,
        backgroundColor: isDark ? const Color(0xFF292207) : colors.surface,
        textColor: isDark ? const Color(0xFFFFF8D6) : colors.textPrimary,
      );
    }
    if (lower.contains('paramount')) {
      return _PlatformStyle(
        displayName: 'Paramount+',
        borderColor: paramountBlue,
        backgroundColor: isDark ? const Color(0xFF071B35) : colors.surface,
        textColor: isDark ? const Color(0xFFE5F0FF) : colors.textPrimary,
      );
    }
    return _PlatformStyle(
      displayName: _cleanGenericName(rawName),
      borderColor: colors.border,
      backgroundColor: colors.surfaceElevated,
      textColor: colors.textSecondary,
    );
  }

  String _cleanGenericName(String name) {
    var clean = name;
    for (final suffix in [' Standard with Ads', ' with Ads', ' Channel']) {
      clean = clean.replaceAll(suffix, '');
    }
    return clean;
  }
}

class _PlatformStyle {
  final String displayName;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _PlatformStyle({
    required this.displayName,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
