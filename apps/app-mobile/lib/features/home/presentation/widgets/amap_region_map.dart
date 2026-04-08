import 'package:flutter/widgets.dart';

import 'amap_region_map_data.dart';
import 'amap_region_map_stub.dart'
    if (dart.library.js_interop) 'amap_region_map_web.dart' as impl;

class AmapRegionMap extends StatelessWidget {
  const AmapRegionMap({
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
    return impl.AmapRegionMapImpl(
      apiKey: apiKey,
      markers: markers,
      selectedCityCode: selectedCityCode,
      onCityTap: onCityTap,
    );
  }
}
