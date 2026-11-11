import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

class StreamingBadges extends StatelessWidget {
  final List<WatchProvider> providers;
  final bool showHeader;
  final int maxBadges;

  const StreamingBadges({
    super.key,
    required this.providers,
    this.showHeader = true,
    this.maxBadges = 4,
    double logoSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Icon(Icons.tv_rounded, size: 12, color: AppTheme.gold.withValues(alpha: 0.9)),
              const SizedBox(width: 5),
              const Text(
                'DISPONIBLE SUR',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...displayProviders.map((p) => _buildProviderBadge(context, p)),
            if (remainingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '+$remainingCount autre${remainingCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderBadge(BuildContext context, WatchProvider provider) {
    final style = _getPlatformStyle(provider.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: style.borderColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo ou icône
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: provider.logoUrl != null
                ? Image.network(
                    provider.logoUrl!,
                    width: 16,
                    height: 16,
                    cacheWidth: (16 * MediaQuery.devicePixelRatioOf(context)).round(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackIcon(style),
                  )
                : _buildFallbackIcon(style),
          ),
          const SizedBox(width: 6),
          // Nom clair et lisible en 11.5px
          Text(
            style.displayName,
            style: TextStyle(
              color: style.textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIcon(_PlatformStyle style) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: style.borderColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        style.displayName.isNotEmpty ? style.displayName.substring(0, 1) : '▶',
        style: TextStyle(
          color: style.borderColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _PlatformStyle _getPlatformStyle(String rawName) {
    final lower = rawName.toLowerCase();

    // Netflix : rouge foncé
    if (lower.contains('netflix')) {
      return const _PlatformStyle(
        displayName: 'Netflix',
        backgroundColor: Color(0xFF260505),
        borderColor: Color(0xFFE50914),
        textColor: Color(0xFFFFEEEE),
      );
    }

    // Amazon Prime Video : bleu nuit
    if (lower.contains('prime') || lower.contains('amazon')) {
      return const _PlatformStyle(
        displayName: 'Prime Video',
        backgroundColor: Color(0xFF03192B),
        borderColor: Color(0xFF00A8E1),
        textColor: Color(0xFFDDF5FF),
      );
    }

    // Apple TV : gris sombre / argent
    if (lower.contains('apple')) {
      return const _PlatformStyle(
        displayName: 'Apple TV',
        backgroundColor: Color(0xFF1C1C1E),
        borderColor: Color(0xFF8E8E93),
        textColor: Color(0xFFF2F2F7),
      );
    }

    // Disney+ : bleu Disney
    if (lower.contains('disney')) {
      return const _PlatformStyle(
        displayName: 'Disney+',
        backgroundColor: Color(0xFF061435),
        borderColor: Color(0xFF113CCF),
        textColor: Color(0xFFE5EDFF),
      );
    }

    // HBO Max : violet sombre
    if (lower.contains('max') || lower.contains('hbo')) {
      return const _PlatformStyle(
        displayName: 'Max',
        backgroundColor: Color(0xFF160829),
        borderColor: Color(0xFF9E47FF),
        textColor: Color(0xFFF4EBFF),
      );
    }

    // Canal+ : or sombre
    if (lower.contains('canal')) {
      return const _PlatformStyle(
        displayName: 'Canal+',
        backgroundColor: Color(0xFF221A04),
        borderColor: Color(0xFFFFCC00),
        textColor: Color(0xFFFFF8D6),
      );
    }

    // Paramount+ : bleu électrique sombre
    if (lower.contains('paramount')) {
      return const _PlatformStyle(
        displayName: 'Paramount+',
        backgroundColor: Color(0xFF041635),
        borderColor: Color(0xFF0064FF),
        textColor: Color(0xFFE5F0FF),
      );
    }

    // Plateformes diverses : gris sombre
    return _PlatformStyle(
      displayName: _cleanGenericName(rawName),
      backgroundColor: const Color(0xFF171B26),
      borderColor: const Color(0xFF384259),
      textColor: const Color(0xFFCBD5E1),
    );
  }

  String _cleanGenericName(String name) {
    var clean = name;
    for (final s in [' Standard with Ads', ' with Ads', ' Channel']) {
      clean = clean.replaceAll(s, '');
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
