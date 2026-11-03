import 'movie.dart';

/// Poids de personnalisation de la similarité cosinus
class RecommendationWeights {
  final double atmosphere;
  final double visual;
  final double genre;
  final double era;
  final double pacing;

  const RecommendationWeights({
    this.atmosphere = 1.5,
    this.visual = 1.2,
    this.genre = 1.0,
    this.era = 0.5,
    this.pacing = 0.8,
  });

  RecommendationWeights copyWith({
    double? atmosphere,
    double? visual,
    double? genre,
    double? era,
    double? pacing,
  }) {
    return RecommendationWeights(
      atmosphere: atmosphere ?? this.atmosphere,
      visual: visual ?? this.visual,
      genre: genre ?? this.genre,
      era: era ?? this.era,
      pacing: pacing ?? this.pacing,
    );
  }

  Map<String, dynamic> toJson() => {
        'atmosphere': atmosphere,
        'visual': visual,
        'genre': genre,
        'era': era,
        'pacing': pacing,
      };

  // Presets prédéfinis pour faciliter la navigation
  static const RecommendationWeights equilibre = RecommendationWeights(
    atmosphere: 1.5,
    visual: 1.2,
    genre: 1.0,
    era: 0.5,
    pacing: 0.8,
  );

  static const RecommendationWeights ambiancePure = RecommendationWeights(
    atmosphere: 2.5,
    visual: 1.0,
    genre: 0.3,
    era: 0.2,
    pacing: 0.5,
  );

  static const RecommendationWeights esthetiqueVisuelle = RecommendationWeights(
    atmosphere: 1.0,
    visual: 2.8,
    genre: 0.4,
    era: 0.2,
    pacing: 0.4,
  );

  static const RecommendationWeights rythmeEtGenre = RecommendationWeights(
    atmosphere: 0.6,
    visual: 0.5,
    genre: 2.0,
    era: 0.5,
    pacing: 2.0,
  );
}

/// Un film recommandé avec son score mathématique et son explication
class RecommendationItem {
  final int id;
  final String title;
  final int year;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final List<String> genres;
  final List<String> atmosphereTags;
  final double pacing;
  final double score;
  final double baseSimilarity;
  final double discoveryFactor;
  final Map<String, double> subScores;
  final String explanation;
  final List<WatchProvider> streamingProviders;

  RecommendationItem({
    required this.id,
    required this.title,
    required this.year,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.genres,
    required this.atmosphereTags,
    required this.pacing,
    required this.score,
    required this.baseSimilarity,
    required this.discoveryFactor,
    required this.subScores,
    required this.explanation,
    this.streamingProviders = const [],
  });

  String? get posterUrl =>
      posterPath != null && posterPath!.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500$posterPath'
          : null;

  String? get backdropUrl =>
      backdropPath != null && backdropPath!.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
          : null;

  bool get isDiscoveryGem => discoveryFactor > 1.05;

  MovieBrief toMovieBrief() {
    return MovieBrief(
      id: id,
      title: title,
      year: year,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      voteCount: voteCount,
      pacing: pacing,
      genres: List.unmodifiable(genres),
      atmosphereTags: List.unmodifiable(atmosphereTags),
      streamingProviders: streamingProviders,
    );
  }

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    final rawSub = json['sub_scores'] as Map<String, dynamic>? ?? {};
    final subMap = <String, double>{};
    rawSub.forEach((k, v) {
      if (v is num) subMap[k] = v.toDouble();
    });

    return RecommendationItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Sans titre',
      year: json['year'] as int? ?? 0,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      atmosphereTags: (json['atmosphere_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pacing: (json['pacing'] as num?)?.toDouble() ?? 0.5,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      baseSimilarity: (json['base_similarity'] as num?)?.toDouble() ?? 0.0,
      discoveryFactor: (json['discovery_factor'] as num?)?.toDouble() ?? 1.0,
      subScores: subMap,
      explanation: json['explanation'] as String? ?? '',
      streamingProviders: (json['streaming_providers'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Réponse complète du endpoint /api/recommend
class RecommendResponse {
  final MovieBrief referenceMovie;
  final List<MovieBrief> referenceMovies;
  final List<RecommendationItem> recommendations;

  RecommendResponse({
    required this.referenceMovie,
    this.referenceMovies = const [],
    required this.recommendations,
  });

  factory RecommendResponse.fromJson(Map<String, dynamic> json) {
    final refList = (json['reference_movies'] as List<dynamic>?)
            ?.map((e) => MovieBrief.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    MovieBrief singleRef;
    if (json['reference_movie'] != null) {
      singleRef = MovieBrief.fromJson(json['reference_movie'] as Map<String, dynamic>);
    } else if (refList.isNotEmpty) {
      singleRef = refList.first;
    } else {
      throw Exception('Aucun film de référence dans la réponse de recommandation');
    }

    return RecommendResponse(
      referenceMovie: singleRef,
      referenceMovies: refList.isNotEmpty ? refList : [singleRef],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) =>
                  RecommendationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
