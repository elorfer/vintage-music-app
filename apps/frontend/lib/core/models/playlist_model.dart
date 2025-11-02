import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'playlist_model.g.dart';

enum PlaylistType {
  @JsonValue('user')
  user,
  @JsonValue('featured')
  featured,
  @JsonValue('genre')
  genre,
  @JsonValue('mood')
  mood,
}

enum PlaylistVisibility {
  @JsonValue('public')
  public,
  @JsonValue('private')
  private,
  @JsonValue('unlisted')
  unlisted,
}

@JsonSerializable(
  explicitToJson: true,
  includeIfNull: false,
)
class Playlist {
  final String id;
  final String? userId;
  final String? name;
  final String? description;
  final String? coverArtUrl;
  final PlaylistType? type;
  final PlaylistVisibility? visibility;
  final bool? isPublic;
  final int? totalTracks;
  final int? totalFollowers;
  final int? totalDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;

  const Playlist({
    required this.id,
    this.userId,
    this.name,
    this.description,
    this.coverArtUrl,
    this.type,
    this.visibility,
    this.isPublic,
    this.totalTracks,
    this.totalFollowers,
    this.totalDuration,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);
  Map<String, dynamic> toJson() => _$PlaylistToJson(this);

  String get durationFormatted {
    if (totalDuration == null) return '0m';
    final hours = totalDuration! ~/ 3600;
    final minutes = (totalDuration! % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

@JsonSerializable(
  fieldRename: FieldRename.snake,
  explicitToJson: true,
  includeIfNull: false,
)
class FeaturedPlaylist {
  final Playlist playlist;
  final String? featuredReason;
  final int rank;

  const FeaturedPlaylist({
    required this.playlist,
    this.featuredReason,
    required this.rank,
  });

  factory FeaturedPlaylist.fromJson(Map<String, dynamic> json) => _$FeaturedPlaylistFromJson(json);
  Map<String, dynamic> toJson() => _$FeaturedPlaylistToJson(this);
}
