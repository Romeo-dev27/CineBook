/// Plateforme de streaming (TMDb Watch Provider)
class WatchProvider {
  final int id;
  final String name;
  final String? logoPath;

  const WatchProvider({
    required this.id,
    required this.name,
    this.logoPath,
  });

  String? get logoUrl =>
      logoPath != null && logoPath!.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w92$logoPath'
          : null;

  factory WatchProvider.fromJson(Map<String, dynamic> json) {
    return WatchProvider(
      id: (json['id'] as num?)?.toInt() ?? (json['provider_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? (json['provider_name'] as String? ?? ''),
      logoPath: json['logo_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo_path': logoPath,
      };
}

/// Modèles de données pour les films CineBook
class MovieBrief {
  final int id;
  final String title;
  final int year;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final double pacing;
  final List<String> genres;
  final List<String> atmosphereTags;
  final List<WatchProvider> streamingProviders;

  MovieBrief({
    required this.id,
    required this.title,
    required this.year,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.pacing,
    required this.genres,
    required this.atmosphereTags,
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

  factory MovieBrief.fromJson(Map<String, dynamic> json) {
    return MovieBrief(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Sans titre',
      year: json['year'] as int? ?? 0,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      pacing: (json['pacing'] as num?)?.toDouble() ?? 0.5,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      atmosphereTags: (json['atmosphere_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      streamingProviders: (json['streaming_providers'] as List<dynamic>?)
              ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ColorPalette {
  final double warmth;
  final double coolness;
  final double avgBrightness;
  final double avgSaturation;
  final double contrast;
  final double colorfulness;
  final double darknessRatio;
  final double vividnessRatio;
  final double tealRatio;
  final double orangeRatio;

  ColorPalette({
    required this.warmth,
    required this.coolness,
    required this.avgBrightness,
    required this.avgSaturation,
    required this.contrast,
    required this.colorfulness,
    required this.darknessRatio,
    required this.vividnessRatio,
    required this.tealRatio,
    required this.orangeRatio,
  });

  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    return ColorPalette(
      warmth: (json['warmth'] as num?)?.toDouble() ?? 0.0,
      coolness: (json['coolness'] as num?)?.toDouble() ?? 0.0,
      avgBrightness: (json['avg_brightness'] as num?)?.toDouble() ?? 0.0,
      avgSaturation: (json['avg_saturation'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 0.0,
      colorfulness: (json['colorfulness'] as num?)?.toDouble() ?? 0.0,
      darknessRatio: (json['darkness_ratio'] as num?)?.toDouble() ?? 0.0,
      vividnessRatio: (json['vividness_ratio'] as num?)?.toDouble() ?? 0.0,
      tealRatio: (json['teal_ratio'] as num?)?.toDouble() ?? 0.0,
      orangeRatio: (json['orange_ratio'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MovieDetail extends MovieBrief {
  final String? originalTitle;
  final String? overview;
  final double popularity;
  final ColorPalette? colorPalette;

  MovieDetail({
    required super.id,
    required super.title,
    required super.year,
    super.posterPath,
    super.backdropPath,
    required super.voteAverage,
    required super.voteCount,
    required super.pacing,
    required super.genres,
    required super.atmosphereTags,
    this.originalTitle,
    this.overview,
    required this.popularity,
    this.colorPalette,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Sans titre',
      year: json['year'] as int? ?? 0,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      pacing: (json['pacing'] as num?)?.toDouble() ?? 0.5,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      atmosphereTags: (json['atmosphere_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      colorPalette: json['color_palette'] != null
          ? ColorPalette.fromJson(json['color_palette'] as Map<String, dynamic>)
          : null,
    );
  }
}
