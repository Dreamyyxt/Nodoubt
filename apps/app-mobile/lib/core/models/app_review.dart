class AppReview {
  const AppReview({
    required this.id,
    required this.score,
    this.content,
    this.isAnonymous = false,
    this.createdAt,
  });

  final String id;
  final int score;
  final String? content;
  final bool isAnonymous;
  final DateTime? createdAt;

  factory AppReview.fromJson(Map<String, dynamic> json) {
    return AppReview(
      id: json['id']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      content: json['content']?.toString(),
      isAnonymous: json['isAnonymous'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
