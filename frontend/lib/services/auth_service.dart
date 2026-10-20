import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  final String baseUrl;

  User? _currentUser;
  String? _token;
  List<WatchlistItem> _watchlist = [];
  final Set<int> _watchlistedMovieIds = {};

  AuthService({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  List<WatchlistItem> get watchlist => _watchlist;
  Set<int> get watchlistedMovieIds => _watchlistedMovieIds;

  bool isMovieInWatchlist(int movieId) => _watchlistedMovieIds.contains(movieId);

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Inscription d'un nouvel utilisateur
  Future<User> register(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      _token = data['access_token'] as String;
      _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
      await refreshWatchlist();
      notifyListeners();
      return _currentUser!;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Échec de l\'inscription');
    }
  }

  /// Connexion utilisateur
  Future<User> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      _token = data['access_token'] as String;
      _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
      await refreshWatchlist();
      notifyListeners();
      return _currentUser!;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Identifiants invalides');
    }
  }

  /// Déconnexion
  void logout() {
    _token = null;
    _currentUser = null;
    _watchlist.clear();
    _watchlistedMovieIds.clear();
    notifyListeners();
  }

  /// Rafraîchissement de la Watchlist depuis le backend
  Future<List<WatchlistItem>> refreshWatchlist() async {
    if (!isAuthenticated) return [];

    final uri = Uri.parse('$baseUrl/watchlist');
    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      _watchlist = data.map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>)).toList();
      _watchlistedMovieIds.clear();
      for (final item in _watchlist) {
        _watchlistedMovieIds.add(item.movieId);
      }
      notifyListeners();
      return _watchlist;
    } else {
      return [];
    }
  }

  /// Ajout d'un film à la Watchlist
  Future<WatchlistItem> addToWatchlist(
    int movieId, {
    String status = 'to_watch',
    String? notes,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Vous devez être connecté pour enregistrer un film.');
    }

    final uri = Uri.parse('$baseUrl/watchlist');
    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode({
        'movie_id': movieId,
        'status': status,
        'notes': ?notes,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final item = WatchlistItem.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      _watchlist.removeWhere((w) => w.movieId == movieId);
      _watchlist.insert(0, item);
      _watchlistedMovieIds.add(movieId);
      notifyListeners();
      return item;
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Impossible d\'ajouter à la watchlist');
    }
  }

  /// Suppression d'un film de la Watchlist
  Future<void> removeFromWatchlist(int movieId) async {
    if (!isAuthenticated) return;

    final uri = Uri.parse('$baseUrl/watchlist/$movieId');
    final response = await http.delete(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      _watchlist.removeWhere((w) => w.movieId == movieId);
      _watchlistedMovieIds.remove(movieId);
      notifyListeners();
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? 'Erreur lors de la suppression');
    }
  }
}
