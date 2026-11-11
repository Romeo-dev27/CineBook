import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'streaming_badges.dart';

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
    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bookmarks, color: AppTheme.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ma Watchlist',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          authService.currentUser?.email ?? 'Connecté',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Liste des films
            Expanded(
              child: ListenableBuilder(
                listenable: authService,
                builder: (context, _) {
                  final items = authService.watchlist;

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Votre Watchlist est vide',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cliquez sur l\'icône de signet sur une carte de film pour l\'enregistrer ici.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildWatchlistItemCard(context, item);
                    },
                  );
                },
              ),
            ),

            // Bouton Déconnexion en bas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 16, color: AppTheme.ruby),
                label: const Text('Se déconnecter', style: TextStyle(color: AppTheme.ruby)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.ruby),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildWatchlistItemCard(BuildContext context, WatchlistItem item) {
    final movie = item.movie;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.posterUrl != null
                  ? Image.network(
                      movie.posterUrl!,
                      width: 50,
                      height: 75,
                      cacheWidth: (50 * MediaQuery.devicePixelRatioOf(context)).round(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Détails
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${movie.year}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: AppTheme.gold, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      ),
                    ],
                  ),
                  if (movie.streamingProviders.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    StreamingBadges(
                      providers: movie.streamingProviders,
                      logoSize: 18.0,
                      showHeader: false,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Bouton Recommander depuis ce film
                      InkWell(
                        onTap: () {
                          onSelectMovie(movie);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: AppTheme.gold, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Recommander',
                                style: TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Bouton Supprimer
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
                        tooltip: 'Retirer de la watchlist',
                        onPressed: () {
                          authService.removeFromWatchlist(item.movieId);
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

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 75,
      color: AppTheme.surfaceElevated,
      child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 24),
    );
  }
}
