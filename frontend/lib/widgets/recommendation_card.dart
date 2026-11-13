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
    final matchPercentage = (item.score * 100).toInt();
    final scoreColor = [
      AppTheme.gold,
      AppTheme.cyan,
      AppTheme.purple,
    ][(rank - 1) % 3];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final posterWidth = isCompact ? 82.0 : 104.0;
        final posterHeight = posterWidth * 1.5;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scoreColor.withValues(alpha: 0.055),
                AppTheme.surface.withValues(alpha: 0.99),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scoreColor.withValues(alpha: 0.26),
              width: item.isDiscoveryGem ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isCompact ? 14 : 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: scoreColor.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.30),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: SizedBox(
                              width: posterWidth,
                              height: posterHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (item.posterUrl != null)
                                    Image.network(
                                      item.posterUrl!,
                                      cacheWidth:
                                          (posterWidth *
                                                  MediaQuery.devicePixelRatioOf(
                                                    context,
                                                  ))
                                              .round(),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildPlaceholder(
                                                posterWidth,
                                                posterHeight,
                                              ),
                                    )
                                  else
                                    _buildPlaceholder(
                                      posterWidth,
                                      posterHeight,
                                    ),
                                  Positioned(
                                    top: 7,
                                    left: 7,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated
                                            .withValues(alpha: 0.94),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: scoreColor.withValues(
                                            alpha: 0.55,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'N° ${rank.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: scoreColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (onToggleSeed != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: posterWidth,
                            height: 32,
                            child: OutlinedButton(
                              onPressed: onToggleSeed,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                side: BorderSide(
                                  color: isSelectedSeed
                                      ? AppTheme.gold
                                      : AppTheme.border,
                                ),
                                backgroundColor: isSelectedSeed
                                    ? AppTheme.gold.withValues(alpha: 0.16)
                                    : AppTheme.surfaceElevated,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelectedSeed ? Icons.check : Icons.add,
                                    size: 13,
                                    color: isSelectedSeed
                                        ? AppTheme.goldLight
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    isSelectedSeed ? 'AJOUTÉ' : 'MIXER +',
                                    style: TextStyle(
                                      color: isSelectedSeed
                                          ? AppTheme.goldLight
                                          : AppTheme.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scoreColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: scoreColor.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '$matchPercentage% VIBE',
                                        style: TextStyle(
                                          color: scoreColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    if (item.isDiscoveryGem)
                                      _buildDiscoveryBadge(),
                                  ],
                                ),
                              ),
                              if (onToggleWatchlist != null ||
                                  onToggleSeed != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (onToggleWatchlist != null)
                                      _buildActionButton(
                                        icon: isWatchlisted
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: isWatchlisted
                                            ? AppTheme.goldLight
                                            : AppTheme.textMuted,
                                        tooltip: isWatchlisted
                                            ? 'Retirer de la watchlist'
                                            : 'Ajouter à la watchlist',
                                        onPressed: onToggleWatchlist!,
                                      ),
                                    if (onToggleWatchlist != null &&
                                        onToggleSeed != null)
                                      const SizedBox(width: 5),
                                    if (onToggleSeed != null)
                                      _buildActionButton(
                                        icon: isSelectedSeed
                                            ? Icons.check_circle
                                            : Icons.playlist_add,
                                        color: isSelectedSeed
                                            ? AppTheme.goldLight
                                            : AppTheme.textMuted,
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
                              color: AppTheme.textPrimary,
                              fontSize: isCompact ? 18 : 20,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${item.year}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.gold,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.voteAverage.toStringAsFixed(1)}/10',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${item.voteCount} avis',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
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
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated.withValues(
                                    alpha: 0.75,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.border.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  genre,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
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
                              logoSize: 22,
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
                  15,
                  isCompact ? 14 : 18,
                  16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withValues(alpha: 0.035),
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(17),
                  ),
                  border: const Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          color: scoreColor,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'POURQUOI CETTE VIBE ?',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.explanation.isNotEmpty
                          ? item.explanation
                          : 'Similarité générale calculée sur les 6 vecteurs de caractéristiques.',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Wrap(
                      spacing: 14,
                      runSpacing: 11,
                      children: item.subScores.entries
                          .map(_buildSubScore)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDiscoveryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, color: AppTheme.cyan, size: 12),
          SizedBox(width: 4),
          Text(
            'PÉPITE',
            style: TextStyle(
              color: AppTheme.cyan,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubScore(MapEntry<String, double> entry) {
    final percent = (entry.value * 100).toInt();
    final color = entry.value >= 0.70 ? AppTheme.emerald : AppTheme.goldLight;

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
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: entry.value.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceElevated,
      child: const Icon(
        Icons.movie_outlined,
        color: AppTheme.textMuted,
        size: 30,
      ),
    );
  }
}
