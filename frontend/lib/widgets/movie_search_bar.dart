import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MovieSearchBar extends StatefulWidget {
  final ApiService apiService;
  final ValueChanged<MovieBrief> onMovieSelected;

  const MovieSearchBar({
    super.key,
    required this.apiService,
    required this.onMovieSelected,
  });

  @override
  State<MovieSearchBar> createState() => _MovieSearchBarState();
}

class _MovieSearchBarState extends State<MovieSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MovieBrief> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showDropdown = _focusNode.hasFocus && _searchResults.isNotEmpty;
      });
    });
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
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _isLoading = true);
      try {
        final results = await widget.apiService.getMovies(query: query, limit: 12);
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
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Rechercher un film de référence (ex: Blade Runner, Interstellar, Amélie)...',
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
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppTheme.border,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final movie = _searchResults[index];
                return ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: movie.posterUrl != null
                        ? Image.network(
                            movie.posterUrl!,
                            width: 32,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  title: Text(
                    movie.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${movie.year} • ⭐ ${movie.voteAverage.toStringAsFixed(1)} • ${movie.genres.take(2).join(', ')}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    widget.onMovieSelected(movie);
                    setState(() {
                      _showDropdown = false;
                      _controller.text = movie.title;
                    });
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 32,
      height: 48,
      color: AppTheme.surface,
      child: const Icon(Icons.movie, color: AppTheme.textMuted, size: 18),
    );
  }
}
