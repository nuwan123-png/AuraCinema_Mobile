class Movie {
  final int id;
  final String title;
  final String image;
  final String? year;
  final String type;
  final bool watchWithSub;
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

    return Movie(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Unknown',
      image: json['image']?.toString() ?? '',
      year: json['year']?.toString(),
      type: json['type']?.toString() ?? 'movie',
      watchWithSub: json['watch_with_sub'] == true ||
          json['watch_with_sub'] == 1 ||
          json['watch_with_sub']?.toString() == 'true',
      language: json['language']?.toString(),
      genre: json['genre']?.toString(),
      tags: parseTags(json['tags']),
    );
  }

  String get fullImageUrl =>
      image.startsWith('http') ? image : '$r2BaseUrl/$image';

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