/// Einstieg der Website auf dem Server.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
// Von Jaspr erzeugt, nicht von Hand ändern.
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      lang: 'de',
      title: 'Karriko',
      // Kein Google Fonts und kein <style> im Kopf: Schrift und Styles kommen
      // als eigene Dateien, damit `style-src 'self'` ohne Ausnahme gilt (E-06).
      head: [
        link(rel: 'stylesheet', href: '/styles.css'),
        link(
          rel: 'preload',
          href: '/fonts/Inter-Regular.ttf',
          as: 'font',
          type: 'font/ttf',
          attributes: {'crossorigin': ''},
        ),
        meta(name: 'robots', content: 'noindex, nofollow'),
      ],
      body: App(),
    ),
  );
}
