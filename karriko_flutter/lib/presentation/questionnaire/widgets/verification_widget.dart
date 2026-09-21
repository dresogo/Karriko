import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/file_pick.dart';
import '../question_context.dart';

/// Der Nachweis des Ausbildungsverhältnisses aus A5.
///
/// Warum das überhaupt sein muss: Nach der Hamburger Rechtsprechung muss ein
/// bewerteter Betrieb prüfen können, ob überhaupt ein geschäftlicher Kontakt
/// bestand; geschwärzte Unterlagen allein reichten dem OLG nicht. Ohne einen
/// belastbaren Verifikationsprozess ist jede kritische Bewertung
/// löschungsgefährdet — und damit genau der Inhalt, für den Azubis die
/// Plattform benutzen.
///
/// Freiwillig bleibt es trotzdem. Eine Bewertung ohne Nachweis geht durch, sie
/// trägt nur kein Siegel. Die Verifikation zur Pflicht zu machen hieße, jede
/// Bewertung von einem Dokument abhängig zu machen, das nicht jeder zur Hand
/// hat.
class VerificationUpload extends StatefulWidget {
  final QuestionContext context;

  /// Lädt hoch und gibt die Datei-Kennung zurück.
  final Future<String> Function(PickedFile datei) onUpload;

  /// Die bereits hochgeladene Datei, falls es eine gibt.
  final String? fileId;

  const VerificationUpload({
    super.key,
    required this.context,
    required this.onUpload,
    this.fileId,
  });

  @override
  State<VerificationUpload> createState() => _VerificationUploadState();
}

class _VerificationUploadState extends State<VerificationUpload> {
  bool _laeuft = false;
  String? _fehler;
  String? _dateiname;

  List<String> get _endungen {
    final roh = widget.context.config<List<Object?>>('extensions') ?? const [];
    return [
      for (final eintrag in roh)
        if (eintrag is String) eintrag,
    ];
  }

  int get _maxBytes =>
      (widget.context.configNum('maxBytes') ?? 10 * 1024 * 1024).round();

  Future<void> _waehlen() async {
    setState(() {
      _laeuft = true;
      _fehler = null;
    });

    try {
      final datei = await pickFile(extensions: _endungen);
      if (datei == null) {
        if (mounted) setState(() => _laeuft = false);
        return;
      }
      if (datei.size > _maxBytes) {
        if (mounted) {
          setState(() {
            _laeuft = false;
            _fehler = 'Die Datei ist zu groß. Erlaubt sind '
                '${(_maxBytes / 1024 / 1024).round()} MB.';
          });
        }
        return;
      }

      await widget.onUpload(datei);
      if (!mounted) return;
      setState(() {
        _laeuft = false;
        _dateiname = datei.name;
      });
    } on UnsupportedError catch (e) {
      if (!mounted) return;
      setState(() {
        _laeuft = false;
        _fehler = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _laeuft = false;
        _fehler = 'Der Nachweis konnte nicht hochgeladen werden. '
            'Du kannst die Bewertung auch ohne ihn abschicken.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.context;
    final hinweisKey = ctx.config<String>('noticeKey');
    final hinweis = hinweisKey == null ? null : ctx.sharedText(hinweisKey);
    final hochgeladen = widget.fileId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hinweis != null) ...[
          Text(
            hinweis,
            style: const TextStyle(color: AppColors.muted, height: 1.55),
          ),
          const SizedBox(height: AppLayout.s24),
        ],
        if (hochgeladen)
          Container(
            padding: const EdgeInsets.all(AppLayout.s16),
            decoration: BoxDecoration(
              color: AppColors.audienceBeige,
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.check, color: AppColors.green, size: 18),
                const SizedBox(width: AppLayout.s8),
                Expanded(
                  child: Text(
                    _dateiname == null
                        ? (ctx.sharedText('ui.upload_done') ?? '')
                        : '${ctx.sharedText('ui.upload_done')}: $_dateiname',
                  ),
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _laeuft ? null : _waehlen,
            icon: _laeuft
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file, size: 18),
            label: Text(ctx.sharedText('ui.upload') ?? ''),
          ),
        if (_endungen.isNotEmpty) ...[
          const SizedBox(height: AppLayout.s8),
          Text(
            '${_endungen.join(', ')} · max. '
            '${(_maxBytes / 1024 / 1024).round()} MB',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
        if (_fehler != null) ...[
          const SizedBox(height: AppLayout.s16),
          Text(
            _fehler!,
            style: const TextStyle(color: AppColors.accent, height: 1.5),
          ),
        ],
      ],
    );
  }
}
