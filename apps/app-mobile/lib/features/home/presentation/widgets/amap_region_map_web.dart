import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'amap_region_map_data.dart';

final Set<String> _registeredAmapViewTypes = <String>{};
Future<void>? _amapLoaderFuture;

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
    final markerJson = markers.map((item) => item.toJson()).toList(growable: false);
    final activeCityLabel = selectedCityCode == null
        ? null
        : _cityLabel(selectedCityCode);
    final signature = jsonEncode({
      'selectedCityCode': selectedCityCode,
      'markers': markerJson,
    });
    final viewType = 'amap-region-map-${signature.hashCode}';

    if (_registeredAmapViewTypes.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (viewId) {
        final wrapper = web.HTMLDivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.overflow = 'hidden'
          ..style.borderRadius = '24px'
          ..style.background = 'linear-gradient(135deg, #eef6ff 0%, #f7f9ff 100%)';

        final mapId = 'amap-region-map-$viewId-${signature.hashCode}';
        final mapDiv = web.HTMLDivElement()
          ..id = mapId
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '24px'
          ..style.touchAction = 'none';
        wrapper.append(mapDiv);

        mapDiv.addEventListener(
          'wheel',
          ((web.Event event) {
            event.preventDefault();
            event.stopPropagation();
          }).toJS,
        );

        final tip = web.HTMLDivElement()
          ..style.position = 'absolute'
          ..style.left = '16px'
          ..style.top = '16px'
          ..style.padding = '10px 14px'
          ..style.borderRadius = '18px'
          ..style.background = 'rgba(255,255,255,0.92)'
          ..style.boxShadow = '0 10px 18px rgba(17, 28, 67, 0.08)'
          ..style.color = '#334155'
          ..style.fontSize = '12px'
          ..style.lineHeight = '1.4'
          ..textContent = selectedCityCode == null
              ? '先看城市热度，继续放大会自然散成区级和具体地址。'
              : '当前聚焦 ${activeCityLabel ?? selectedCityCode}，继续放大会看到更细的区域锚点。';
        wrapper.append(tip);

        final cityTapListener = ((web.Event event) {
          final customEvent = event as web.CustomEvent;
          final detail = customEvent.detail.dartify();
          if (detail is Map && detail['cityCode'] is String) {
            onCityTap(detail['cityCode'] as String);
          }
        }).toJS;
        web.document.addEventListener('citytap', cityTapListener);

        _ensureAmapLoaded(apiKey).then((_) {
          final configJson = jsonEncode({
            'selectedCityCode': selectedCityCode,
            'markers': markerJson,
          });
          final initScript = web.HTMLScriptElement()
            ..type = 'text/javascript'
            ..text = _buildInitScript(
              mapId: mapId,
              configJson: configJson,
            );
          wrapper.append(initScript);
        });

        return wrapper;
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: HtmlElementView(viewType: viewType),
    );
  }
}

Future<void> _ensureAmapLoaded(String apiKey) {
  if (_amapLoaderFuture != null) {
    return _amapLoaderFuture!;
  }

  final completer = Completer<void>();
  _amapLoaderFuture = completer.future;

  final script = web.HTMLScriptElement()
    ..src = 'https://webapi.amap.com/maps?v=2.0&key=$apiKey'
    ..async = true
    ..defer = true;
  script.setAttribute('data-nodoubt-amap', 'true');

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
        completer.completeError(StateError('Failed to load AMap JS API'));
      }
    }).toJS,
  );

  web.document.head?.append(script);
  return _amapLoaderFuture!;
}

String _buildInitScript({
  required String mapId,
  required String configJson,
}) {
  return '''
(() => {
  const container = document.getElementById("$mapId");
  if (!container || typeof AMap === 'undefined') {
    return;
  }

  container.innerHTML = '';
  const config = $configJson;
  const selectedCityCode = config.selectedCityCode;
  const center = [104.195397, 35.86166];
  const map = new AMap.Map(container, {
    viewMode: '2D',
    zoom: selectedCityCode ? 10.8 : 4.8,
    center: center,
    resizeEnable: true,
    dragEnable: true,
    zoomEnable: true,
    mapStyle: 'amap://styles/normal',
    features: ['bg', 'road', 'building', 'point'],
  });

  const cityNameMap = {
    shanghai: '上海',
    beijing: '北京',
    guangzhou: '广州',
    shenzhen: '深圳',
    hangzhou: '杭州',
    chengdu: '成都',
    wuhan: '武汉',
    nanjing: '南京',
    chongqing: '重庆',
    xiamen: '厦门',
  };

  const currentOverlays = [];
  const infoWindow = new AMap.InfoWindow({
    anchor: 'bottom-center',
    offset: new AMap.Pixel(0, -10),
    isCustom: false,
  });

  const clearOverlays = () => {
    if (currentOverlays.length) {
      map.remove(currentOverlays.splice(0, currentOverlays.length));
    }
  };

  const groupByCity = (markerData) => {
    const grouped = new Map();
    markerData.forEach((item) => {
      if (!grouped.has(item.cityCode)) {
        grouped.set(item.cityCode, []);
      }
      grouped.get(item.cityCode).push(item);
    });
    return [...grouped.entries()].map(([cityCode, items]) => {
      const totalCount = items.length;
      const taskCount = items.filter((item) => item.listingType === 'TASK').length;
      const exchangeCount = items.filter((item) => item.listingType === 'EXCHANGE').length;
      const longitude =
        items.reduce((sum, item) => sum + item.longitude, 0) / totalCount;
      const latitude =
        items.reduce((sum, item) => sum + item.latitude, 0) / totalCount;
      return {
        cityCode,
        label: cityNameMap[cityCode] || cityCode,
        totalCount,
        taskCount,
        exchangeCount,
        longitude,
        latitude,
      };
    });
  };

  const getDistrictLabel = (item) => {
    const text = item.locationText || '';
    const match = text.match(/市([^省市]{1,12}(?:区|县|市))/);
    return match ? match[1] : item.label;
  };

  const groupByDistrict = (markerData) => {
    const grouped = new Map();
    markerData.forEach((item) => {
      const district = getDistrictLabel(item);
      const key = `\${item.cityCode}::\${district}`;
      if (!grouped.has(key)) {
        grouped.set(key, []);
      }
      grouped.get(key).push(item);
    });
    return [...grouped.entries()].map(([key, items]) => {
      const [cityCode, districtLabel] = key.split('::');
      const totalCount = items.length;
      const longitude =
        items.reduce((sum, item) => sum + item.longitude, 0) / totalCount;
      const latitude =
        items.reduce((sum, item) => sum + item.latitude, 0) / totalCount;
      return {
        cityCode,
        districtLabel,
        totalCount,
        longitude,
        latitude,
      };
    });
  };

  const svgToDataUri = (svg) =>
    'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg);

  const buildPinIcon = (color) =>
    new AMap.Icon({
      image: svgToDataUri(`
        <svg xmlns="http://www.w3.org/2000/svg" width="30" height="40" viewBox="0 0 30 40">
          <defs>
            <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
              <feDropShadow dx="0" dy="3" stdDeviation="3" flood-color="rgba(15,23,42,0.18)"/>
            </filter>
          </defs>
          <g filter="url(#shadow)">
            <path d="M15 1C7.268 1 1 7.268 1 15c0 10.728 14 23 14 23s14-12.272 14-23C29 7.268 22.732 1 15 1z" fill="\${color}"/>
            <circle cx="15" cy="15" r="6.5" fill="white"/>
            <circle cx="15" cy="15" r="3" fill="\${color}" opacity="0.88"/>
          </g>
        </svg>
      `),
      size: new AMap.Size(30, 40),
      imageSize: new AMap.Size(30, 40),
    });

  const buildBubbleContent = (title, count, palette) => `
    <div style="
      display:flex;
      align-items:center;
      gap:8px;
      padding:7px 10px 7px 8px;
      border-radius:999px;
      background:\${palette.background};
      border:1px solid \${palette.border};
      box-shadow:0 12px 30px rgba(15,23,42,0.12);
      color:\${palette.text};
      font-family:-apple-system,BlinkMacSystemFont,'PingFang SC',sans-serif;
      transform: translateY(-2px);
      white-space:nowrap;
    ">
      <span style="
        width:10px;
        height:10px;
        border-radius:999px;
        background:\${palette.dot};
        box-shadow:0 0 0 3px \${palette.dotRing};
        flex:0 0 auto;
      "></span>
      <span style="font-size:12px;font-weight:700;letter-spacing:0.1px;">\${title}</span>
      <span style="
        min-width:22px;
        height:22px;
        padding:0 7px;
        border-radius:999px;
        background:\${palette.badge};
        color:\${palette.badgeText};
        display:flex;
        align-items:center;
        justify-content:center;
        font-size:11px;
        font-weight:800;
      ">\${count}</span>
    </div>
  `;

  const renderOverlays = (markerData) => {
    clearOverlays();
    infoWindow.close();
    const zoom = map.getZoom();
    const useListingMarkers = zoom >= 12.2;
    const useDistrictMarkers = !useListingMarkers && zoom >= 8.8;
    const overlays = [];

    if (useListingMarkers) {
      markerData.forEach((item) => {
        const color = item.listingType === 'TASK' ? '#ef4444' : '#0f766e';
        const marker = new AMap.Marker({
          position: [item.longitude, item.latitude],
          anchor: 'bottom-center',
          offset: new AMap.Pixel(0, 0),
          icon: buildPinIcon(color),
          title: `\${item.label}`,
        });
        marker.on('click', () => {
          infoWindow.setContent(`
            <div style="padding:6px 4px; min-width:180px; font-family:-apple-system,BlinkMacSystemFont,'PingFang SC',sans-serif;">
              <div style="font-size:13px; font-weight:700; color:#111827; margin-bottom:6px;">\${item.label}</div>
              <div style="font-size:12px; color:#475569; line-height:1.5;">\${item.locationText}</div>
            </div>
          `);
          infoWindow.open(map, [item.longitude, item.latitude]);
        });
        overlays.push(marker);
      });
    } else if (useDistrictMarkers) {
      groupByDistrict(markerData).forEach((item) => {
        const marker = new AMap.Marker({
          position: [item.longitude, item.latitude],
          anchor: 'bottom-center',
          offset: new AMap.Pixel(0, 0),
          content: buildBubbleContent(item.districtLabel, item.totalCount, {
            background: 'rgba(255,255,255,0.96)',
            border: 'rgba(148,163,184,0.22)',
            text: '#0f172a',
            dot: '#22c55e',
            dotRing: 'rgba(34,197,94,0.16)',
            badge: '#ecfccb',
            badgeText: '#365314',
          }),
        });
        marker.on('click', () => {
          map.setZoomAndCenter(12.6, [item.longitude, item.latitude], true);
        });
        overlays.push(marker);
      });
    } else {
      groupByCity(markerData).forEach((item) => {
        const marker = new AMap.Marker({
          position: [item.longitude, item.latitude],
          anchor: 'bottom-center',
          offset: new AMap.Pixel(0, 0),
          content: buildBubbleContent(item.label, item.totalCount, {
            background: 'rgba(17,24,39,0.94)',
            border: 'rgba(255,255,255,0.12)',
            text: '#ffffff',
            dot: '#a78bfa',
            dotRing: 'rgba(167,139,250,0.18)',
            badge: '#ffffff',
            badgeText: '#4c1d95',
          }),
        });
        marker.on('click', () => {
          document.dispatchEvent(
            new CustomEvent('citytap', {
              detail: { cityCode: item.cityCode },
            }),
          );
        });
        overlays.push(marker);
      });
    }

    if (overlays.length) {
      currentOverlays.push(...overlays);
      map.add(overlays);
    }
  };

  Promise.resolve(config.markers).then((markerData) => {
    const selected = groupByCity(markerData).find((item) => item.cityCode === selectedCityCode);
    if (selected) {
      map.setZoomAndCenter(10.8, [selected.longitude, selected.latitude], true);
    }

    const syncOverlays = () => renderOverlays(markerData);

    syncOverlays();
    map.on('complete', syncOverlays);
    map.on('zoomend', syncOverlays);
    map.on('moveend', syncOverlays);
    setTimeout(syncOverlays, 220);
  });
})();
''';
}

String? _cityLabel(String? cityCode) {
  switch (cityCode) {
    case 'shanghai':
      return '上海';
    case 'beijing':
      return '北京';
    case 'guangzhou':
      return '广州';
    case 'shenzhen':
      return '深圳';
    case 'hangzhou':
      return '杭州';
    case 'chengdu':
      return '成都';
    case 'wuhan':
      return '武汉';
    case 'nanjing':
      return '南京';
    case 'chongqing':
      return '重庆';
    case 'xiamen':
      return '厦门';
    default:
      return cityCode;
  }
}
