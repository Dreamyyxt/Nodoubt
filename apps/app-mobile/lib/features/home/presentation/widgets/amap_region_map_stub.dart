import 'package:flutter/material.dart';

import 'amap_region_map_data.dart';

class AmapRegionMapImpl extends StatelessWidget {
  const AmapRegionMapImpl({
    super.key,
    required this.apiKey,
    required this.markers,
    required this.selectedCityCode,
    required this.onCityTap,
  });

  final String apiKey;
  final List<AmapRegionMarkerData> markers;
  final String? selectedCityCode;
  final ValueChanged<String> onCityTap;

  @override
  Widget build(BuildContext context) {
    final active = selectedCityCode == null
        ? '全部城市'
        : markers
              .where((item) => item.cityCode == selectedCityCode)
              .map((item) => item.label)
              .firstOrNull ??
            selectedCityCode!;

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
            '高德地图在 Web 端显示。\n当前聚焦：$active\n已接入 ${markers.length} 个城市锚点。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
