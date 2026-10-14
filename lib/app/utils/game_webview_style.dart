// Style injecté dans les jeux (WebView) : l'appbar Flutter remplace l'en-tête
// web (bouton retour + titre), et le décalage haut (safe-area déjà géré par
// Flutter) est supprimé pour coller le jeu à l'appbar.
import 'package:webview_flutter/webview_flutter.dart';

const String kGameInAppCss =
    '.bar:has(#back) #back,.bar:has(#back)>h1{display:none!important}'
    '.bar:has(#back):not(:has(.ib:not(#back):not([hidden]))){display:none!important;min-height:0!important}'
    '.bar:has(#back){min-height:0!important;padding-right:0!important;justify-content:flex-end}'
    '.app{padding-top:0!important}'
    'html,body{margin:0!important}';

Future<void> injectGameInAppStyle(WebViewController c) async {
  try {
    await c.runJavaScript(
      "(function(){var d=document;var s=d.getElementById('__inapp_css');"
      "if(!s){s=d.createElement('style');s.id='__inapp_css';"
      "(d.head||d.documentElement).appendChild(s);}"
      "s.textContent='$kGameInAppCss';})();",
    );
  } catch (_) {}
}
