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
import 'widgets/cinematic_backdrop.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: isCompact ? 64 : 78,
        titleSpacing: isCompact ? 16 : 24,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.goldLight, AppTheme.gold],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.movie_filter_rounded,
                color: Color(0xFF171006),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'CINE',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                          ),
                        ),
                        TextSpan(
                          text: 'BOOK',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact)
                    const Text(
                      'LE CINÉMA, PAR ATMOSPHÈRE',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                ],
              ),
            ),
            if (screenWidth >= 1100) ...[
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTheme.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'RECOMMANDATION SUR MESURE',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
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
      body: CinematicBackdrop(
        child: SafeArea(
          child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHero(isDesktop: true),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 440,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  child: _buildControlsSection(),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(32, 4, 32, 40),
                  child: _buildResultsSection(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _buildHero(isDesktop: false),
        _buildControlsSection(),
        const SizedBox(height: 32),
        ..._buildResultsChildren(),
      ],
    );
  }

  Widget _buildHero({required bool isDesktop}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 0,
        isDesktop ? 20 : 8,
        isDesktop ? 24 : 0,
        isDesktop ? 24 : 26,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceElevated.withValues(alpha: 0.88),
                AppTheme.surface.withValues(alpha: 0.96),
                AppTheme.cyan.withValues(alpha: 0.035),
              ],
            ),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(isDesktop ? 30 : 22),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.gold.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.gold.withValues(
                                          alpha: 0.32,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'CINEBOOK PRÉSENTE',
                                      style: TextStyle(
                                        color: AppTheme.goldLight,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyan.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.cyan.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'SÉANCE 001',
                                      style: TextStyle(
                                        color: AppTheme.cyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isDesktop ? 20 : 18),
                              Text.rich(
                                const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'TON CINÉMA.\n',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'TES VIBES.',
                                      style: TextStyle(
                                        color: AppTheme.goldLight,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  fontSize: isDesktop ? 48 : 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1.04,
                                  letterSpacing: -1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Un film suffit pour trouver la prochaine séance qui te ressemble.',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: isDesktop ? 17 : 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 650,
                                ),
                                child: Text(
                                  'Mixe les ambiances, ajuste le rythme et explore une sélection pensée pour toi, entre valeurs sûres et belles découvertes.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: isDesktop ? 14 : 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _HeroVibeTag(
                                    label: 'RESSENS',
                                    icon: Icons.favorite_rounded,
                                    color: AppTheme.gold,
                                  ),
                                  _HeroVibeTag(
                                    label: 'EXPLORE',
                                    icon: Icons.explore_rounded,
                                    color: AppTheme.cyan,
                                  ),
                                  _HeroVibeTag(
                                    label: 'DÉCOUVRE',
                                    icon: Icons.auto_awesome_rounded,
                                    color: AppTheme.purple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 28),
                          Container(
                            width: 220,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated.withValues(
                                alpha: 0.78,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color: AppTheme.gold,
                                      size: 18,
                                    ),
                                    SizedBox(width: 7),
                                    Text(
                                      'VIBE ENGINE',
                                      style: TextStyle(
                                        color: AppTheme.goldLight,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  '142',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'films à explorer',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '5 DIMENSIONS',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '∞ POSSIBILITÉS',
                                      style: TextStyle(
                                        color: AppTheme.cyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    for (final color in [
                                      AppTheme.gold,
                                      AppTheme.goldLight,
                                      AppTheme.cyan,
                                      AppTheme.purple,
                                      AppTheme.textMuted,
                                    ])
                                      Expanded(
                                        child: Container(
                                          height: 5,
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          'AMBIANCE  •  COULEUR  •  RYTHME  •  ÉPOQUE  •  GENRE  •  DÉCOUVERTE',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStreamingFilterBar(),
        const SizedBox(height: 18),

        _buildStepHeading(
          number: '01',
          eyebrow: 'LE CASTING',
          title: 'Choisis tes films de référence',
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
          const SizedBox(height: 14),
          const Text(
            'SÉLECTION RAPIDE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
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
                      color: isSelected
                          ? const Color(0xFF171006)
                          : AppTheme.cyan,
                    ),
                    label: Text(m.title),
                    backgroundColor: isSelected
                        ? AppTheme.gold
                        : AppTheme.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppTheme.goldLight : AppTheme.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF171006)
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

        _buildStepHeading(
          number: '02',
          eyebrow: 'LA RÉGIE',
          title: 'Compose ton ambiance',
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

        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF171006),
                    ),
                  )
                : const Icon(Icons.auto_awesome, color: Color(0xFF171006)),
            label: Text(
              _isLoading
                  ? 'COMPOSITION EN COURS...'
                  : (_selectedSeeds.length > 1
                        ? 'MIXER LES ${_selectedSeeds.length} FILMS'
                        : 'COMPOSER MA SÉLECTION'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: const Color(0xFF171006),
              disabledForegroundColor: const Color(0xFF171006),
            ),
            onPressed: _isLoading ? null : _fetchRecommendations,
          ),
        ),
      ],
    );
  }

  Widget _buildStepHeading({
    required String number,
    required String eyebrow,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF171006),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppTheme.cyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gold.withValues(alpha: 0.10),
            AppTheme.surface.withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.35),
          width: 1.2,
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
                'La projection se prépare...',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
                Icons.theaters_outlined,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                isFiltered
                    ? 'Aucun film trouvé sur $_selectedProvider pour cette sélection'
                    : 'La salle est prête. À vous de choisir le premier film.',
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
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'TA SÉANCE SUR MESURE',
                  style: TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    color: AppTheme.cyan,
                    size: 17,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'VIBES EN DIRECT',
                    style: TextStyle(
                      color: AppTheme.cyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
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
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 320 + index * 60),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: child,
            ),
          ),
          child: RepaintBoundary(
            child: RecommendationCard(
              item: item,
              rank: index + 1,
              isWatchlisted: _authService.isMovieInWatchlist(item.id),
              onToggleWatchlist: () => _handleToggleWatchlist(item),
              isSelectedSeed: isSeed,
              onToggleSeed: () => _toggleSeed(item.toMovieBrief()),
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildStreamingFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.live_tv_rounded, size: 14, color: AppTheme.gold),
              const SizedBox(width: 6),
              const Text(
                'DISPONIBILITÉ · STREAMING',
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

class _HeroVibeTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeroVibeTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
