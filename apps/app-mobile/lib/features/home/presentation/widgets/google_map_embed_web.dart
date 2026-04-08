import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredMapViewTypes = <String>{};

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
    final safeZoom = zoom.clamp(3, 14);
    final src =
        'https://www.google.com/maps?q=${Uri.encodeComponent(query)}'
        '&z=$safeZoom&output=embed';
    final viewType = 'google-map-embed-${src.hashCode}-${interactive ? 'interactive' : 'locked'}';

    if (_registeredMapViewTypes.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = src
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '24px'
          ..style.backgroundColor = '#F6F4FF'
          ..style.pointerEvents = interactive ? 'auto' : 'none';
        iframe.setAttribute('loading', 'lazy');
        iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
        return iframe;
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: HtmlElementView(viewType: viewType),
    );
  }
}
