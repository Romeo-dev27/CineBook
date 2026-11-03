import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

class StreamingBadges extends StatelessWidget {
  final List<WatchProvider> providers;
  final double logoSize;
  final bool showHeader;
  final int maxBadges;

  const StreamingBadges({
    super.key,
    required this.providers,
    this.logoSize = 24.0,
    this.showHeader = true,
    this.maxBadges = 5,
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
              Icon(Icons.play_circle_fill_rounded, size: 13, color: AppTheme.gold.withValues(alpha: 0.9)),
              const SizedBox(width: 5),
              const Text(
                'STREAMING',
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
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...displayProviders.map((p) => _buildProviderBadge(context, p)),
            if (remainingCount > 0)
              Container(
                height: logoSize,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProviderBadge(BuildContext context, WatchProvider provider) {
    return Tooltip(
      message: 'Disponible sur ${provider.name}',
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      child: Container(
        width: logoSize,
        height: logoSize,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _getBrandBorderColor(provider.name),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: provider.logoUrl != null
              ? Image.network(
                  provider.logoUrl!,
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackPill(provider),
                )
              : _buildFallbackPill(provider),
        ),
      ),
    );
  }

  Color _getBrandBorderColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('netflix')) return const Color(0xFFE50914).withValues(alpha: 0.6);
    if (lower.contains('prime') || lower.contains('amazon')) return const Color(0xFF00A8E1).withValues(alpha: 0.6);
    if (lower.contains('disney')) return const Color(0xFF113CCF).withValues(alpha: 0.6);
    if (lower.contains('max') || lower.contains('hbo')) return const Color(0xFF5822B4).withValues(alpha: 0.6);
    if (lower.contains('apple')) return Colors.white.withValues(alpha: 0.4);
    if (lower.contains('canal')) return AppTheme.gold.withValues(alpha: 0.6);
    return AppTheme.border;
  }

  Widget _buildFallbackPill(WatchProvider provider) {
    final initial = provider.name.isNotEmpty ? provider.name.substring(0, 1).toUpperCase() : '▶';
    return Container(
      color: AppTheme.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: _getBrandBorderColor(provider.name),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
