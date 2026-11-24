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
    final colors = context.cineColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;
        final posterWidth = isCompact ? 76.0 : 92.0;
        final posterHeight = posterWidth * 1.5;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 2,
                color: colors.accent,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 8, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.movie_filter_outlined,
                      color: colors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'FILM DE RÉFÉRENCE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colors.textMuted,
                        size: 17,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Retirer ce film de référence',
                      onPressed: onClear,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 14 : 17,
                  4,
                  isCompact ? 14 : 17,
                  17,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: movie.posterUrl != null
                          ? Image.network(
                              movie.posterUrl!,
                              width: posterWidth,
                              height: posterHeight,
                              cacheWidth: (posterWidth *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                              fit: BoxFit.cover,
                              semanticLabel: 'Affiche de ${movie.title}',
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(colors, posterWidth, posterHeight),
                            )
                          : _buildPlaceholder(colors, posterWidth, posterHeight),
                    ),
                    SizedBox(width: isCompact ? 13 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
                              color: colors.textPrimary,
                              fontSize: isCompact ? 20 : 23,
                              height: 1.12,
                              fontWeight: FontWeight.w600,
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
                                    '${movie.voteAverage.toStringAsFixed(1)}/10',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${movie.voteCount} votes',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cadence : ${_getPacingLabel(movie.pacing)} · ${(movie.pacing * 100).toInt()}%',
                            style: TextStyle(
                              color: colors.cyan,
                              fontSize: 10,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: movie.atmosphereTags.take(4).map((tag) {
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
                                  '#$tag',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (movie.streamingProviders.isNotEmpty) ...[
                            const SizedBox(height: 11),
                            StreamingBadges(
                              providers: movie.streamingProviders,
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
            ],
          ),
        );
      },
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
        size: 26,
      ),
    );
  }
}
