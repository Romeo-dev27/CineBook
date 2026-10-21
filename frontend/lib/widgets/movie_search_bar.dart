import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MovieSearchBar extends StatefulWidget {
  final ApiService apiService;
  final ValueChanged<MovieBrief>? onMovieSelected;
  final ValueChanged<List<MovieBrief>>? onSelectionChanged;
  final List<MovieBrief>? initialSelectedMovies;
  final List<MovieBrief>? selectedSeeds;
  final VoidCallback? onClearAllSeeds;
  final ValueChanged<MovieBrief>? onSeedRemoved;

  const MovieSearchBar({
    super.key,
    required this.apiService,
    this.onMovieSelected,
    this.onSelectionChanged,
    this.initialSelectedMovies,
    this.selectedSeeds,
    this.onClearAllSeeds,
    this.onSeedRemoved,
  });

  @override
  State<MovieSearchBar> createState() => _MovieSearchBarState();
}

class _MovieSearchBarState extends State<MovieSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MovieBrief> _searchResults = [];
  final List<MovieBrief> _selectedSeeds = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _showDropdown = false;

  List<MovieBrief> get _effectiveSeeds => widget.selectedSeeds ?? _selectedSeeds;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedMovies != null) {
      _selectedSeeds.addAll(widget.initialSelectedMovies!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _isLoading = true);
      try {
        final results = await widget.apiService.getMovies(query: trimmed, limit: 10);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
            _showDropdown = results.isNotEmpty;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _searchResults = [];
            _showDropdown = false;
          });
        }
      }
    });
  }

  void _selectMovie(MovieBrief movie) {
    // 1. Fermer le clavier et enlever le focus
    FocusScope.of(context).unfocus();
    _focusNode.unfocus();

    // 2. Vider la barre de recherche et masquer les suggestions
    _controller.clear();

    final updatedSeeds = List<MovieBrief>.from(_effectiveSeeds);
    if (!updatedSeeds.any((m) => m.id == movie.id)) {
      updatedSeeds.add(movie);
    }

    setState(() {
      _searchResults = [];
      _showDropdown = false;
      if (widget.selectedSeeds == null) {
        _selectedSeeds.clear();
        _selectedSeeds.addAll(updatedSeeds);
      }
    });

    // 4. Déclencher les callbacks
    widget.onMovieSelected?.call(movie);
    widget.onSelectionChanged?.call(List.unmodifiable(updatedSeeds));
  }

  void _removeSeed(MovieBrief movie) {
    final updatedSeeds = List<MovieBrief>.from(_effectiveSeeds);
    updatedSeeds.removeWhere((m) => m.id == movie.id);

    setState(() {
      if (widget.selectedSeeds == null) {
        _selectedSeeds.removeWhere((m) => m.id == movie.id);
      }
    });

    widget.onSeedRemoved?.call(movie);
    widget.onSelectionChanged?.call(List.unmodifiable(updatedSeeds));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Champ de recherche ───────────────────────────────────────────────
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Rechercher un film de référence (ex: Blade Runner, Interstellar)...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.gold,
                      ),
                    ),
                  )
                : (_controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null),
          ),
        ),

        // ── Liste déroulante des suggestions interactives ─────────────────────
        if (_showDropdown && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppTheme.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final movie = _searchResults[index];
                  final isAlreadySelected = _effectiveSeeds.any((m) => m.id == movie.id);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      hoverColor: AppTheme.gold.withValues(alpha: 0.10),
                      splashColor: AppTheme.gold.withValues(alpha: 0.20),
                      onTap: () => _selectMovie(movie),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            // Poster miniature
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: movie.posterUrl != null
                                  ? Image.network(
                                      movie.posterUrl!,
                                      width: 36,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            const SizedBox(width: 12),

                            // Titre, Année, Note, Genres
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isAlreadySelected
                                          ? AppTheme.gold
                                          : AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        '${movie.year}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star, color: AppTheme.gold, size: 13),
                                      const SizedBox(width: 3),
                                      Text(
                                        movie.voteAverage.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (movie.genres.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '• ${movie.genres.take(2).join(', ')}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Indicateur de sélection
                            if (isAlreadySelected)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.check_circle, color: AppTheme.gold, size: 18),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.add_circle_outline, color: AppTheme.textMuted, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // ── Puces (Pills) des films sélectionnés (Seeds) ─────────────────────
        if (_effectiveSeeds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.movie_filter_outlined, color: AppTheme.gold, size: 15),
              const SizedBox(width: 6),
              Text(
                'Films sélectionnés (${_effectiveSeeds.length}) :',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (_effectiveSeeds.length > 1)
                InkWell(
                  onTap: () {
                    if (widget.selectedSeeds == null) {
                      setState(() => _selectedSeeds.clear());
                    }
                    widget.onClearAllSeeds?.call();
                    widget.onSelectionChanged?.call(const []);
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _effectiveSeeds.map((movie) => _buildSeedPill(movie)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSeedPill(MovieBrief movie) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Affiche miniature arrondie
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: movie.posterUrl != null
                ? Image.network(
                    movie.posterUrl!,
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 26,
                      height: 26,
                      color: AppTheme.surface,
                      child: const Icon(Icons.movie, size: 14, color: AppTheme.gold),
                    ),
                  )
                : Container(
                    width: 26,
                    height: 26,
                    color: AppTheme.surface,
                    child: const Icon(Icons.movie, size: 14, color: AppTheme.gold),
                  ),
          ),
          const SizedBox(width: 8),

          // Titre et année
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${movie.year})',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),

          // Bouton supprimer la puce
          InkWell(
            onTap: () => _removeSeed(movie),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 15,
                color: AppTheme.textMuted.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 36,
      height: 52,
      color: AppTheme.surface,
      child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 20),
    );
  }
}
