class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.nickname,
    this.cityCode,
    this.bio,
    this.creditScore,
    this.level,
    this.ratingCount,
    this.ratingAvg,
    this.completedTaskCount,
    this.completedExchangeCount,
  });

  final String id;
  final String phone;
  final String nickname;
  final String? cityCode;
  final String? bio;
  final int? creditScore;
  final int? level;
  final int? ratingCount;
  final double? ratingAvg;
  final int? completedTaskCount;
  final int? completedExchangeCount;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      phone: (json['phone'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      cityCode: json['cityCode']?.toString(),
      bio: json['bio']?.toString(),
      creditScore: json['creditScore'] as int?,
      level: json['level'] as int?,
      ratingCount: json['ratingCount'] as int?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
      completedTaskCount: (json['completedTaskCount'] as num?)?.toInt(),
      completedExchangeCount: (json['completedExchangeCount'] as num?)?.toInt(),
    );
  }
}
