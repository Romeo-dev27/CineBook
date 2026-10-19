import 'package:flutter/material.dart';
import 'models/movie.dart';
import 'models/recommendation.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'widgets/movie_search_bar.dart';
import 'widgets/reference_card.dart';
import 'widgets/weight_sliders.dart';
import 'widgets/recommendation_card.dart';

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
  final ApiService _apiService = ApiService();

  MovieBrief? _selectedMovie;
  RecommendationWeights _weights = RecommendationWeights.equilibre;
  double _discoverySlider = 0.3;
  int _topN = 5;

  bool _isLoading = false;
  RecommendResponse? _response;
  String? _errorMessage;

  // Films d'exemple populaires pour démarrer en un clic
  List<MovieBrief> _quickPicks = [];
  bool _isLoadingQuickPicks = true;

  @override
  void initState() {
    super.initState();
    _loadQuickPicks();
  }

  Future<void> _loadQuickPicks() async {
    try {
      final movies = await _apiService.getMovies(limit: 6);
      if (mounted) {
        setState(() {
          _quickPicks = movies;
          _isLoadingQuickPicks = false;
          // Pré-sélectionner le premier film pour une expérience immédiate
          if (movies.isNotEmpty && _selectedMovie == null) {
            _selectedMovie = movies.firstWhere(
              (m) => m.title.contains('Blade Runner 2049'),
              orElse: () => movies.first,
            );
          }
        });
        if (_selectedMovie != null) {
          _fetchRecommendations();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingQuickPicks = false);
      }
    }
  }

  Future<void> _fetchRecommendations() async {
    if (_selectedMovie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un film de référence.'),
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
        movieId: _selectedMovie!.id,
        topN: _topN,
        weights: _weights,
        discoverySlider: _discoverySlider,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie_creation_outlined, color: AppTheme.gold, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'CineBook',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text(
                'MVP FLUTTER',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: AppTheme.emerald, size: 14),
                SizedBox(width: 4),
                Text(
                  'FastAPI REST Live',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
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
        // Colonne de Gauche : Contrôles & Sélection (42% de l'écran)
        SizedBox(
          width: 420,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildControlsSection(),
          ),
        ),
        const VerticalDivider(color: AppTheme.border, width: 1),

        // Colonne de Droite : Recommandations (Reste de l'écran)
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildControlsSection(),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),
          _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. Choisis ton film de référence',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // Barre de recherche
        MovieSearchBar(
          apiService: _apiService,
          onMovieSelected: (movie) {
            setState(() => _selectedMovie = movie);
            _fetchRecommendations();
          },
        ),

        // Suggestions rapides
        if (!_isLoadingQuickPicks && _quickPicks.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPicks.map((m) {
                final isSelected = _selectedMovie?.id == m.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(m.title),
                    backgroundColor: isSelected
                        ? AppTheme.gold.withValues(alpha: 0.2)
                        : AppTheme.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppTheme.gold : AppTheme.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.gold : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onPressed: () {
                      setState(() => _selectedMovie = m);
                      _fetchRecommendations();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Carte du film de référence sélectionné
        if (_selectedMovie != null) ...[
          ReferenceCard(
            movie: _selectedMovie!,
            onClear: () {
              setState(() {
                _selectedMovie = null;
                _response = null;
              });
            },
          ),
          const SizedBox(height: 20),
        ],

        // 2. Pondérations des 5 vecteurs
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

        // Bouton d'action principal
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
              _isLoading ? 'CALCUL DU COSINUS EN COURS...' : 'GÉNÉRER LES RECOMMANDATIONS 🎬',
            ),
            onPressed: _isLoading ? null : _fetchRecommendations,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (_errorMessage != null) {
      return Container(
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
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Container(
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
      );
    }

    if (_response == null || _response!.recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.movie_filter_outlined, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Aucune recommandation générée pour l\'instant',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choisis un film de référence à gauche puis clique sur Générer.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final recs = _response!.recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.recommend, color: AppTheme.gold, size: 22),
            const SizedBox(width: 10),
            Text(
              'Top ${recs.length} Recommandations pour "${_response!.referenceMovie.title}"',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Classées par similarité mathématique multidimensionnelle (ambiance, visuel, rythme, genre, époque).',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),

        ...List.generate(recs.length, (index) {
          return RecommendationCard(
            item: recs[index],
            rank: index + 1,
          );
        }),
      ],
    );
  }
}
