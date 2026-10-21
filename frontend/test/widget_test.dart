import 'package:flutter_test/flutter_test.dart';
import 'package:cinebook_frontend/models/movie.dart';
import 'package:cinebook_frontend/models/recommendation.dart';

void main() {
  group('Models & Calculations Tests', () {
    test('MovieBrief.fromJson parses TMDb fields correctly', () {
      final json = {
        'id': 335984,
        'title': 'Blade Runner 2049',
        'year': 2017,
        'poster_path': '/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg',
        'backdrop_path': '/sAtoMqDVhNDQBc3QJL3RF6hlxGq.jpg',
        'vote_average': 7.6,
        'vote_count': 13000,
        'pacing': 0.65,
        'genres': ['Science Fiction', 'Drama'],
        'atmosphere_tags': ['cyberpunk', 'melancholic', 'cold'],
      };

      final movie = MovieBrief.fromJson(json);

      expect(movie.id, 335984);
      expect(movie.title, 'Blade Runner 2049');
      expect(movie.year, 2017);
      expect(movie.voteAverage, 7.6);
      expect(movie.genres.length, 2);
      expect(movie.atmosphereTags.length, 3);
      expect(movie.posterUrl, contains('https://image.tmdb.org/t/p/w500/'));
    });

    test('RecommendationWeights presets have expected values', () {
      const eq = RecommendationWeights.equilibre;
      expect(eq.atmosphere, 1.5);
      expect(eq.visual, 1.2);
      expect(eq.genre, 1.0);

      const atmo = RecommendationWeights.ambiancePure;
      expect(atmo.atmosphere, 2.5);

      final json = eq.toJson();
      expect(json['atmosphere'], 1.5);
      expect(json['visual'], 1.2);
    });

    test('RecommendationItem.fromJson parses scores and explanation', () {
      final json = {
        'id': 603,
        'title': 'The Matrix',
        'year': 1999,
        'poster_path': '/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg',
        'vote_average': 8.2,
        'vote_count': 24000,
        'genres': ['Action', 'Science Fiction'],
        'atmosphere_tags': ['dark', 'kinetic'],
        'pacing': 0.75,
        'score': 0.885,
        'base_similarity': 0.87,
        'discovery_factor': 1.02,
        'sub_scores': {
          'Ambiance': 0.90,
          'Esthétique Visuelle': 0.85,
        },
        'explanation': 'Ambiance très proche (90%) • Tags partagés : dark',
      };

      final item = RecommendationItem.fromJson(json);

      expect(item.id, 603);
      expect(item.score, 0.885);
      expect(item.subScores['Ambiance'], 0.90);
      expect(item.explanation, contains('Ambiance très proche'));

      // Test conversion vers MovieBrief pour "Add to list"
      final brief = item.toMovieBrief();
      expect(brief.id, 603);
      expect(brief.title, 'The Matrix');
      expect(brief.genres, ['Action', 'Science Fiction']);
      expect(brief.atmosphereTags, ['dark', 'kinetic']);
    });

    test('RecommendResponse.fromJson parses multi-seeds reference_movies', () {
      final json = {
        'reference_movie': {
          'id': 335984,
          'title': 'Blade Runner 2049',
          'year': 2017,
          'vote_average': 7.6,
          'vote_count': 13000,
          'pacing': 0.65,
          'genres': ['Science Fiction'],
          'atmosphere_tags': ['cyberpunk'],
        },
        'reference_movies': [
          {
            'id': 335984,
            'title': 'Blade Runner 2049',
            'year': 2017,
            'vote_average': 7.6,
            'vote_count': 13000,
            'pacing': 0.65,
            'genres': ['Science Fiction'],
            'atmosphere_tags': ['cyberpunk'],
          },
          {
            'id': 603,
            'title': 'The Matrix',
            'year': 1999,
            'vote_average': 8.2,
            'vote_count': 24000,
            'pacing': 0.75,
            'genres': ['Action', 'Science Fiction'],
            'atmosphere_tags': ['cyberpunk', 'dark'],
          }
        ],
        'recommendations': [
          {
            'id': 76341,
            'title': 'Mad Max: Fury Road',
            'year': 2015,
            'vote_average': 7.6,
            'vote_count': 21000,
            'genres': ['Action', 'Adventure'],
            'atmosphere_tags': ['kinetic', 'dystopian'],
            'pacing': 0.95,
            'score': 0.81,
            'base_similarity': 0.80,
            'discovery_factor': 1.0,
            'sub_scores': {'Rythme': 0.85},
            'explanation': 'Vibe mixte (2 films) • Rythme très proche (85%)',
          }
        ],
      };

      final response = RecommendResponse.fromJson(json);
      expect(response.referenceMovies.length, 2);
      expect(response.referenceMovie.id, 335984);
      expect(response.referenceMovies[1].id, 603);
      expect(response.recommendations.length, 1);
      expect(response.recommendations.first.title, 'Mad Max: Fury Road');
    });
  });
}
