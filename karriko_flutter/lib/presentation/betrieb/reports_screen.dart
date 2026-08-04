import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../common/app_bar_widget.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _reasonCtrl = TextEditingController();
  String? _selectedReviewId;
  String _selectedReason = 'Unangemessener Inhalt';

  final List<String> _reasons = [
    'Unangemessener Inhalt',
    'Falsche Informationen',
    'Spam',
    'Verleumdung',
    'Sonstiges',
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Die Meldung wird der angemeldeten Person zugeordnet. Ohne Sitzung
    // bleibt der Knopf gesperrt, statt einen Platzhalter zu schreiben.
    final reporterId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: const KarrikoAppBar(title: 'Bewertungen melden'),
      drawer: const KarrikoDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFB45309)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Melde Bewertungen, die gegen unsere Richtlinien verstoßen. Unser Team prüft jede Meldung individuell.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Neue Meldung',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Bewertungs-ID'),
              onChanged: (v) =>
                  setState(() => _selectedReviewId = v.isEmpty ? null : v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(labelText: 'Grund der Meldung'),
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedReason = v ?? _selectedReason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Zusätzliche Erläuterung (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedReviewId != null && reporterId != null
                    ? () async {
                        await ref.read(reviewRepositoryProvider).reportReview(
                              reviewId: _selectedReviewId!,
                              reporterId: reporterId,
                              reason: _reasonCtrl.text.isEmpty
                                  ? _selectedReason
                                  : '$_selectedReason: ${_reasonCtrl.text}',
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Meldung eingereicht. Wir prüfen den Fall.')));
                          setState(() {
                            _selectedReviewId = null;
                            _reasonCtrl.clear();
                          });
                        }
                      }
                    : null,
                child: const Text('Meldung einreichen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
