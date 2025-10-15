import 'dart:ui' as ui;

typedef HtmlViewFactory = Object Function(int viewId);

void registerHtmlViewFactory(
  String viewType,
  HtmlViewFactory factory,
) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, factory);
}
