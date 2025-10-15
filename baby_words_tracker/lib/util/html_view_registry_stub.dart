typedef HtmlViewFactory = Object Function(int viewId);

void registerHtmlViewFactory(
  String viewType,
  HtmlViewFactory factory,
) {}
