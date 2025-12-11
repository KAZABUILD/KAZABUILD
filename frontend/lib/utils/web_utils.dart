// Facade for web utilities
// Handles platform-specific imports conditionally

import 'web_utils_stub.dart'
    if (dart.library.html) 'web_utils_web.dart';

String getCurrentUrl() => getCurrentUrlImpl();
String getUrlOrigin() => getUrlOriginImpl();
String getUrlHash() => getUrlHashImpl();
void setUrlHash(String hash) => setUrlHashImpl(hash);
void setUrlHref(String href) => setUrlHrefImpl(href);
void replaceUrlState(String url) => replaceUrlStateImpl(url);
void reloadPage() => reloadPageImpl();
