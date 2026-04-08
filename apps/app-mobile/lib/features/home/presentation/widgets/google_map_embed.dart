import 'package:flutter/widgets.dart';

import 'google_map_embed_stub.dart'
    if (dart.library.js_interop) 'google_map_embed_web.dart' as impl;

class GoogleMapEmbed extends StatelessWidget {
  const GoogleMapEmbed({
    super.key,
    required this.query,
    this.zoom = 4,
    this.interactive = true,
  });

  final String query;
  final int zoom;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return impl.GoogleMapEmbedImpl(
      query: query,
      zoom: zoom,
      interactive: interactive,
    );
  }
}
