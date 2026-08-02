import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bar_widget.dart';
import '../common/footer_widget.dart';

/// Gemeinsames Gerüst der Login-Seiten.
///
/// Übernimmt das geteilte Raster des Startseiten-Heros: links die redaktionelle
/// Spalte auf Papierfläche, rechts das weiße Aktionspanel, getrennt durch eine
/// Haarlinie. Ab 980 px nebeneinander, darunter gestapelt.
///
/// Der Bereich füllt immer mindestens den Viewport unterhalb der Kopfzeile, der
/// Footer liegt darunter. Weil die Höhe über [IntrinsicHeight] ermittelt wird,
/// dürfen die Spalten ihre Breite ausschließlich über Padding begrenzen –
/// `ConstrainedBox(maxWidth:)` reicht die äußere Breite an die Messung weiter
/// und führt zu einer zu klein berechneten Texthöhe.
class LoginShell extends StatelessWidget {
  final String appBarTitle;
  final String eyebrow;
  final String headline;
  final String lede;

  /// Optionaler Fußtext der linken Spalte (z. B. Vertrauenshinweis).
  final Widget? aside;

  /// Inhalt des weißen Panels.
  final Widget child;

  const LoginShell({
    super.key,
    required this.appBarTitle,
    required this.eyebrow,
    required this.headline,
    required this.lede,
    this.aside,
    required this.child,
  });

  /// Breite der redaktionellen Spalte im geteilten Raster (47 % der Fläche
  /// abzüglich der Trennlinie).
  static double _copyWidth(double totalWidth) => (totalWidth - 1) * 0.47;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 980;

    // Der Login-Bereich füllt den Viewport unterhalb der Kopfzeile vollständig,
    // unabhängig von der Bildschirmhöhe. Passt der Inhalt nicht hinein, wächst
    // die Sektion mit, statt abzuschneiden.
    final sectionHeight =
        mq.size.height - KarrikoAppBar.height - mq.padding.top - mq.padding.bottom;

    final copyWidth = isWide ? _copyWidth(mq.size.width) : mq.size.width;
    final panelWidth = isWide ? mq.size.width - 1 - copyWidth : mq.size.width;

    final copy = _Copy(
      eyebrow: eyebrow,
      headline: headline,
      lede: lede,
      aside: aside,
      isWide: isWide,
      width: copyWidth,
    );
    final panel = _Panel(isWide: isWide, width: panelWidth, child: child);

    return Scaffold(
      appBar: KarrikoAppBar(title: appBarTitle),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: sectionHeight > 0 ? sectionHeight : 0),
              child: Container(
                decoration: BoxDecoration(
                  // Gestapelt liegt das weiße Panel unten; überschüssige Höhe
                  // bekommt dieselbe Fläche, damit kein Farbsprung entsteht.
                  color: isWide ? null : AppColors.surface,
                  border: const Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: isWide
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: copyWidth, child: copy),
                            Container(width: 1, color: AppColors.line),
                            SizedBox(width: panelWidth, child: panel),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(color: AppColors.paper, child: copy),
                          const Divider(color: AppColors.line, height: 1),
                          panel,
                        ],
                      ),
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String lede;
  final Widget? aside;
  final bool isWide;
  final double width;

  /// Maximale Zeilenlänge des Fließtexts.
  static const double _measure = 460;

  const _Copy({
    required this.eyebrow,
    required this.headline,
    required this.lede,
    required this.aside,
    required this.isWide,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final hPad = isWide ? AppLayout.gutter(viewportWidth) : AppLayout.s24;
    final vPad = isWide ? AppLayout.s64 : AppLayout.s48;
    final contentWidth = width - hPad * 2;
    final ledeInset = (contentWidth - _measure).clamp(0.0, double.infinity);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: isWide ? AppLayout.s48 : AppLayout.s32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.32,
                  ),
                ),
                const SizedBox(height: AppLayout.s16),
                Text(
                  headline,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: isWide ? (viewportWidth * 0.042).clamp(40.0, 64.0) : 38,
                    fontWeight: FontWeight.w800,
                    height: 0.96,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppLayout.s24),
                Padding(
                  padding: EdgeInsets.only(right: ledeInset),
                  child: Text(
                    lede,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 17,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (aside != null) aside!,
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final bool isWide;
  final double width;
  final Widget child;

  /// Maximale Breite des Formulars innerhalb des Panels.
  static const double _measure = 520;

  const _Panel({required this.isWide, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    final basePad = isWide ? AppLayout.s64 : AppLayout.s24;
    final vPad = isWide ? AppLayout.s64 : AppLayout.s48;
    final contentWidth = width - basePad * 2;
    final inset = ((contentWidth - _measure) / 2).clamp(0.0, double.infinity);

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(basePad + inset, vPad, basePad + inset, vPad),
      // Zentriert den Inhalt vertikal im Panel. Ein einfaches Align genügt nicht:
      // Der Inhalt ist selbst eine Column mit MainAxisSize.max und würde die
      // volle Höhe einnehmen. Als Kind dieser Column bekommt er unbegrenzte
      // Höhe, schrumpft auf seine Inhaltshöhe und lässt sich damit ausrichten.
      // Zentriert den Inhalt vertikal im Panel. Ein einfaches Align genügt nicht:
      // Der Inhalt ist selbst eine Column mit MainAxisSize.max und würde die
      // volle Höhe einnehmen. Als Kind dieser Column bekommt er unbegrenzte
      // Höhe, schrumpft auf seine Inhaltshöhe und lässt sich damit ausrichten.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child],
      ),
    );
  }
}

/// Vertrauenshinweis am Fuß der linken Spalte. Icon und Text liegen in einem
/// einzigen Textfluss, damit die Höhenmessung im geteilten Raster exakt bleibt.
class LoginTrustNote extends StatelessWidget {
  final String text;

  const LoginTrustNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(right: AppLayout.s8),
              child: Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }
}

/// Fehlermeldung im Stil der Website: Papierfläche mit Akzentkante links,
/// Text in Tintenschwarz (Kontrast ≥ 4.5:1) und zusätzlichem Icon, damit die
/// Aussage nicht allein über Farbe transportiert wird.
class LoginErrorBanner extends StatelessWidget {
  final String message;

  const LoginErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppLayout.s16),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.only(right: AppLayout.s8),
                  child: Icon(Icons.error_outline, size: 18, color: AppColors.accentDark),
                ),
              ),
              TextSpan(text: message),
            ],
          ),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
