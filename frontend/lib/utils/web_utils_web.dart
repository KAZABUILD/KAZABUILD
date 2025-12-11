// Web implementation for web platform

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String getCurrentUrlImpl() => html.window.location.href;
String getUrlOriginImpl() => html.window.location.origin;
String getUrlHashImpl() => html.window.location.hash;
void setUrlHashImpl(String hash) { html.window.location.hash = hash; }
void setUrlHrefImpl(String href) { html.window.location.href = href; }
void replaceUrlStateImpl(String url) { html.window.history.replaceState(null, '', url); }
void reloadPageImpl() { html.window.location.reload(); }
