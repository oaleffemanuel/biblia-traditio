import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';

/// Transparent (not scary) disclosure of where each piece of content comes from
/// and under what terms — reachable from Settings → About.
class AttributionsScreen extends StatelessWidget {
  const AttributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.licensesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Text(l10n.licensesIntro,
                  style: TextStyle(color: c.textSecondary, height: 1.5)),
            ),
            _SourceCard(
                icon: Icons.menu_book_outlined,
                title: l10n.licVulgataTitle,
                body: l10n.licVulgataBody),
            _SourceCard(
                icon: Icons.auto_stories_outlined,
                title: l10n.licPatristicsTitle,
                body: l10n.licPatristicsBody),
            _SourceCard(
                icon: Icons.translate,
                title: l10n.licPortugueseTitle,
                body: l10n.licPortugueseBody),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.code, color: c.textSecondary),
              title: Text(l10n.ossLicenses),
              trailing: Icon(Icons.chevron_right, color: c.textFaint),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appName,
                applicationVersion: '1.0.0',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SourceCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(body,
                    style: TextStyle(color: c.textSecondary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
