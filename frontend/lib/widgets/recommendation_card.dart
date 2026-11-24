import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../theme/app_theme.dart';
import 'streaming_badges.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationItem item;
  final int rank;
  final bool isWatchlisted;
  final VoidCallback? onToggleWatchlist;
  final bool isSelectedSeed;
  final VoidCallback? onToggleSeed;

  const RecommendationCard({
    super.key,
    required this.item,
    required this.rank,
    this.isWatchlisted = false,
    this.onToggleWatchlist,
    this.isSelectedSeed = false,
    this.onToggleSeed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.cineColors;
    final matchPercentage = (item.score * 100).toInt();
    final scoreColor = [
      colors.accent,
      colors.cyan,
      colors.purple,
    ][(rank - 1) % 3];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final posterWidth = isCompact ? 82.0 : 104.0;
        final posterHeight = posterWidth * 1.5;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 2,
                color: scoreColor.withValues(alpha: item.isDiscoveryGem ? 1 : 0.55),
              ),
              Padding(
                padding: EdgeInsets.all(isCompact ? 14 : 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            width: posterWidth,
                            height: posterHeight,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (item.posterUrl != null)
                                  Image.network(
                                    item.posterUrl!,
                                    cacheWidth: (posterWidth *
                                            MediaQuery.devicePixelRatioOf(context))
                                        .round(),
                                    fit: BoxFit.cover,
                                    semanticLabel: 'Affiche de ${item.title}',
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPlaceholder(colors, posterWidth, posterHeight),
                                  )
                                else
                                  _buildPlaceholder(colors, posterWidth, posterHeight),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 5,
                                    ),
                                    color: colors.background.withValues(alpha: 0.9),
                                    child: Text(
                                      'N° ${rank.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (onToggleSeed != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: posterWidth,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: onToggleSeed,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                side: BorderSide(
                                  color: isSelectedSeed
                                      ? colors.accent
                                      : colors.border,
                                ),
                                backgroundColor: isSelectedSeed
                                    ? colors.accent.withValues(alpha: 0.1)
                                    : colors.surfaceElevated,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelectedSeed ? Icons.check : Icons.add,
                                    size: 13,
                                    color: isSelectedSeed
                                        ? colors.accent
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      isSelectedSeed
                                          ? 'Retirer du mix'
                                          : 'Ajouter au mix',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelectedSeed
                                            ? colors.accent
                                            : colors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(width: isCompact ? 13 : 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: scoreColor.withValues(alpha: 0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  '$matchPercentage% D’AFFINITÉ',
                                  style: TextStyle(
                                    color: scoreColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              if (item.isDiscoveryGem)
                                _buildDiscoveryBadge(colors),
                              if (onToggleWatchlist != null || onToggleSeed != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (onToggleWatchlist != null)
                                      _buildActionButton(
                                        colors,
                                        icon: isWatchlisted
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: isWatchlisted
                                            ? colors.accent
                                            : colors.textMuted,
                                        tooltip: isWatchlisted
                                            ? 'Retirer de la watchlist'
                                            : 'Ajouter à la watchlist',
                                        onPressed: onToggleWatchlist!,
                                      ),
                                    if (onToggleWatchlist != null &&
                                        onToggleSeed != null)
                                      const SizedBox(width: 4),
                                    if (onToggleSeed != null)
                                      _buildActionButton(
                                        colors,
                                        icon: isSelectedSeed
                                            ? Icons.check_circle
                                            : Icons.playlist_add,
                                        color: isSelectedSeed
                                            ? colors.accent
                                            : colors.textMuted,
                                        tooltip: isSelectedSeed
                                            ? 'Retirer des films sélectionnés'
                                            : 'Ajouter à la sélection de mixage',
                                        onPressed: onToggleSeed!,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
                              color: colors.textPrimary,
                              fontSize: isCompact ? 21 : 24,
                              height: 1.12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 9,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${item.year}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: colors.gold,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.voteAverage.toStringAsFixed(1)}/10',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${item.voteCount} avis',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: item.genres.take(3).map((genre) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Text(
                                  genre,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (item.streamingProviders.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            StreamingBadges(
                              providers: item.streamingProviders,
                              logoSize: 20,
                              showHeader: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 14 : 18,
                  14,
                  isCompact ? 14 : 18,
                  16,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.35),
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POURQUOI CETTE VIBE ?',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.explanation.isNotEmpty
                          ? item.explanation
                          : 'Similarité générale calculée sur les vecteurs de caractéristiques.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.55,
                      ),
                    ),
                    if (item.subScores.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        children: item.subScores.entries
                            .map((entry) => _buildSubScore(colors, entry))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    CineBookColors colors, {
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 17),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDiscoveryBadge(CineBookColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: colors.cyan.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, color: colors.cyan, size: 11),
          const SizedBox(width: 4),
          Text(
            'PÉPITE',
            style: TextStyle(
              color: colors.cyan,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubScore(CineBookColors colors, MapEntry<String, double> entry) {
    final percent = (entry.value * 100).toInt();
    final color = entry.value >= 0.70 ? colors.emerald : colors.accent;

    return SizedBox(
      width: 126,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.key.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$percent%',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: entry.value.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: colors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(
    CineBookColors colors,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      color: colors.posterPlaceholder,
      child: Icon(
        Icons.movie_outlined,
        color: colors.textMuted,
        size: 28,
      ),
    );
  }
}
