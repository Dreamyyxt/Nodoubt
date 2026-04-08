import 'amap_geocoder_stub.dart'
    if (dart.library.js_interop) 'amap_geocoder_web.dart' as impl;

class GeocodedLocation {
  const GeocodedLocation({
    required this.longitude,
    required this.latitude,
    this.formattedAddress,
  });

  final double longitude;
  final double latitude;
  final String? formattedAddress;
}

Future<GeocodedLocation?> geocodeWithAmap({
  required String apiKey,
  required String cityLabel,
  required String locationText,
}) {
  return impl.geocodeWithAmapImpl(
    apiKey: apiKey,
    cityLabel: cityLabel,
    locationText: locationText,
  );
}
