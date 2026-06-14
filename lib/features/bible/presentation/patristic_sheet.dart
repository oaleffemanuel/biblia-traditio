import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/bible_providers.dart';
import '../domain/entities.dart';

/// Opens the "Padres da Igreja" panel for a verse: author · century · source.
void showPatristicSheet(BuildContext context, VerseRef ref, String bookName) {
  final c = context.bt;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, controller) =>
          _PatristicBody(vref: ref, bookName: bookName, controller: controller),
    ),
  );
}

class _PatristicBody extends ConsumerWidget {
  final VerseRef vref;
  final String bookName;
  final ScrollController controller;
  const _PatristicBody(
      {required this.vref, required this.bookName, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final items = ref.watch(commentariesProvider(vref));
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: c.divider, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(children: [
            Icon(Icons.auto_stories, color: c.accent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Padres da Igreja',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text('$bookName ${vref.chapter},${vref.verse}',
                style: TextStyle(color: c.textSecondary)),
          ]),
        ),
        Divider(height: 1, color: c.divider),
        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (_, i) => _CommentaryCard(items[i]),
          ),
        ),
      ],
    );
  }
}

class _CommentaryCard extends StatelessWidget {
  final Commentary item;
  const _CommentaryCard(this.item);

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(item.fatherName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: c.accent, fontWeight: FontWeight.w600)),
          ),
          if (item.century.isNotEmpty)
            Text('séc. ${item.century}',
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Text(item.text,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontSize: 17, height: 1.5)),
        if (item.isMachineTranslation) ...[
          const SizedBox(height: 8),
          Text('tradução automática · ${item.source ?? 'fonte tradicional'}',
              style: TextStyle(color: c.textFaint, fontSize: 11)),
        ],
      ],
    );
  }
}
