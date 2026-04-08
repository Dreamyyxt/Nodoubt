import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'amap_geocoder.dart';

Future<void>? _aMapLoaderFuture;

Future<GeocodedLocation?> geocodeWithAmapImpl({
  required String apiKey,
  required String cityLabel,
  required String locationText,
}) async {
  await _ensureAmapLoaded(apiKey);

  final requestId = 'nodoubt-geocode-${DateTime.now().microsecondsSinceEpoch}';
  final completer = Completer<GeocodedLocation?>();

  JSFunction? listener;
  listener = ((web.Event event) {
    final customEvent = event as web.CustomEvent;
    final detail = customEvent.detail?.dartify();
    if (detail is! Map) {
      return;
    }
    if (detail['requestId'] != requestId) {
      return;
    }
    web.window.removeEventListener('nodoubt-amap-geocode', listener);
    final success = detail['success'] == true;
    if (!success) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }
    if (!completer.isCompleted) {
      completer.complete(
        GeocodedLocation(
          longitude: (detail['longitude'] as num).toDouble(),
          latitude: (detail['latitude'] as num).toDouble(),
          formattedAddress: detail['formattedAddress']?.toString(),
        ),
      );
    }
  }).toJS;

  web.window.addEventListener('nodoubt-amap-geocode', listener);

  final script = web.HTMLScriptElement()
    ..type = 'text/javascript'
    ..text = _buildGeocodeScript(
      requestId: requestId,
      cityLabel: cityLabel,
      locationText: locationText,
    );
  web.document.body?.append(script);

  return completer.future.timeout(
    const Duration(seconds: 4),
    onTimeout: () {
      web.window.removeEventListener('nodoubt-amap-geocode', listener);
      return null;
    },
  );
}

Future<void> _ensureAmapLoaded(String apiKey) {
  if (_aMapLoaderFuture != null) {
    return _aMapLoaderFuture!;
  }

  final completer = Completer<void>();
  _aMapLoaderFuture = completer.future;

  final script = web.HTMLScriptElement()
    ..src = 'https://webapi.amap.com/maps?v=2.0&key=$apiKey&plugin=AMap.Geocoder'
    ..async = true
    ..defer = true;
  script.setAttribute('data-nodoubt-amap-geocoder', 'true');

  script.addEventListener(
    'load',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS,
  );
  script.addEventListener(
    'error',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Failed to load AMap geocoder'));
      }
    }).toJS,
  );

  web.document.head?.append(script);
  return _aMapLoaderFuture!;
}

String _buildGeocodeScript({
  required String requestId,
  required String cityLabel,
  required String locationText,
}) {
  final cityJson = jsonEncode(cityLabel);
  final locationJson = jsonEncode(locationText);
  return '''
(() => {
  const requestId = ${jsonEncode(requestId)};
  const city = $cityJson;
  const address = $locationJson;
  const emit = (detail) => window.dispatchEvent(new CustomEvent('nodoubt-amap-geocode', { detail }));
  if (typeof AMap === 'undefined') {
    emit({ requestId, success: false });
    return;
  }
  AMap.plugin(['AMap.Geocoder'], function () {
    const geocoder = new AMap.Geocoder({ city, citylimit: true });
    geocoder.getLocation(address, function(status, result) {
      if (status === 'complete' && result && Array.isArray(result.geocodes) && result.geocodes.length > 0) {
        const best = result.geocodes[0];
        const location = best.location;
        emit({
          requestId,
          success: true,
          longitude: location.lng,
          latitude: location.lat,
          formattedAddress: best.formattedAddress || address
        });
        return;
      }
      emit({ requestId, success: false });
    });
  });
})();
''';
}
