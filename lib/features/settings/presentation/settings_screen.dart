import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../application/settings_providers.dart';
import '../domain/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsControllerProvider);
    final db = ref.watch(contentDatabaseProvider);
    final patristics = db?.meta('patristics_count');
    final translation = TranslationOption.catalogue
        .firstWhere((t) => t.id == s.primaryTranslationId,
            orElse: () => TranslationOption.catalogue.first);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          _section(c, 'Conta'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Nome'),
            subtitle: Text(s.displayName.isEmpty ? '—' : s.displayName),
            onTap: () => _editName(context, s.displayName, ctrl.setDisplayName),
          ),
          _section(c, 'Leitura'),
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('Tradução'),
            subtitle: Text(translation.title),
            onTap: () => _pick<TranslationOption>(
              context,
              'Tradução',
              TranslationOption.catalogue,
              (t) => t.title,
              translation,
              (t) => ctrl.setTranslation(t.id),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma do app'),
            subtitle: Text(s.language.label),
            onTap: () => _pick<AppLanguage>(
              context,
              'Idioma',
              AppLanguage.values,
              (l) => l.label,
              s.language,
              ctrl.setLanguage,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Tema'),
            subtitle: Text(switch (s.themeMode) {
              ThemeMode.light => 'Claro',
              ThemeMode.system => 'Sistema',
              ThemeMode.dark => 'Escuro',
            }),
            onTap: () => _pick<ThemeMode>(
              context,
              'Tema',
              ThemeMode.values,
              (m) => switch (m) {
                ThemeMode.light => 'Claro',
                ThemeMode.system => 'Sistema',
                ThemeMode.dark => 'Escuro',
              },
              s.themeMode,
              ctrl.setThemeMode,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none),
            title: const Text('Lembretes diários'),
            value: s.notificationsEnabled,
            onChanged: ctrl.setNotifications,
          ),
          _section(c, 'Recursos baixados'),
          ListTile(
            leading: const Icon(Icons.auto_stories),
            title: const Text('Comentário Patrístico'),
            subtitle: Text(patristics == null
                ? 'não instalado'
                : '$patristics comentários instalados'),
            trailing: Icon(
                patristics == null ? Icons.download : Icons.check_circle,
                color:
                    patristics == null ? c.textFaint : LiturgicalPalette.green),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Traduções da Bíblia'),
            subtitle: const Text('Gerir pacotes offline'),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.go('/home'),
              child: Text('Fechar', style: TextStyle(color: c.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  void _editName(
      BuildContext context, String current, ValueChanged<String> onSave) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nome'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'O seu nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _pick<T>(BuildContext context, String title, List<T> options,
      String Function(T) labelOf, T current, ValueChanged<T> onSelect) {
    final c = context.bt;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final o in options)
              ListTile(
                title: Text(labelOf(o)),
                trailing: o == current
                    ? Icon(Icons.check, color: c.accent)
                    : null,
                onTap: () {
                  onSelect(o);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _section(BtColors c, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(title.toUpperCase(),
            style: TextStyle(
                color: c.textFaint,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600)),
      );
}
