class MovieDetail {
  final int id;
  final String title;
  final String? description;
  final String image;
  final String? year;
  final String type;
  final String? genre;
  final String? language;
  final bool watchWithSub;
  final String? streamUrl;
  final String? embedUrl;
  final String? trailerUrl;
  final String? trailerEmbedUrl;
  final String? subtitleUrl;
  final Map<String, String?> downloads;
  final List<String> gallery;
  final List<EpisodeItem> episodes;

  static const String r2BaseUrl =
      'https://pub-63df71478cdb4786a59eae41e51254b1.r2.dev';

  MovieDetail({
    required this.id,
    required this.title,
    this.description,
    required this.image,
    this.year,
    required this.type,
    this.genre,
    this.language,
    required this.watchWithSub,
    this.streamUrl,
    this.embedUrl,
    this.trailerUrl,
    this.trailerEmbedUrl,
    this.subtitleUrl,
    required this.downloads,
    required this.gallery,
    required this.episodes,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    final rawDownloads = (json['downloads'] as Map<String, dynamic>?) ?? {};
    final downloadsMap = <String, String?>{
      '480p': rawDownloads['480p']?.toString(),
      '720p': rawDownloads['720p']?.toString(),
      '1080p': rawDownloads['1080p']?.toString(),
      'Telegram': rawDownloads['telegram']?.toString(),
    };

    final rawGallery = (json['gallery'] as List<dynamic>?) ?? [];
    final rawEpisodes = (json['episodes'] as List<dynamic>?) ?? [];

    return MovieDetail(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? 'Unknown',
      description: json['description']?.toString(),
      image: json['image']?.toString() ?? '',
      year: json['year']?.toString(),
      type: json['type']?.toString() ?? 'movie',
      genre: json['genre']?.toString(),
      language: json['language']?.toString(),
      watchWithSub: json['watch_with_sub'] == true,
      streamUrl: _cleanUrl(json['stream_url']),
      embedUrl: _cleanUrl(json['embed_url']),
      trailerUrl: _cleanUrl(json['trailer_url']),
      trailerEmbedUrl: _cleanUrl(json['trailer_embed_url']),
      subtitleUrl: _cleanUrl(json['subtitle_url']),
      downloads: downloadsMap,
      gallery: rawGallery
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      episodes: rawEpisodes
          .whereType<Map<String, dynamic>>()
          .map((e) => EpisodeItem.fromJson(e))
          .toList(),
    );
  }

  static String? _cleanUrl(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }

  String get fullImageUrl =>
      image.startsWith('http') ? image : '$r2BaseUrl/$image';

  String? get fullTrailerUrl {
    if (trailerUrl == null) return null;
    if (trailerUrl!.startsWith('http')) return trailerUrl;
    return '$r2BaseUrl/$trailerUrl';
  }

  String? get effectiveTrailerUrl => trailerEmbedUrl ?? fullTrailerUrl;

  List<String> get fullGalleryUrls => gallery
      .map((path) => path.startsWith('http') ? path : '$r2BaseUrl/$path')
      .toList();

  String? get watchUrl => embedUrl ?? streamUrl;

  String get displayYear {
    if (year != null && year!.isNotEmpty) return year!;
    final match = RegExp(r'\((\d{4})\)').firstMatch(title);
    return match?.group(1) ?? '2026';
  }

  String? get fullSubtitleUrl {
    if (subtitleUrl == null || subtitleUrl!.isEmpty) return null;
    if (subtitleUrl!.startsWith('http')) return subtitleUrl;
    return '$r2BaseUrl/$subtitleUrl';
  }
}



class EpisodeItem {
  final int id;
  final int number;
  final String url;
  final String? subtitleUrl;
  final String? downloadUrl;
  final String? telegramUrl;

  EpisodeItem({
    required this.id,
    required this.number,
    required this.url,
    this.subtitleUrl,
    this.downloadUrl,
    this.telegramUrl,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      id: json['id'] ?? 0,
      number: json['number'] ?? 1,
      url: json['url']?.toString() ?? '',
      subtitleUrl: json['subtitle_url']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      telegramUrl: json['telegram_url']?.toString(),
    );
  }
}