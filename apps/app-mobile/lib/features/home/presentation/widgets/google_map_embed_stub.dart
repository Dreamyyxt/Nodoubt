import 'package:flutter/material.dart';

class GoogleMapEmbedImpl extends StatelessWidget {
  const GoogleMapEmbedImpl({
    super.key,
    required this.query,
    required this.zoom,
    required this.interactive,
  });

  final String query;
  final int zoom;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF2FF), Color(0xFFF8F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Google Maps 预览在 Web 端显示。\n当前聚焦：$query\n模式：${interactive ? '浏览地图' : '点选城市'}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
