import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'streaming_badges.dart';

class ReferenceCard extends StatelessWidget {
  final MovieBrief movie;
  final VoidCallback onClear;

  const ReferenceCard({
    super.key,
    required this.movie,
    required this.onClear,
  });

  String _getPacingLabel(double pacing) {
    if (pacing < 0.35) return 'Très lent / Hypnotique';
    if (pacing < 0.50) return 'Contemplatif';
    if (pacing < 0.65) return 'Équilibré';
    if (pacing < 0.80) return 'Soutenu';
    return 'Frénétique / Haletant';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec label de référence
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: AppTheme.gold, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'FILM DE RÉFÉRENCE CHOISI',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Changer de film',
                  onPressed: onClear,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: movie.posterUrl != null
                      ? Image.network(
                          movie.posterUrl!,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 16),
                // Métadonnées
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${movie.year}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.star, color: AppTheme.gold, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${movie.voteAverage.toStringAsFixed(1)}/10',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${movie.voteCount} votes)',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Rythme
                      Row(
                        children: [
                          const Icon(Icons.speed, color: AppTheme.cyan, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Cadence : ${_getPacingLabel(movie.pacing)} (${(movie.pacing * 100).toInt()}%)',
                            style: const TextStyle(
                              color: AppTheme.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Tags d'atmosphère
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: movie.atmosphereTags.take(4).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (movie.streamingProviders.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        StreamingBadges(
                          providers: movie.streamingProviders,
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
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 120,
      color: AppTheme.surfaceElevated,
      child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 30),
    );
  }
}
