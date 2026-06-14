import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/settings.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  static const _steps = 6;

  // collected choices
  final _nameController = TextEditingController();
  AppLanguage _language = AppLanguage.pt;
  String _translationId = 'pt_cat';
  bool _notifications = false;
  bool _readingPlan = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _finish() {
    final s = ref.read(settingsControllerProvider);
    s.setDisplayName(_nameController.text.trim());
    s.setLanguage(_language);
    s.setTranslation(_translationId);
    s.setNotifications(_notifications);
    s.setWantsReadingPlan(_readingPlan);
    s.completeOnboarding(); // flips initial route to /home
  }

  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      onPressed: _back,
                      icon: Icon(Icons.arrow_back, color: c.textSecondary),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  _ProgressDots(step: _step, total: _steps),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                              begin: const Offset(0.06, 0), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(c),
                  ),
                ),
              ),
              _PrimaryButton(
                label: _step == _steps - 1 ? 'Entrar' : 'Continuar',
                enabled: _step != 1 || _nameController.text.trim().isNotEmpty,
                onTap: _next,
              ),
              if (_step > 0 && _step < _steps - 1)
                TextButton(
                  onPressed: _next,
                  child: Text('Saltar',
                      style: TextStyle(color: c.textFaint)),
                )
              else
                const SizedBox(height: 48),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BtColors c) => switch (_step) {
        0 => _Welcome(c),
        1 => _NameStep(c, _nameController, () => setState(() {})),
        2 => _ChoiceStep<AppLanguage>(
            c,
            title: 'Idioma',
            subtitle: 'Em que língua prefere a interface?',
            options: AppLanguage.values,
            labelOf: (l) => l.label,
            selected: _language,
            onSelect: (l) => setState(() => _language = l),
          ),
        3 => _ChoiceStep<TranslationOption>(
            c,
            title: 'Tradução',
            subtitle: 'Escolha a sua tradução principal das Escrituras.',
            options: TranslationOption.catalogue,
            labelOf: (t) => t.title,
            selected: TranslationOption.catalogue
                .firstWhere((t) => t.id == _translationId),
            onSelect: (t) => setState(() => _translationId = t.id),
          ),
        4 => _ToggleStep(
            c,
            icon: Icons.notifications_none,
            title: 'Lembretes diários',
            subtitle:
                'Receba um convite suave para a leitura e a liturgia do dia.',
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
        _ => _ToggleStep(
            c,
            icon: Icons.calendar_month_outlined,
            title: 'Plano de leitura',
            subtitle: 'Deseja seguir um plano para ler as Escrituras?',
            value: _readingPlan,
            onChanged: (v) => setState(() => _readingPlan = v),
          ),
      };
}

class _Welcome extends StatelessWidget {
  final BtColors c;
  const _Welcome(this.c);
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: c.accent.withValues(alpha: 0.4))),
            child: Icon(Icons.menu_book, color: c.accent, size: 44),
          ),
          const SizedBox(height: 32),
          Text('Biblia Traditio',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 12),
          Text('A Escritura à luz da Tradição.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 16)),
        ],
      );
}

class _NameStep extends StatelessWidget {
  final BtColors c;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _NameStep(this.c, this.controller, this.onChanged);
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Como devemos chamá-lo?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Usaremos o seu nome para o saudar.',
              style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => onChanged(),
            style: TextStyle(color: c.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'O seu nome',
              hintStyle: TextStyle(color: c.textFaint),
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      );
}

class _ChoiceStep<T> extends StatelessWidget {
  final BtColors c;
  final String title;
  final String subtitle;
  final List<T> options;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onSelect;
  const _ChoiceStep(this.c,
      {required this.title,
      required this.subtitle,
      required this.options,
      required this.labelOf,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                for (final o in options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SelectTile(
                      c,
                      label: labelOf(o),
                      selected: o == selected,
                      onTap: () => onSelect(o),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class _SelectTile extends StatelessWidget {
  final BtColors c;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectTile(this.c,
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? c.accent : Colors.transparent, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400)),
              ),
              if (selected) Icon(Icons.check_circle, color: c.accent, size: 20),
            ],
          ),
        ),
      );
}

class _ToggleStep extends StatelessWidget {
  final BtColors c;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleStep(this.c,
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: c.accent, size: 48),
          const SizedBox(height: 24),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, height: 1.4)),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OptionChip(c, 'Agora não', !value, () => onChanged(false)),
              const SizedBox(width: 12),
              _OptionChip(c, 'Ativar', value, () => onChanged(true)),
            ],
          ),
        ],
      );
}

class _OptionChip extends StatelessWidget {
  final BtColors c;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionChip(this.c, this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? c.accent : c.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : c.textPrimary,
                  fontWeight: FontWeight.w600)),
        ),
      );
}

class _ProgressDots extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressDots({required this.step, required this.total});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == step ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i <= step ? c.accent : c.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryButton(
      {required this.label, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.bt;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          disabledBackgroundColor: c.surfaceHigh,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
        ),
        onPressed: enabled ? onTap : null,
        child: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
