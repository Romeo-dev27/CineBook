import 'movie.dart';

/// Utilisateur authentifié CineBook
class User {
  final int id;
  final String email;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

/// Élément de la Watchlist d'un utilisateur
class WatchlistItem {
  final int id;
  final int movieId;
  final String status; // "to_watch", "watched", "favorite"
  final String? notes;
  final DateTime? createdAt;
  final MovieBrief movie;

  WatchlistItem({
    required this.id,
    required this.movieId,
    required this.status,
    this.notes,
    this.createdAt,
    required this.movie,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as int,
      movieId: json['movie_id'] as int,
      status: json['status'] as String? ?? 'to_watch',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      movie: MovieBrief.fromJson(json['movie'] as Map<String, dynamic>),
    );
  }
}
