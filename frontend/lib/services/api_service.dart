import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/recommendation.dart';

class ApiService {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  final String baseUrl;

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  /// Recherche ou liste des films avec filtres
  Future<List<MovieBrief>> getMovies({
    String? query,
    String? genre,
    String? tag,
    String? provider,
    int limit = 30,
    int skip = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'skip': skip.toString(),
    };
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (genre != null && genre.isNotEmpty) {
      queryParams['genre'] = genre;
    }
    if (tag != null && tag.isNotEmpty) {
      queryParams['tag'] = tag;
    }
    if (provider != null && provider.isNotEmpty && provider != 'Tous') {
      queryParams['provider'] = provider;
    }

    final uri = Uri.parse('$baseUrl/movies').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => MovieBrief.fromJson(json)).toList();
      } else {
        throw Exception('Erreur API (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Impossible de charger les films : $e');
    }
  }

  /// Détails complets d'un film avec sa palette
  Future<MovieDetail> getMovieDetail(int id) async {
    final uri = Uri.parse('$baseUrl/movies/$id');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return MovieDetail.fromJson(data);
      } else {
        throw Exception('Film introuvable ($id)');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des détails : $e');
    }
  }

  /// Liste des genres cinématographiques
  Future<List<String>> getGenres() async {
    final uri = Uri.parse('$baseUrl/genres');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e['name'].toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Liste des tags d'atmosphère
  Future<List<String>> getTags() async {
    final uri = Uri.parse('$baseUrl/tags');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => e['name'].toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Appel au moteur de recommandation (supporte un film unique ou une liste multi-seeds)
  Future<RecommendResponse> getRecommendations({
    int? movieId,
    List<int>? movieIds,
    int topN = 5,
    required RecommendationWeights weights,
    double discoverySlider = 0.3,
    String? provider,
  }) async {
    final uri = Uri.parse('$baseUrl/recommend');
    
    // Résolution de la liste des IDs sélectionnés
    final resolvedIds = <int>[];
    if (movieIds != null && movieIds.isNotEmpty) {
      resolvedIds.addAll(movieIds);
    } else if (movieId != null) {
      resolvedIds.add(movieId);
    }

    if (resolvedIds.isEmpty) {
      throw Exception('Au moins un film de référence doit être spécifié.');
    }

    final payloadMap = <String, dynamic>{
      'movie_ids': resolvedIds,
      'movie_id': resolvedIds.first,
      'top_n': topN,
      'weights': weights.toJson(),
      'discovery_slider': discoverySlider,
    };
    if (provider != null && provider.isNotEmpty && provider != 'Tous') {
      payloadMap['provider'] = provider;
    }

    final body = jsonEncode(payloadMap);

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return RecommendResponse.fromJson(data);
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['detail'] ?? 'Erreur lors du calcul');
      }
    } catch (e) {
      throw Exception('Erreur moteur de recommandation : $e');
    }
  }
}
