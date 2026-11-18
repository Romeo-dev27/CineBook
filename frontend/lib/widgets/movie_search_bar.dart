import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MovieSearchBar extends StatefulWidget {
  final ApiService apiService;
  final ValueChanged<MovieBrief> onMovieSelected;
  final List<MovieBrief> selectedSeeds;

  const MovieSearchBar({
    super.key,
    required this.apiService,
    required this.onMovieSelected,
    required this.selectedSeeds,
  });

  @override
  State<MovieSearchBar> createState() => _MovieSearchBarState();
}

class _MovieSearchBarState extends State<MovieSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _overlay = OverlayPortalController();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  final _optionsScroll = ScrollController();
  List<MovieBrief> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  int _request = 0;
  int _highlighted = -1;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _overlay.hide();
    } else if (_controller.text.trim().isNotEmpty) {
      _search(_controller.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _optionsScroll.dispose();
    super.dispose();
  }

  void _search(String query) {
    _debounce?.cancel();
    final request = ++_request;
    final trimmed = query.trim();
    setState(() {
      _results = [];
      _error = null;
      _highlighted = -1;
      _isLoading = trimmed.isNotEmpty;
    });
    if (trimmed.isEmpty) {
      _overlay.hide();
      return;
    }
    _overlay.show();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await widget.apiService.getMovies(
          query: trimmed,
          limit: 10,
        );
        if (!mounted || request != _request) return;
        setState(() {
          _results = results;
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted || request != _request) return;
        setState(() {
          _error = 'Recherche indisponible. Réessaie dans un instant.';
          _isLoading = false;
        });
      }
    });
  }

  void _select(MovieBrief movie) {
    _controller.clear();
    _search('');
    _focusNode.unfocus();
    widget.onMovieSelected(movie);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _overlay.hide();
      _focusNode.unfocus();
      return KeyEventResult.handled;
    }
    if (!_overlay.isShowing || _results.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final delta = event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1;
      setState(
        () =>
            _highlighted = (_highlighted + delta).clamp(0, _results.length - 1),
      );
      if (_optionsScroll.hasClients) {
        _optionsScroll.jumpTo(
          (_highlighted * 80.0).clamp(
            0,
            _optionsScroll.position.maxScrollExtent,
          ),
        );
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _select(_results[_highlighted < 0 ? 0 : _highlighted]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OverlayPortal(
          controller: _overlay,
          overlayChildBuilder: (context) {
            final box =
                _fieldKey.currentContext!.findRenderObject() as RenderBox;
            final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
            final available =
                MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                bottom -
                8;
            return Positioned(
              width: constraints.maxWidth,
              child: CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomLeft,
                offset: const Offset(0, 6),
                showWhenUnlinked: false,
                child: TextFieldTapRegion(
                  child: Material(
                    color: AppTheme.surfaceElevated,
                    elevation: 12,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(0, math.min(320, available)),
                      ),
                      child: _buildOptions(),
                    ),
                  ),
                ),
              ),
            );
          },
          child: CompositedTransformTarget(
            link: _link,
            child: Focus(
              onKeyEvent: _onKey,
              child: TextField(
                key: _fieldKey,
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _search,
                onTapOutside: (_) => _focusNode.unfocus(),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  if (_results.isNotEmpty) {
                    _select(_results[_highlighted < 0 ? 0 : _highlighted]);
                  }
                },
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Rechercher un film',
                  hintText: 'Ex. Interstellar',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Effacer la recherche',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptions() {
    if (_isLoading || _error != null || _results.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading) const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  _isLoading
                      ? 'Recherche en cours…'
                      : _error ?? 'Aucun film trouvé. Essaie un autre titre.',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (_error != null)
                  TextButton(
                    onPressed: () => _search(_controller.text),
                    child: const Text('Réessayer la recherche'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _optionsScroll,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemExtent: 80,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final movie = _results[index];
        final selected = widget.selectedSeeds.any(
          (seed) => seed.id == movie.id,
        );
        return ListTile(
          selected: _highlighted == index,
          selectedTileColor: AppTheme.gold.withValues(alpha: 0.12),
          leading: SizedBox(
            width: 36,
            height: 52,
            child: movie.posterUrl == null
                ? const Icon(Icons.movie_outlined)
                : Image.network(
                    movie.posterUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: (36 * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                    errorBuilder: (_, _, _) => const Icon(Icons.movie_outlined),
                  ),
          ),
          title: Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${movie.year} · ${selected ? 'Déjà sélectionné' : 'Ajouter comme référence'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            selected ? Icons.check_circle : Icons.add_circle_outline,
            color: AppTheme.gold,
          ),
          onTap: () => _select(movie),
        );
      },
    );
  }
}
