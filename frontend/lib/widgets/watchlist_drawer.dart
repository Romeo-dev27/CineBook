import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'streaming_badges.dart';
import 'auth_dialog.dart';

class WatchlistDrawer extends StatelessWidget {
  final AuthService authService;
  final ValueChanged<MovieBrief> onSelectMovie;

  const WatchlistDrawer({
    super.key,
    required this.authService,
    required this.onSelectMovie,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.cineColors;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 18),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ma Watchlist',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            color: colors.textPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authService.currentUser?.email ??
                              'Sauvegarde personnelle',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    tooltip: 'Fermer la Watchlist',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: authService,
                builder: (context, _) {
                  final items = authService.watchlist;

                  if (!authService.isAuthenticated) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bookmarks_outlined,
                            color: colors.accent,
                            size: 44,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Garde tes films pour plus tard',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Un compte permet de sauvegarder et retrouver ta Watchlist. La recherche et les recommandations restent accessibles sans compte.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton(
                            onPressed: () =>
                                AuthDialog.show(context, authService),
                            child: const Text('Se connecter pour sauvegarder'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Continuer sans compte'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              color: colors.textMuted.withValues(alpha: 0.6),
                              size: 54,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Votre Watchlist est vide',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cliquez sur l’icône de signet sur une carte de film pour l’enregistrer ici.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildWatchlistItemCard(context, colors, items[index]),
                  );
                },
              ),
            ),
            if (authService.isAuthenticated)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: OutlinedButton.icon(
                  icon: Icon(Icons.logout, size: 16, color: colors.ruby),
                  label: Text(
                    'Se déconnecter',
                    style: TextStyle(color: colors.ruby),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.ruby),
                  ),
                  onPressed: () {
                    authService.logout();
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistItemCard(
    BuildContext context,
    CineBookColors colors,
    WatchlistItem item,
  ) {
    final movie = item.movie;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: movie.posterUrl != null
                  ? Image.network(
                      movie.posterUrl!,
                      width: 50,
                      height: 75,
                      cacheWidth: (50 * MediaQuery.devicePixelRatioOf(context))
                          .round(),
                      fit: BoxFit.cover,
                      semanticLabel: 'Affiche de ${movie.title}',
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(colors),
                    )
                  : _buildPlaceholder(colors),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${movie.year}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.star, color: colors.gold, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (movie.streamingProviders.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    StreamingBadges(
                      providers: movie.streamingProviders,
                      logoSize: 14,
                      showHeader: false,
                      maxBadges: 2,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      InkWell(
                        onTap: () {
                          onSelectMovie(movie);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.1),
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.45),
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: colors.accent,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Recommander',
                                style: TextStyle(
                                  color: colors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colors.textMuted,
                          size: 18,
                        ),
                        tooltip: 'Retirer de la watchlist',
                        onPressed: () async {
                          try {
                            await authService.removeFromWatchlist(item.movieId);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Le film n’a pas pu être retiré. Réessaie.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(CineBookColors colors) {
    return Container(
      width: 50,
      height: 75,
      color: colors.posterPlaceholder,
      child: Icon(Icons.movie, color: colors.textMuted, size: 22),
    );
  }
}
