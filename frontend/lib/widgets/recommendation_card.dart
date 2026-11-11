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


  Color _getScoreColor(double score) {
    if (score >= 0.80) return AppTheme.emerald;
    if (score >= 0.65) return AppTheme.gold;
    return AppTheme.cyan;
  }

  @override
  Widget build(BuildContext context) {
    final matchPercentage = (item.score * 100).toInt();
    final scoreColor = _getScoreColor(item.score);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isDiscoveryGem
              ? AppTheme.cyan.withValues(alpha: 0.5)
              : AppTheme.border,
          width: item.isDiscoveryGem ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: item.isDiscoveryGem
                ? AppTheme.cyan.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau supérieur (Rang, Titre, Match Score)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster + Bouton "Mixer +"
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.posterUrl != null
                          ? Image.network(
                              item.posterUrl!,
                              width: 85,
                              height: 128,
                              cacheWidth: (85 * MediaQuery.devicePixelRatioOf(context)).round(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                    if (onToggleSeed != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 85,
                        height: 28,
                        child: OutlinedButton(
                          onPressed: onToggleSeed,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            side: BorderSide(
                              color: isSelectedSeed ? AppTheme.gold : AppTheme.border,
                              width: 1,
                            ),
                            backgroundColor: isSelectedSeed
                                ? AppTheme.gold.withValues(alpha: 0.18)
                                : AppTheme.surfaceElevated,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelectedSeed ? Icons.check : Icons.add,
                                size: 12,
                                color: isSelectedSeed ? AppTheme.gold : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isSelectedSeed ? 'Ajouté' : 'Mixer +',
                                style: TextStyle(
                                  color: isSelectedSeed ? AppTheme.gold : AppTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 16),

                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rang + Badge Score
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              '#$rank',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.isDiscoveryGem)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.cyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.diamond, color: AppTheme.cyan, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pépite méconnue',
                                    style: TextStyle(
                                      color: AppTheme.cyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: scoreColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '$matchPercentage% MATCH',
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (onToggleWatchlist != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                isWatchlisted ? Icons.bookmark : Icons.bookmark_border,
                                color: isWatchlisted ? AppTheme.gold : AppTheme.textMuted,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: isWatchlisted ? 'Retirer de la watchlist' : 'Ajouter à la watchlist',
                              onPressed: onToggleWatchlist,
                            ),
                          ],
                          if (onToggleSeed != null) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                isSelectedSeed ? Icons.check_circle : Icons.playlist_add,
                                color: isSelectedSeed ? AppTheme.gold : AppTheme.textMuted,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: isSelectedSeed
                                  ? 'Retirer des films sélectionnés'
                                  : 'Ajouter à la sélection de mixage (+)',
                              onPressed: onToggleSeed,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Titre & Année
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Année, Note, Votes
                      Row(
                        children: [
                          Text(
                            '${item.year}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.star, color: AppTheme.gold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${item.voteAverage.toStringAsFixed(1)}/10',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${item.voteCount} avis)',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Genres
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.genres.take(3).map((g) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              g,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Badges de streaming (TMDb Watch Providers)
                      if (item.streamingProviders.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        StreamingBadges(
                          providers: item.streamingProviders,
                          logoSize: 22.0,
                          showHeader: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bloc "Pourquoi ce film ?" (Explication explicite)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              border: const Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppTheme.gold, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'POURQUOI CE FILM ?',
                      style: TextStyle(
                        color: AppTheme.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.explanation.isNotEmpty
                      ? item.explanation
                      : 'Similarité générale calculée sur les 6 vecteurs de caractéristiques.',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Mini barres de sous-scores
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: item.subScores.entries.map((entry) {
                    final percent = (entry.value * 100).toInt();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.key} :',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            color: entry.value >= 0.70
                                ? AppTheme.emerald
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 85,
      height: 128,
      color: AppTheme.surfaceElevated,
      child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 30),
    );
  }
}
