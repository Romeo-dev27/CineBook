import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'streaming_badges.dart';

class ReferenceCard extends StatelessWidget {
  final MovieBrief movie;
  final VoidCallback onClear;

  const ReferenceCard({super.key, required this.movie, required this.onClear});

  String _getPacingLabel(double pacing) {
    if (pacing < 0.35) return 'Très lent / Hypnotique';
    if (pacing < 0.50) return 'Contemplatif';
    if (pacing < 0.65) return 'Équilibré';
    if (pacing < 0.80) return 'Soutenu';
    return 'Frénétique / Haletant';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;
        final posterWidth = isCompact ? 76.0 : 92.0;
        final posterHeight = posterWidth * 1.5;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.gold.withValues(alpha: 0.06), AppTheme.surface],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 9, 10, 9),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.gold.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.movie_filter_rounded,
                      color: AppTheme.goldLight,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'FILM DE RÉFÉRENCE',
                        style: TextStyle(
                          color: AppTheme.goldLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Changer de film',
                      onPressed: onClear,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isCompact ? 14 : 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: movie.posterUrl != null
                            ? Image.network(
                                movie.posterUrl!,
                                width: posterWidth,
                                height: posterHeight,
                                cacheWidth:
                                    (posterWidth *
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ))
                                        .round(),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(
                                      posterWidth,
                                      posterHeight,
                                    ),
                              )
                            : _buildPlaceholder(posterWidth, posterHeight),
                      ),
                    ),
                    SizedBox(width: isCompact ? 13 : 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: isCompact ? 17 : 19,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${movie.year}',
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
                                    '${movie.voteAverage.toStringAsFixed(1)}/10',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${movie.voteCount} votes',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.speed_rounded,
                                  color: AppTheme.cyan,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cadence : ${_getPacingLabel(movie.pacing)} · ${(movie.pacing * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: AppTheme.cyan,
                                    fontSize: 11,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: movie.atmosphereTags.take(4).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceElevated.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (movie.streamingProviders.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            StreamingBadges(
                              providers: movie.streamingProviders,
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
            ],
          ),
        );
      },
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
