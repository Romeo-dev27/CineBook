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
import 'widgets/cinebook_logo.dart';
import 'services/theme_controller.dart';

void main() {
  runApp(const CineBookApp());
}

class CineBookApp extends StatefulWidget {
  const CineBookApp({super.key});

  @override
  State<CineBookApp> createState() => _CineBookAppState();
}

class _CineBookAppState extends State<CineBookApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.load();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) => MaterialApp(
        title: 'CineBook — Le cinéma, par atmosphère',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeController.themeMode,
        home: HomeScreen(themeController: _themeController),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ThemeController themeController;

  const HomeScreen({super.key, required this.themeController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CineBookColors get _colors => context.cineColors;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final ScrollController _pageController = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();
  int _recommendationRequest = 0;
  int _browseRequest = 0;
  bool _settingsChanged = false;
  List<String> _genres = [];
  String? _selectedGenre;
  String? _browseError;

  final List<MovieBrief> _selectedSeeds = [];
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
    _apiService.getGenres().then((genres) {
      if (mounted) setState(() => _genres = genres);
    });
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _authService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadQuickPicks() async {
    final request = ++_browseRequest;
    setState(() {
      _isLoadingQuickPicks = true;
      _browseError = null;
    });
    try {
      final movies = await _apiService.getMovies(
        limit: 12,
        genre: _selectedGenre,
      );
      if (mounted && request == _browseRequest) {
        setState(() {
          _quickPicks = movies;
          _isLoadingQuickPicks = false;
        });
      }
    } catch (_) {
      if (mounted && request == _browseRequest) {
        setState(() {
          _isLoadingQuickPicks = false;
          _browseError = 'Impossible de charger les suggestions.';
        });
      }
    }
  }

  void _clearSeeds() {
    setState(() {
      _selectedSeeds.clear();
      _response = null;
      _errorMessage = null;
      _isLoading = false;
      _recommendationRequest++;
    });
  }

  void _showResults() {
    FocusScope.of(context).unfocus();
    final target = _resultsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
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
              color: _colors.gold,
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
        backgroundColor: _colors.surfaceElevated,
        duration: const Duration(seconds: 3),
        action: _selectedSeeds.isEmpty
            ? null
            : SnackBarAction(
                label: 'Voir',
                textColor: _colors.goldLight,
                onPressed: _showResults,
              ),
      ),
    );

    if (_selectedSeeds.isNotEmpty) {
      _fetchRecommendations();
    } else {
      _clearSeeds();
    }
  }

  Future<void> _fetchRecommendations({bool showResults = false}) async {
    if (_selectedSeeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Veuillez sélectionner au moins un film de référence.',
          ),
          backgroundColor: _colors.ruby,
        ),
      );
      return;
    }

    final request = ++_recommendationRequest;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _settingsChanged = false;
    });
    try {
      final res = await _apiService.getRecommendations(
        movieIds: _selectedSeeds.map((m) => m.id).toList(),
        topN: _topN,
        weights: _weights,
        discoverySlider: _discoverySlider,
        provider: _selectedProvider == 'Tous' ? null : _selectedProvider,
      );
      if (mounted && request == _recommendationRequest) {
        setState(() {
          _response = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && request == _recommendationRequest) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
    if (showResults && mounted && request == _recommendationRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && request == _recommendationRequest) _showResults();
      });
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
              backgroundColor: _colors.surfaceElevated,
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
                  Icon(Icons.bookmark, color: _colors.gold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('"${movie.title}" ajouté à votre Watchlist !'),
                  ),
                ],
              ),
              backgroundColor: _colors.surfaceElevated,
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
            backgroundColor: _colors.ruby,
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
        automaticallyImplyLeading: false,
        backgroundColor: _colors.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: isCompact ? 64 : 72,
        titleSpacing: isCompact ? 12 : 24,
        bottom: isDesktop
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(68),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildHeaderSearch(),
                ),
              ),
        title: Row(
          children: [
            Flexible(
              flex: isDesktop ? 2 : 1,
              child: CineBookLogo(
                compact: isCompact,
                showTagline: !isCompact,
                onTap: () => _pageController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 32),
              Expanded(flex: 3, child: _buildHeaderSearch()),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.themeController.themeMode == ThemeMode.dark
                ? 'Passer au thème clair'
                : 'Passer au thème sombre',
            icon: Icon(
              widget.themeController.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: widget.themeController.toggle,
          ),
          if (isCompact)
            IconButton(
              tooltip: _authService.isAuthenticated
                  ? 'Watchlist (${_authService.watchlist.length})'
                  : 'Watchlist',
              icon: Badge(
                isLabelVisible: _authService.isAuthenticated &&
                    _authService.watchlist.isNotEmpty,
                label: Text('${_authService.watchlist.length}'),
                child: const Icon(Icons.bookmarks_outlined, size: 21),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                _scaffoldKey.currentState?.openEndDrawer();
              },
            )
          else
            TextButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                _scaffoldKey.currentState?.openEndDrawer();
              },
              icon: const Icon(Icons.bookmarks_outlined, size: 18),
              label: Text(
                _authService.isAuthenticated
                    ? 'Watchlist (${_authService.watchlist.length})'
                    : 'Watchlist',
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          if (isCompact && !_authService.isAuthenticated)
            IconButton(
              tooltip: 'Connexion (facultative)',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => AuthDialog.show(context, _authService),
            )
          else if (!_authService.isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Connexion'),
                onPressed: () => AuthDialog.show(context, _authService),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.account_circle, size: 24),
              tooltip: _authService.currentUser?.email,
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
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

  Widget _buildHeaderSearch() {
    return MovieSearchBar(
      apiService: _apiService,
      selectedSeeds: _selectedSeeds,
      onMovieSelected: (movie) {
        if (!_selectedSeeds.any((seed) => seed.id == movie.id)) {
          _toggleSeed(movie);
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      controller: _pageController,
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
                        color: _colors.border.withValues(alpha: 0.6),
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
    return CustomScrollView(
      controller: _pageController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHero(isDesktop: false),
                _buildControlsSection(),
                const SizedBox(height: 24),
                SizedBox(key: _resultsKey, height: 1, width: double.infinity),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList.list(
            children: [
              _buildStreamingFilterBar(),
              const SizedBox(height: 16),
              ..._buildResultsChildren(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero({required bool isDesktop}) {
    final featured = _quickPicks.isEmpty ? null : _quickPicks.first;
    final hasBackdrop = featured?.backdropUrl != null;
    final isGuest = !_authService.isAuthenticated;
    final foreground = hasBackdrop ? const Color(0xFFF8F5EE) : _colors.textPrimary;
    final secondary = hasBackdrop ? const Color(0xFFD7D2C8) : _colors.textSecondary;
    final eyebrowColor = hasBackdrop ? const Color(0xFFE4C586) : _colors.accent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 0,
        isDesktop ? 20 : 8,
        isDesktop ? 24 : 0,
        isDesktop ? 24 : 26,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 300),
        decoration: BoxDecoration(
          color: _colors.surface,
          border: Border.all(color: _colors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            if (hasBackdrop)
              Positioned.fill(
                child: Image.network(
                  featured!.backdropUrl!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  cacheWidth: (MediaQuery.sizeOf(context).width *
                          MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  semanticLabel: 'Image du film ${featured.title}',
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Color(0xFF151719)),
                ),
              ),
            if (hasBackdrop)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.88),
                        Colors.black.withValues(alpha: 0.52),
                        Colors.black.withValues(alpha: 0.16),
                      ],
                      stops: const [0, 0.58, 1],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 38 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isGuest ? 'DÉCOUVRIR SANS COMPTE' : 'CINEBOOK PRÉSENTE',
                          style: TextStyle(
                            color: eyebrowColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Text(
                        'SÉANCE 001',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? 42 : 30),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Text(
                      isGuest
                          ? 'Quel film regarder ce soir ?'
                          : 'TON CINÉMA.\nTES VIBES.',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        color: foreground,
                        fontSize: isDesktop ? 58 : 38,
                        fontWeight: FontWeight.w600,
                        height: 1.02,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 610),
                    child: Text(
                      isGuest
                          ? 'Recherche un film que tu aimes ou choisis une suggestion. CineBook te propose aussitôt des films proches de son atmosphère.'
                          : 'Un film suffit pour trouver la prochaine séance qui te ressemble. Mélange les ambiances, ajuste le rythme et fais place aux découvertes.',
                      style: TextStyle(
                        color: secondary,
                        fontSize: isDesktop ? 15 : 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                  if (isGuest) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Aucune inscription nécessaire. Un compte sert uniquement à sauvegarder ta Watchlist.',
                      style: TextStyle(
                        color: hasBackdrop
                            ? const Color(0xFFBDB8AE)
                            : _colors.textMuted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Container(
                    height: 1,
                    color: hasBackdrop
                        ? Colors.white.withValues(alpha: 0.24)
                        : _colors.border,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'AMBIANCE',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'RYTHME',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'DÉCOUVERTE',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (featured != null)
                        Text(
                          'À L’AFFICHE · ${featured.title.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: eyebrowColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
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

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeading(
          number: '01',
          eyebrow: 'TON POINT DE DÉPART',
          title: 'Choisis un film que tu aimes',
        ),
        const SizedBox(height: 10),
        Text(
          'Utilise la recherche en haut ou les suggestions ci-dessous. Tu peux combiner plusieurs films.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (_genres.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _selectedGenre ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Suggestions par genre'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tous les genres')),
              ..._genres.map(
                (genre) => DropdownMenuItem(value: genre, child: Text(genre)),
              ),
            ],
            onChanged: (genre) {
              setState(() => _selectedGenre = genre == '' ? null : genre);
              _loadQuickPicks();
            },
          ),
        if (_isLoadingQuickPicks)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          )
        else if (_browseError != null) ...[
          Text(
            _browseError!,
            style: TextStyle(color: _colors.ruby, fontSize: 12),
          ),
          TextButton.icon(
            onPressed: _loadQuickPicks,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réessayer les suggestions'),
          ),
        ] else if (_quickPicks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aucune suggestion pour ce genre. Essaie un autre genre ou la recherche en haut.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (!_isLoadingQuickPicks && _quickPicks.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'SÉLECTION RAPIDE',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickPicks.map((movie) {
              final isSelected = _selectedSeeds.any((seed) => seed.id == movie.id);
              return ActionChip(
                avatar: Icon(
                  isSelected ? Icons.check : Icons.add,
                  size: 13,
                  color: isSelected ? _colors.onAccent : _colors.textMuted,
                ),
                label: Text(movie.title),
                backgroundColor: isSelected
                    ? _colors.accent
                    : _colors.surfaceElevated,
                side: BorderSide(
                  color: isSelected ? _colors.accent : _colors.border,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? _colors.onAccent : _colors.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                onPressed: () => _toggleSeed(movie),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 18),
        if (_selectedSeeds.length == 1) ...[
          ReferenceCard(movie: _selectedSeeds.first, onClear: _clearSeeds),
          const SizedBox(height: 22),
        ] else if (_selectedSeeds.length > 1) ...[
          _buildBlendedSeedsCard(),
          const SizedBox(height: 22),
        ],
        _buildStepHeading(
          number: '02',
          eyebrow: 'TA SÉLECTION',
          title: 'Découvre les films proposés',
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: Text(
            _selectedSeeds.isEmpty
                ? 'Choisis un premier film pour commencer.'
                : _isLoading
                ? 'Recherche de films similaires…'
                : _settingsChanged
                ? 'Réglages modifiés : applique-les pour actualiser les résultats.'
                : _errorMessage != null
                ? 'La sélection n’a pas pu être chargée. Réessaie.'
                : '${_response?.recommendations.length ?? 0} films proposés · ${_selectedSeeds.length} film(s) de référence',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: _isLoading
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _colors.onAccent,
                    ),
                  )
                : Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: _selectedSeeds.isEmpty
                        ? _colors.textMuted
                        : _colors.onAccent,
                  ),
            label: Text(
              _isLoading
                  ? 'RECHERCHE EN COURS…'
                  : _selectedSeeds.isEmpty
                  ? 'CHOISIS UN FILM POUR COMMENCER'
                  : _settingsChanged
                  ? 'APPLIQUER LES RÉGLAGES'
                  : _errorMessage != null
                  ? 'RÉESSAYER'
                  : 'VOIR MA SÉLECTION',
            ),
            onPressed: _isLoading || _selectedSeeds.isEmpty
                ? null
                : () {
                    if (_settingsChanged ||
                        _errorMessage != null ||
                        _response == null) {
                      _fetchRecommendations(showResults: true);
                    } else {
                      _showResults();
                    }
                  },
          ),
        ),
        const SizedBox(height: 14),
        ExpansionTile(
          key: const PageStorageKey('recommendation-settings'),
          tilePadding: EdgeInsets.zero,
          title: Text(
            'Affiner ma sélection (facultatif)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Text(
            'Ambiance, couleurs, genres, époque, rythme',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Les réglages équilibrés suffisent pour commencer. Après une modification, clique sur « Appliquer les réglages ».',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            WeightSliders(
              weights: _weights,
              discoverySlider: _discoverySlider,
              topN: _topN,
              onWeightsChanged: (weights) => setState(() {
                _weights = weights;
                _settingsChanged = true;
              }),
              onDiscoveryChanged: (value) => setState(() {
                _discoverySlider = value;
                _settingsChanged = true;
              }),
              onTopNChanged: (value) => setState(() {
                _topN = value;
                _settingsChanged = true;
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectedSeeds.isEmpty || _isLoading
                  ? null
                  : () => _fetchRecommendations(showResults: true),
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Appliquer les réglages'),
            ),
          ],
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
          width: 34,
          height: 34,
          color: _colors.accent,
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: _colors.onAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: _colors.accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlendedSeedsCard() {
    final allGenres = <String>{};
    for (final movie in _selectedSeeds) {
      allGenres.addAll(movie.genres);
    }
    final avgPacing =
        _selectedSeeds.map((movie) => movie.pacing).reduce((a, b) => a + b) /
        _selectedSeeds.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _colors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, color: _colors.accent, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'MIX DE ${_selectedSeeds.length} FILMS',
                  style: TextStyle(
                    color: _colors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton(
                onPressed: _clearSeeds,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Tout effacer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ces films sont combinés pour trouver des points communs. Retire une référence pour ajuster le mix.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedSeeds
                .map(
                  (movie) => InputChip(
                    label: Text(movie.title, overflow: TextOverflow.ellipsis),
                    onDeleted: () => _toggleSeed(movie),
                    deleteButtonTooltipMessage: 'Retirer ${movie.title}',
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _selectedSeeds.map((movie) {
                return Padding(
                  padding: const EdgeInsets.only(right: 9),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: movie.posterUrl != null
                        ? Image.network(
                            movie.posterUrl!,
                            width: 54,
                            height: 80,
                            cacheWidth: (54 *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                            fit: BoxFit.cover,
                            semanticLabel: 'Affiche de ${movie.title}',
                            errorBuilder: (context, error, stackTrace) =>
                                _buildMixPlaceholder(),
                          )
                        : _buildMixPlaceholder(),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _colors.surfaceElevated,
                  border: Border.all(color: _colors.border),
                ),
                child: Text(
                  'Rythme moyen : ${(avgPacing * 100).toInt()}%',
                  style: TextStyle(
                    color: _colors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...allGenres.take(4).map(
                (genre) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _colors.surfaceElevated,
                    border: Border.all(color: _colors.border),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: _colors.textSecondary,
                      fontSize: 10,
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

  Widget _buildMixPlaceholder() {
    return Container(
      width: 54,
      height: 80,
      color: _colors.posterPlaceholder,
      child: Icon(Icons.movie, size: 19, color: _colors.textMuted),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      key: _resultsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStreamingFilterBar(),
        const SizedBox(height: 16),
        ..._buildResultsChildren(),
      ],
    );
  }

  List<Widget> _buildResultsChildren() {
    if (_errorMessage != null) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _colors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _colors.ruby.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: _colors.ruby, size: 32),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: _colors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _fetchRecommendations,
                icon: Icon(Icons.refresh, size: 16, color: _colors.accent),
                label: Text(
                  'Réessayer',
                  style: TextStyle(color: _colors.accent),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _colors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
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
          padding: const EdgeInsets.symmetric(vertical: 72),
          alignment: Alignment.center,
          child: Column(
            children: [
              CircularProgressIndicator(color: _colors.accent),
              const SizedBox(height: 20),
              Text(
                'La projection se prépare...',
                style: TextStyle(
                  color: _colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nous cherchons des films proches de ta sélection.',
                style: TextStyle(color: _colors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    if (_response == null || _response!.recommendations.isEmpty) {
      final isFiltered =
          _selectedProvider != 'Tous' && _selectedSeeds.isNotEmpty;
      final emptyTitle = isFiltered
          ? 'Aucun film trouvé sur $_selectedProvider pour cette sélection'
          : _selectedSeeds.isEmpty
          ? 'Tes découvertes apparaîtront ici'
          : 'Aucun résultat pour cette sélection';
      final emptyDescription = isFiltered
          ? 'Essayez de repasser sur « Tous » ou d’ajuster vos curseurs pour élargir la recherche.'
          : _selectedSeeds.isEmpty
          ? 'Recherche un titre en haut ou choisis une suggestion. Aucun compte nécessaire.'
          : 'Essaie un autre film ou ajuste les réglages.';
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 56),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                Icons.theaters_outlined,
                color: _colors.textMuted,
                size: 52,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  emptyTitle,
                  style: TextStyle(
                    color: _colors.textPrimary,
                    fontFamily: AppTheme.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  emptyDescription,
                  style: TextStyle(
                    color: _colors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  icon: Icon(Icons.refresh, size: 16, color: _colors.accent),
                  label: Text(
                    'Afficher toutes les plateformes',
                    style: TextStyle(color: _colors.accent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _colors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
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
          'Inspirées de : ${_selectedSeeds.map((s) => s.title).join(' + ')}';
    } else {
      final refTitle = _selectedSeeds.isNotEmpty
          ? _selectedSeeds.first.title
          : _response!.referenceMovie.title;
      title = 'Top ${recs.length} Recommandations pour "$refTitle"';
      subtitle =
          'Des films proches par leur ambiance, leur style et leur rythme. Le signet les sauvegarde dans ta Watchlist ; « Ajouter au mix » les utilise comme référence.';
    }

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TA SÉANCE SUR MESURE',
            style: TextStyle(
              color: _colors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: _colors.textPrimary,
              fontFamily: AppTheme.displayFont,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: _colors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      if (_selectedProvider != 'Tous') ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _colors.surface,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: _getProviderBorderColor(_selectedProvider),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChoiceChipAvatar(_selectedProvider, true) ??
                  const SizedBox.shrink(),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Filtre actif : $_selectedProvider',
                  style: TextStyle(
                    color: _colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() => _selectedProvider = 'Tous');
                  _fetchRecommendations();
                },
                borderRadius: BorderRadius.circular(2),
                child: Icon(
                  Icons.close,
                  size: 15,
                  color: _colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      ...List.generate(recs.length, (index) {
        final item = recs[index];
        final isSeed = _selectedSeeds.any((s) => s.id == item.id);
        return RecommendationCard(
          key: ValueKey('recommendation-${item.id}'),
          item: item,
          rank: index + 1,
          isWatchlisted: _authService.isMovieInWatchlist(item.id),
          onToggleWatchlist: () => _handleToggleWatchlist(item),
          isSelectedSeed: isSeed,
          onToggleSeed: () => _toggleSeed(item.toMovieBrief()),
        );
      }),
    ];
  }

  Widget _buildStreamingFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.live_tv_outlined, size: 15, color: _colors.accent),
              const SizedBox(width: 7),
              Text(
                'FILTRER PAR PLATEFORME',
                style: TextStyle(
                  color: _colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                    backgroundColor: _colors.background,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                      side: BorderSide(
                        color: isSelected
                            ? _getProviderBorderColor(provider)
                            : _colors.border,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? _colors.textPrimary
                          : _colors.textSecondary,
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
        color: isSelected ? _colors.gold : _colors.textMuted,
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
    if (provider == 'Tous') return _colors.accent.withValues(alpha: 0.12);
    final brandColor = _getProviderBorderColor(provider);
    if (Theme.of(context).brightness == Brightness.light) {
      return brandColor.withValues(alpha: 0.08);
    }
    if (provider == 'Netflix') return const Color(0xFF380606);
    if (provider == 'Amazon Prime Video') return const Color(0xFF042138);
    if (provider == 'Apple TV') return const Color(0xFF2C2C2E);
    return _colors.accent.withValues(alpha: 0.12);
  }

  Color _getProviderBorderColor(String provider) {
    if (provider == 'Netflix') return const Color(0xFFE50914);
    if (provider == 'Amazon Prime Video') return const Color(0xFF00A8E1);
    if (provider == 'Apple TV') return const Color(0xFFA2AAAD);
    return _colors.gold;
  }
}
