import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/snack.dart';
import '../../../core/theme/app_theme.dart';
import '../../packages/application/package_providers.dart';
import '../../packages/domain/content_package.dart';
import '../application/settings_providers.dart';
import '../domain/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.bt;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsControllerProvider);
    final packages = ref.watch(installablePackagesProvider);
    final available = ref.watch(availableTranslationsProvider);
    final resolvedId = ref.watch(resolvedTranslationIdProvider);
    final l10n = context.l10n;
    final translationTitle = available
        .where((t) => t.id == resolvedId)
        .map((t) => t.title)
        .firstOrNull ??
        l10n.noTranslationInstalled;
    String themeLabel(ThemeMode m) => switch (m) {
          ThemeMode.light => l10n.themeLight,
          ThemeMode.system => l10n.themeSystem,
          ThemeMode.dark => l10n.themeDark,
        };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _section(c, l10n.settingsAccount),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsName),
            subtitle: Text(s.displayName.isEmpty ? '—' : s.displayName),
            onTap: () => _editName(context, s.displayName, ctrl.setDisplayName,
                l10n.settingsName),
          ),
          _section(c, l10n.settingsReading),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.settingsTranslation),
            subtitle: Text(translationTitle),
            enabled: available.isNotEmpty,
            onTap: available.isEmpty
                ? null
                : () => _pick<({String id, String lang, String title})>(
                      context,
                      l10n.settingsTranslation,
                      available,
                      (t) => t.title,
                      available.firstWhere((t) => t.id == resolvedId,
                          orElse: () => available.first),
                      (t) => ctrl.setTranslation(t.id),
                    ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsAppLanguage),
            subtitle: Text(s.language.label),
            onTap: () => _pick<AppLanguage>(
              context,
              l10n.settingsAppLanguage,
              AppLanguage.values,
              (l) => l.label,
              s.language,
              ctrl.setLanguage,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(l10n.settingsTheme),
            subtitle: Text(themeLabel(s.themeMode)),
            onTap: () => _pick<ThemeMode>(
              context,
              l10n.settingsTheme,
              ThemeMode.values,
              themeLabel,
              s.themeMode,
              ctrl.setThemeMode,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none),
            title: Text(l10n.settingsReminders),
            value: s.notificationsEnabled,
            onChanged: ctrl.setNotifications,
          ),
          _section(c, l10n.settingsOfflineResources),
          for (final entry in packages)
            _PackageTile(pkg: entry.pkg, installed: entry.installed),
          _section(c, l10n.settingsContact),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline,
                color: Color(0xFF25D366)),
            title: Text(l10n.whatsappTitle),
            subtitle: Text(l10n.whatsappSubtitle),
            onTap: () => _openWhatsApp(context),
          ),
          _section(c, l10n.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.licensesTitle),
            trailing: Icon(Icons.chevron_right, color: c.textFaint),
            onTap: () => context.push('/licenses'),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.go('/home'),
              child:
                  Text(l10n.actionClose, style: TextStyle(color: c.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    const phone = '5531975965032'; // +55 31 97596-5032
    const msg = 'Olá! Escrevo sobre o app Biblia Traditio.';
    final encoded = Uri.encodeComponent(msg);
    // Prefer the WhatsApp app; fall back to the browser (wa.me). Capture the
    // failure message before any await so we never touch a stale context.
    final failMsg = context.l10n.contactLaunchFailed;
    final appUri = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
    final webUri = Uri.parse('https://wa.me/$phone?text=$encoded');
    try {
      if (await canLaunchUrl(appUri) && await launchUrl(appUri)) return;
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) return;
      showSnack(failMsg);
    } catch (_) {
      showSnack(failMsg);
    }
  }

  void _editName(BuildContext context, String current,
      ValueChanged<String> onSave, String title) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              InputDecoration(hintText: ctx.l10n.namePlaceholder),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.actionCancel)),
          FilledButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: Text(ctx.l10n.actionSave),
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

String _mb(int bytes) => '${(bytes / 1048576).toStringAsFixed(0)} MB';

class _PackageTile extends ConsumerStatefulWidget {
  final ContentPackage pkg;
  final bool installed;
  const _PackageTile({required this.pkg, required this.installed});
  @override
  ConsumerState<_PackageTile> createState() => _PackageTileState();
}

class _PackageTileState extends ConsumerState<_PackageTile> {
  bool _busy = false;
  double _progress = 0;

  IconData get _icon => switch (widget.pkg.type) {
        PackageType.patristics => Icons.auto_stories,
        PackageType.bibleTranslation => Icons.menu_book,
        PackageType.liturgy => Icons.calendar_month,
        PackageType.catechism => Icons.school_outlined,
        _ => Icons.inventory_2_outlined,
      };

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _progress = 0;
    });
    final successMsg = context.l10n.installSuccess;
    try {
      await ref.read(packageControllerProvider).install(widget.pkg,
          onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      showSnack(successMsg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.installFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Confirms first — removing forces a fresh (potentially large) re-download.
  Future<void> _remove() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removePackageTitle),
        content: Text(l10n.removePackageMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionRemove)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(packageControllerProvider).remove(widget.pkg);
      showSnack(l10n.removeSuccess);
    } catch (e) {
      showSnack(l10n.installFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    final pkg = widget.pkg;
    final l10n = context.l10n;
    final subtitle = widget.installed
        ? l10n.packageInstalled(_mb(pkg.sizeBytes))
        : pkg.required
            ? l10n.packageRequired
            : l10n.packageDownload(_mb(pkg.compressedBytes), _mb(pkg.sizeBytes));

    return Column(
      children: [
        ListTile(
          leading: Icon(_icon, color: c.accent),
          title: Text(pkg.title),
          subtitle: Text(subtitle),
          trailing: _busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _progress == 0 ? null : _progress,
                      color: c.accent))
              : widget.installed
                  ? (pkg.required
                      ? Icon(Icons.check_circle, color: LiturgicalPalette.green)
                      : IconButton(
                          tooltip: l10n.actionRemove,
                          icon: Icon(Icons.delete_outline,
                              color: c.textSecondary),
                          onPressed: _remove))
                  : IconButton(
                      tooltip: l10n.actionDownload,
                      icon: Icon(Icons.download, color: c.accent),
                      onPressed: _install),
        ),
        if (_busy)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                backgroundColor: c.surfaceHigh,
                color: c.accent),
          ),
      ],
    );
  }
}
