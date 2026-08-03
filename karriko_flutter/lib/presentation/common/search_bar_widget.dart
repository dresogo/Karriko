import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/company_provider.dart';

class HomeSearchBar extends ConsumerStatefulWidget {
  const HomeSearchBar({super.key});

  @override
  ConsumerState<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends ConsumerState<HomeSearchBar> {
  final _controller = TextEditingController();
  bool _showSuggestions = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus && _controller.text.length >= 2);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _focusNode.unfocus();
    context.go('/search?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final suggestions = query.length >= 2
        ? ref.watch(searchSuggestionsProvider(query))
        : const AsyncValue.data(<String>[]);

    return Column(
      children: [
        // search-row: bordered container with input + red button (kept square)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (v) {
                    setState(() => _showSuggestions = v.length >= 2);
                  },
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Betrieb oder Beruf suchen ...',
                    hintStyle: const TextStyle(color: Color(0xFF8C8E88), fontSize: 16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    constraints: const BoxConstraints(minHeight: 62),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.muted, size: 18),
                            onPressed: () => setState(() {
                              _controller.clear();
                              _showSuggestions = false;
                            }),
                          )
                        : null,
                  ),
                ),
              ),
              // Red search button
              GestureDetector(
                onTap: _search,
                child: Container(
                  width: 58,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    border: Border(left: BorderSide(color: AppColors.ink, width: 2)),
                  ),
                  child: const Center(
                    child: Icon(Icons.search, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showSuggestions)
          suggestions.when(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : _SuggestionList(
                    suggestions: list,
                    onTap: (s) {
                      _controller.text = s;
                      _focusNode.unfocus();
                      context.go('/search?q=${Uri.encodeComponent(s)}');
                    },
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionList({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: suggestions
            .map(
              (s) => GestureDetector(
                onTap: () => onTap(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 14, color: AppColors.muted),
                      const SizedBox(width: 10),
                      Text(s,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
