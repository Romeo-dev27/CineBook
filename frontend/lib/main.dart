import 'package:flutter/material.dart';
import 'models/movie.dart';
import 'models/recommendation.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/movie_search_bar.dart';
import 'widgets/reference_card.dart';
import 'widgets/weight_sliders.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/auth_dialog.dart';
import 'widgets/watchlist_drawer.dart';

void main() {
  runApp(const CineBookApp());
}

class CineBookApp extends StatelessWidget {
  const CineBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineBook — Recommandation Cinématographique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<MovieBrief> _selectedSeeds = [];
  RecommendationWeights _weights = RecommendationWeights.equilibre;
  double _discoverySlider = 0.3;
  int _topN = 5;
  String _selectedProvider = 'Tous';
  static const List<String> _providerOptions = [
    'Tous',
    'Netflix',
    'Amazon Prime Video',
    'Apple TV',
  ];

  bool _isLoading = false;
  RecommendResponse? _response;
  String? _errorMessage;

  List<MovieBrief> _quickPicks = [];
  bool _isLoadingQuickPicks = true;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
    _loadQuickPicks();
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadQuickPicks() async {
    try {
      final movies = await _apiService.getMovies(limit: 6);
      if (mounted) {
        setState(() {
          _quickPicks = movies;
          _isLoadingQuickPicks = false;
          if (movies.isNotEmpty && _selectedSeeds.isEmpty) {
            final defaultSeed = movies.firstWhere(
              (m) => m.title.contains('Blade Runner 2049'),
              orElse: () => movies.first,
            );
            _selectedSeeds.add(defaultSeed);
          }
        });
        if (_selectedSeeds.isNotEmpty) {
          _fetchRecommendations();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingQuickPicks = false);
      }
    }
  }

  void _toggleSeed(MovieBrief movie) {
    final exists = _selectedSeeds.any((m) => m.id == movie.id);
    setState(() {
      if (exists) {
        _selectedSeeds.removeWhere((m) => m.id == movie.id);
      } else {
        _selectedSeeds.add(movie);
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              exists ? Icons.remove_circle_outline : Icons.auto_awesome,
              color: AppTheme.gold,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exists
                    ? '"${movie.title}" retiré du mix.'
                    : '"${movie.title}" ajouté au mix ! (${_selectedSeeds.length} film${_selectedSeeds.length > 1 ? 's' : ''})',
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );

    if (_selectedSeeds.isNotEmpty) {
      _fetchRecommendations();
    } else {
      setState(() => _response = null);
    }
  }

  Future<void> _fetchRecommendations() async {
    if (_selectedSeeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un film de référence.'),
          backgroundColor: AppTheme.ruby,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.getRecommendations(
        movieIds: _selectedSeeds.map((m) => m.id).toList(),
        topN: _topN,
        weights: _weights,
        discoverySlider: _discoverySlider,
        provider: _selectedProvider == 'Tous' ? null : _selectedProvider,
      );
      if (mounted) {
        setState(() {
          _response = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleToggleWatchlist(RecommendationItem movie) async {
    if (!_authService.isAuthenticated) {
      final loggedIn = await AuthDialog.show(context, _authService);
      if (loggedIn != true || !mounted) return;
    }

    final isAlreadySaved = _authService.isMovieInWatchlist(movie.id);

    try {
      if (isAlreadySaved) {
        await _authService.removeFromWatchlist(movie.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Film retiré de votre Watchlist : "${movie.title}"',
              ),
              backgroundColor: AppTheme.surfaceElevated,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _authService.addToWatchlist(movie.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.bookmark, color: AppTheme.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('"${movie.title}" ajouté à votre Watchlist !'),
                  ),
                ],
              ),
              backgroundColor: AppTheme.surfaceElevated,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.ruby,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    final isCompact = screenWidth < 600;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: WatchlistDrawer(
        authService: _authService,
        onSelectMovie: (movie) {
          setState(() {
            if (!_selectedSeeds.any((s) => s.id == movie.id)) {
              _selectedSeeds.add(movie);
            }
          });
          _fetchRecommendations();
        },
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.movie_creation_outlined,
                color: AppTheme.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'CineBook',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'FLUTTER + SUPABASE AUTH',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Statut ou Bouton Auth
          if (!_authService.isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.login, size: 16, color: AppTheme.gold),
                label: const Text(
                  'Connexion',
                  style: TextStyle(color: AppTheme.gold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => AuthDialog.show(context, _authService),
              ),
            )
          else ...[
            // Bouton Watchlist avec compteur
            InkWell(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmarks, color: AppTheme.gold, size: 16),
                    if (!isCompact) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'Watchlist',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_authService.watchlist.length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Profil Utilisateur
            IconButton(
              icon: const Icon(
                Icons.account_circle,
                color: AppTheme.textSecondary,
                size: 28,
              ),
              tooltip: _authService.currentUser?.email,
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 420,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildControlsSection(),
          ),
        ),
        const VerticalDivider(color: AppTheme.border, width: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildResultsSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildControlsSection(),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 16),
        ..._buildResultsChildren(),
      ],
    );
  }

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStreamingFilterBar(),
        const SizedBox(height: 18),

        const Text(
          '1. Choisis tes films de référence (Multi-sélection & Mix)',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        MovieSearchBar(
          apiService: _apiService,
          selectedSeeds: _selectedSeeds,
          onSelectionChanged: (seeds) {
            setState(() => _selectedSeeds = List.from(seeds));
            if (_selectedSeeds.isNotEmpty) {
              _fetchRecommendations();
            } else {
              setState(() => _response = null);
            }
          },
          onClearAllSeeds: () {
            setState(() {
              _selectedSeeds.clear();
              _response = null;
            });
          },
        ),

        if (!_isLoadingQuickPicks && _quickPicks.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPicks.map((m) {
                final isSelected = _selectedSeeds.any((s) => s.id == m.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    avatar: Icon(
                      isSelected ? Icons.check : Icons.add,
                      size: 13,
                      color: isSelected ? AppTheme.gold : AppTheme.textMuted,
                    ),
                    label: Text(m.title),
                    backgroundColor: isSelected
                        ? AppTheme.gold.withValues(alpha: 0.2)
                        : AppTheme.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppTheme.gold : AppTheme.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.gold
                          : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onPressed: () => _toggleSeed(m),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 16),

        if (_selectedSeeds.length == 1) ...[
          ReferenceCard(
            movie: _selectedSeeds.first,
            onClear: () {
              setState(() {
                _selectedSeeds.clear();
                _response = null;
              });
            },
          ),
          const SizedBox(height: 20),
        ] else if (_selectedSeeds.length > 1) ...[
          _buildBlendedSeedsCard(),
          const SizedBox(height: 20),
        ],

        const Text(
          '2. Ajuste les dimensions de recommandation',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        WeightSliders(
          weights: _weights,
          discoverySlider: _discoverySlider,
          topN: _topN,
          onWeightsChanged: (w) => setState(() => _weights = w),
          onDiscoveryChanged: (d) => setState(() => _discoverySlider = d),
          onTopNChanged: (n) => setState(() => _topN = n),
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.auto_awesome, color: Colors.black),
            label: Text(
              _isLoading
                  ? 'CALCUL DU COSINUS EN COURS...'
                  : (_selectedSeeds.length > 1
                        ? 'MIXER LES ${_selectedSeeds.length} FILMS 🎬'
                        : 'GÉNÉRER LES RECOMMANDATIONS 🎬'),
            ),
            onPressed: _isLoading ? null : _fetchRecommendations,
          ),
        ),
      ],
    );
  }

  Widget _buildBlendedSeedsCard() {
    final allGenres = <String>{};
    for (final m in _selectedSeeds) {
      allGenres.addAll(m.genres);
    }
    final avgPacing =
        _selectedSeeds.map((m) => m.pacing).reduce((a, b) => a + b) /
        _selectedSeeds.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: AppTheme.gold,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'VIBE MIXTE ACTIVE (${_selectedSeeds.length} FILMS)',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedSeeds.clear();
                    _response = null;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Tout effacer',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Moyenne mathématique (centroid) de vos films sélectionnés :',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _selectedSeeds.map((movie) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: movie.posterUrl != null
                            ? Image.network(
                                movie.posterUrl!,
                                width: 54,
                                height: 80,
                                cacheWidth:
                                    (54 *
                                            MediaQuery.devicePixelRatioOf(
                                              context,
                                            ))
                                        .round(),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 54,
                                  height: 80,
                                  color: AppTheme.surfaceElevated,
                                  child: const Icon(
                                    Icons.movie,
                                    size: 20,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              )
                            : Container(
                                width: 54,
                                height: 80,
                                color: AppTheme.surfaceElevated,
                                child: const Icon(
                                  Icons.movie,
                                  size: 20,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => _toggleSeed(movie),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Rythme moyen : ${(avgPacing * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...allGenres
                  .take(4)
                  .map(
                    (g) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        g,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildResultsChildren(),
    );
  }

  List<Widget> _buildResultsChildren() {
    if (_errorMessage != null) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.ruby.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.ruby.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.ruby, size: 36),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.ruby, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchRecommendations,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ruby),
                child: const Text(
                  'Réessayer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (_isLoading) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 80),
          alignment: Alignment.center,
          child: const Column(
            children: [
              CircularProgressIndicator(color: AppTheme.gold),
              SizedBox(height: 20),
              Text(
                'Calcul de la Similarité Cosinus Pondérée...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              SizedBox(height: 6),
              Text(
                'Comparaison des 6 vecteurs et application du filtre de découverte',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ];
    }

    if (_response == null || _response!.recommendations.isEmpty) {
      final isFiltered = _selectedProvider != 'Tous';
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                Icons.movie_filter_outlined,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                isFiltered
                    ? 'Aucun film trouvé sur $_selectedProvider pour cette sélection'
                    : 'Aucune recommandation générée pour l\'instant',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isFiltered
                    ? 'Essayez de repasser sur "Tous" ou d\'ajuster vos curseurs pour élargir la recherche.'
                    : 'Choisis un film de référence à gauche puis clique sur Générer.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              if (isFiltered) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.refresh,
                    size: 16,
                    color: AppTheme.gold,
                  ),
                  label: const Text(
                    'Afficher toutes les plateformes',
                    style: TextStyle(color: AppTheme.gold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.gold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() => _selectedProvider = 'Tous');
                    _fetchRecommendations();
                  },
                ),
              ],
            ],
          ),
        ),
      ];
    }

    final recs = _response!.recommendations;

    final String title;
    final String subtitle;
    if (_selectedSeeds.length > 1) {
      title =
          'Top ${recs.length} Recommandations pour votre mix (${_selectedSeeds.length} films)';
      subtitle =
          'Moyenne mathématique pondérée sur : ${_selectedSeeds.map((s) => s.title).join(' + ')}';
    } else {
      final refTitle = _selectedSeeds.isNotEmpty
          ? _selectedSeeds.first.title
          : _response!.referenceMovie.title;
      title = 'Top ${recs.length} Recommandations pour "$refTitle"';
      subtitle =
          'Classées par similarité mathématique multidimensionnelle (ambiance, visuel, rythme, genre, époque).';
    }

    return [
      Row(
        children: [
          const Icon(Icons.recommend, color: AppTheme.gold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
      if (_selectedProvider != 'Tous') ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _getProviderBgColor(_selectedProvider),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getProviderBorderColor(_selectedProvider),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChoiceChipAvatar(_selectedProvider, true) ??
                  const SizedBox.shrink(),
              const SizedBox(width: 6),
              Text(
                'Filtre actif : $_selectedProvider',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() => _selectedProvider = 'Tous');
                  _fetchRecommendations();
                },
                child: const Icon(Icons.close, size: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),

      ...List.generate(recs.length, (index) {
        final item = recs[index];
        final isSeed = _selectedSeeds.any((s) => s.id == item.id);
        return RepaintBoundary(
          child: RecommendationCard(
            item: item,
            rank: index + 1,
            isWatchlisted: _authService.isMovieInWatchlist(item.id),
            onToggleWatchlist: () => _handleToggleWatchlist(item),
            isSelectedSeed: isSeed,
            onToggleSeed: () => _toggleSeed(item.toMovieBrief()),
          ),
        );
      }),
    ];
  }

  Widget _buildStreamingFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.live_tv_rounded, size: 14, color: AppTheme.gold),
              const SizedBox(width: 6),
              const Text(
                'PLATEFORME DE STREAMING',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              if (_selectedProvider != 'Tous') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: _getProviderBorderColor(
                      _selectedProvider,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getProviderBorderColor(_selectedProvider),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _selectedProvider,
                    style: TextStyle(
                      color: _getProviderBorderColor(_selectedProvider),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _providerOptions.map((provider) {
                final isSelected = _selectedProvider == provider;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: _buildChoiceChipAvatar(provider, isSelected),
                    label: Text(provider),
                    selected: isSelected,
                    selectedColor: _getProviderBgColor(provider),
                    backgroundColor: AppTheme.surface,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? _getProviderBorderColor(provider)
                            : AppTheme.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected && _selectedProvider != provider) {
                        setState(() {
                          _selectedProvider = provider;
                        });
                        if (_selectedSeeds.isNotEmpty) {
                          _fetchRecommendations();
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildChoiceChipAvatar(String provider, bool isSelected) {
    if (provider == 'Tous') {
      return Icon(
        Icons.auto_awesome,
        size: 13,
        color: isSelected ? AppTheme.gold : AppTheme.textMuted,
      );
    }
    if (provider == 'Netflix') {
      return Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFFE50914),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    if (provider == 'Amazon Prime Video') {
      return Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFF00A8E1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 10),
      );
    }
    if (provider == 'Apple TV') {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.tv, color: Colors.white, size: 10),
      );
    }
    return null;
  }

  Color _getProviderBgColor(String provider) {
    if (provider == 'Netflix') return const Color(0xFF380606);
    if (provider == 'Amazon Prime Video') return const Color(0xFF042138);
    if (provider == 'Apple TV') return const Color(0xFF2C2C2E);
    return AppTheme.gold.withValues(alpha: 0.22);
  }

  Color _getProviderBorderColor(String provider) {
    if (provider == 'Netflix') return const Color(0xFFE50914);
    if (provider == 'Amazon Prime Video') return const Color(0xFF00A8E1);
    if (provider == 'Apple TV') return const Color(0xFFA2AAAD);
    return AppTheme.gold;
  }
}
