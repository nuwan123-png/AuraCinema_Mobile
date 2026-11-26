class Movie {
  final int id;
  final String title;
  final String image;
  final String? year;
  final String type;
  final bool watchWithSub;
  final bool isIncomplete;
  final int episodesCount;
  final String? trailerEmbedUrl;
  final String? trailerUrl;
  final String? language;
  final String? genre;
  final String? tags;

  static const String r2BaseUrl =
      'https://pub-63df71478cdb4786a59eae41e51254b1.r2.dev';

  Movie({
    required this.id,
    required this.title,
    required this.image,
    this.year,
    required this.type,
    required this.watchWithSub,
    this.isIncomplete = false,
    this.episodesCount = 0,
    this.trailerEmbedUrl,
    this.trailerUrl,
    this.language,
    this.genre,
    this.tags,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    String? parseTags(dynamic raw) {
      if (raw == null) return null;
      if (raw is List) {
        return raw.map((e) => e.toString()).join(',');
      }
      return raw.toString();
    }

    bool parseBool(dynamic val) {
      return val == true ||
          val == 1 ||
          val?.toString().toLowerCase() == 'true' ||
          val?.toString() == '1';
    }

    int parseEpisodesCount(Map<String, dynamic> map) {
      if (map['episodes_count'] != null) {
        return int.tryParse(map['episodes_count'].toString()) ?? 0;
      }
      if (map['episodesCount'] != null) {
        return int.tryParse(map['episodesCount'].toString()) ?? 0;
      }
      if (map['episodes'] is List) {
        return (map['episodes'] as List).length;
      }
      return 0;
    }

    final epCount = parseEpisodesCount(json);
    final explicitIncomplete = json.containsKey('is_incomplete')
        ? parseBool(json['is_incomplete'])
        : (json.containsKey('isIncomplete')
            ? parseBool(json['isIncomplete'])
            : null);

    bool computedIncomplete = false;
    if (explicitIncomplete != null) {
      computedIncomplete = explicitIncomplete;
    } else if (json.containsKey('embed_url') ||
        json.containsKey('download_480p') ||
        json.containsKey('download_720p') ||
        json.containsKey('download_1080p')) {
      final hasEmbed =
          (json['embed_url']?.toString().trim() ?? '').isNotEmpty;
      final hasDl =
          (json['download_480p']?.toString().trim() ?? '').isNotEmpty ||
              (json['download_720p']?.toString().trim() ?? '').isNotEmpty ||
              (json['download_1080p']?.toString().trim() ?? '').isNotEmpty;
      if (epCount == 0 && (!hasEmbed || !hasDl)) {
        computedIncomplete = true;
      }
    }

    return Movie(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Unknown',
      image: json['image']?.toString() ?? '',
      year: json['year']?.toString(),
      type: json['type']?.toString() ?? 'movie',
      watchWithSub: parseBool(json['watch_with_sub']),
      isIncomplete: computedIncomplete,
      episodesCount: epCount,
      trailerEmbedUrl: (json['trailer_embed_url'] ?? json['trailerEmbedUrl'])
          ?.toString(),
      trailerUrl: (json['trailer_url'] ?? json['trailerUrl'])?.toString(),
      language: json['language']?.toString(),
      genre: json['genre']?.toString(),
      tags: parseTags(json['tags']),
    );
  }

  bool get hasTrailer =>
      (trailerEmbedUrl != null && trailerEmbedUrl!.trim().isNotEmpty) ||
      (trailerUrl != null && trailerUrl!.trim().isNotEmpty);

  String get fullImageUrl =>
      image.startsWith('http') ? image : '$r2BaseUrl/$image';

  String? get fullTrailerVideoUrl {
    final t = trailerUrl?.trim() ?? '';
    if (t.isEmpty) return null;
    return t.startsWith('http') ? t : '$r2BaseUrl/$t';
  }

  String? get playableTrailerYoutubeUrl {
    final raw = trailerEmbedUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    final embedMatch = RegExp(r'/embed/([a-zA-Z0-9_-]+)').firstMatch(raw);
    if (embedMatch != null) {
      return 'https://www.youtube.com/watch?v=${embedMatch.group(1)}';
    }
    return raw;
  }

  String get displayYear {
    if (year != null && year!.isNotEmpty && year != 'null') return year!;
    final match = RegExp(r'\((\d{4})\)').firstMatch(title);
    return match?.group(1) ?? '2026';
  }

  /// Web එකේ වගේ normalized keywords/tags list එක (#2026, #Tamil -> 2026, tamil)
  List<String> get keywordList {
    final raw = (tags ?? '').toLowerCase();
    final parts = raw
        .split(RegExp(r'[,\s#]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (language != null && language!.trim().isNotEmpty) {
      parts.add(language!.trim().toLowerCase());
    }
    if (genre != null && genre!.trim().isNotEmpty) {
      parts.add(genre!.trim().toLowerCase());
    }
    if (watchWithSub) {
      parts.addAll(['sinhala sub', 'sub']);
    }
    return parts.toSet().toList();
  }
}