import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';

/// Bandeau d'accueil en 2 étapes — équivalent de `Onboarding` du prototype.
class OnboardingSheet extends StatefulWidget {
  final void Function(RentalMode? mode, double? budget) onFinish;
  const OnboardingSheet({super.key, required this.onFinish});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> with SingleTickerProviderStateMixin {
  int _step = 0;
  RentalMode _mode = RentalMode.longue;
  double _budget = 180000;

  late final AnimationController _didouController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _didouScale =
      CurvedAnimation(parent: _didouController, curve: Curves.easeOutBack);
  late final Animation<double> _didouFade =
      CurvedAnimation(parent: _didouController, curve: const Interval(0, 0.6, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _didouController.forward();
  }

  @override
  void dispose() {
    _didouController.dispose();
    super.dispose();
  }

  void _finish() => widget.onFinish(_mode, _budget);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _didouFade,
                        child: ScaleTransition(
                          scale: _didouScale,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/didou_face.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_step == 0 ? 'Bienvenue 👋' : 'Ton budget',
                                style: AppTextStyles.serif(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text(
                              _step == 0 ? "Je suis Didou, je t'accompagne" : 'Encore une question et on y est',
                              style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_step == 0) ..._buildStepMode() else ..._buildStepBudget(),
                  const SizedBox(height: 24),
                  Row(children: [
                    if (_step > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step -= 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          ),
                          child: const Text('Retour'),
                        ),
                      ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _step < 1 ? setState(() => _step += 1) : _finish(),
                        icon: Icon(_step < 1 ? Icons.arrow_forward : Icons.arrow_forward, size: 15),
                        label: Text(_step < 1 ? 'Continuer' : "C'est parti"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => widget.onFinish(null, null),
                      child: Text('Passer', style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.4))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStepMode() {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 8),
        child: Text('Trois questions rapides pour préparer ton premier calcul. Tout reste modifiable ensuite.',
            style: AppTextStyles.sans(fontSize: 13.5, color: AppColors.ink.withValues(alpha: 0.7))),
      ),
      Text('Quel type de location vises-tu ?', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _modeCard(RentalMode.longue, 'Longue durée', Icons.apartment_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _modeCard(RentalMode.courte, 'Courte durée', Icons.bed_outlined)),
      ]),
    ];
  }

  Widget _modeCard(RentalMode mode, String label, IconData icon) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.accent : AppColors.border, width: 1.5),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: active ? Colors.white : AppColors.ink),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : AppColors.ink)),
        ]),
      ),
    );
  }

  List<Widget> _buildStepBudget() {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 8),
        child: Text('Budget total approximatif pour ce projet (prix du bien, frais compris).',
            style: AppTextStyles.sans(fontSize: 13.5, color: AppColors.ink.withValues(alpha: 0.7))),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Slider(
            value: _budget,
            min: 50000,
            max: 600000,
            divisions: 110,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(() => _budget = v),
          ),
          Text(eur(_budget), style: AppTextStyles.mono(fontSize: 22, color: AppColors.accent)),
        ]),
      ),
    ];
  }
}
