import 'package:flutter/material.dart';

import '../../models/app_tab.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/pointing_arrow.dart';
import 'app_tab_meta.dart';

/// Un slide du tuto général (voir [_tutoSlides]) — explique une grande ligne
/// de l'appli plutôt qu'une question à répondre, contrairement aux étapes
/// mode/budget qui suivent. [points] : quelques puces courtes plutôt qu'un
/// paragraphe continu — un bloc de texte "monolithique" donnait moins
/// envie de lire que des points séparés, plus faciles à parcourir.
class _TutoSlide {
  final String title;
  final String caption;
  final List<String> points;
  final IconData icon;
  const _TutoSlide({required this.title, required this.caption, required this.points, required this.icon});
}

/// Bandeau d'accueil pour la toute première connexion — équivalent de
/// `Onboarding` du prototype, étendu d'un tuto général (voir [_tutoSlides])
/// avant les deux questions d'origine (type de location, budget) qui
/// préparent le premier calcul.
///
/// [tutoOnly] réaffiche uniquement les slides du tuto général, sans les
/// deux questions — utilisé pour "Revoir le tuto" depuis l'aide, une fois
/// la première connexion déjà passée : ni le formulaire en cours ni le
/// statut "onboarding-done" ne doivent être touchés à cette occasion,
/// [onFinish] est alors appelé avec `(null, null)`.
class OnboardingSheet extends StatefulWidget {
  final void Function(RentalMode? mode, double? budget) onFinish;
  final bool tutoOnly;
  const OnboardingSheet({super.key, required this.onFinish, this.tutoOnly = false});

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> with SingleTickerProviderStateMixin {
  // Tuto général (grandes lignes de l'appli) suivi des deux questions
  // d'origine — un seul et même enchaînement d'étapes, plutôt que deux
  // popups qui se suivraient, pour que "Retour"/"Passer" restent cohérents
  // sur l'ensemble. Un slide par onglet (plutôt qu'un seul slide qui les
  // énumère à la suite) pour laisser la place à une vraie explication de
  // chacun — icônes reprises telles quelles de `kTabMeta` : ce sont
  // exactement celles que l'utilisateur retrouve ensuite dans la barre du
  // bas, pas des icônes inventées pour le tuto.
  final List<_TutoSlide> _tutoSlides = [
    _TutoSlide(
      title: 'Bienvenue 👋',
      caption: "Je suis Didou, je t'accompagne",
      icon: Icons.waving_hand_outlined,
      points: const [
        "T'aide à savoir si un bien est un bon investissement avant de te lancer",
        'Rentabilité, financement et fiscalité au même endroit',
        'Un tour rapide de chaque onglet avant de commencer',
      ],
    ),
    _TutoSlide(
      title: 'Onglet "Bien" — le point de départ',
      caption: 'Comment remplir',
      icon: kTabMeta[AppTab.calc]!.icon,
      points: const [
        'Renseigne le nom, la localisation, le prix et la surface',
        'Ajoute les revenus attendus',
        'La rentabilité se calcule automatiquement, au fur et à mesure',
      ],
    ),
    _TutoSlide(
      title: 'Onglet "Marché"',
      caption: 'Repères de prix du secteur',
      icon: kTabMeta[AppTab.marche]!.icon,
      points: const [
        'Prix et loyer au m² du secteur, une fois la commune renseignée',
        "L'écart entre ton bien et ce repère",
        "Un score d'investissement qui résume la comparaison",
      ],
    ),
    _TutoSlide(
      title: 'Onglet "Carte"',
      caption: 'Les prix, visuellement',
      icon: kTabMeta[AppTab.carte]!.icon,
      points: const [
        'Les mêmes repères de prix, visualisés sur une carte',
        "Compare plusieurs secteurs d'un coup d'œil",
      ],
    ),
    _TutoSlide(
      title: 'Onglet "Fiscalité"',
      caption: 'Régimes, démarches, échéances',
      icon: kTabMeta[AppTab.fisc]!.icon,
      points: const [
        'Compare les régimes fiscaux possibles (micro-foncier, LMNP...)',
        'Documents et démarches à prévoir',
        'Échéances récurrentes à ne pas rater',
      ],
    ),
    _TutoSlide(
      title: 'Onglet "Projection"',
      caption: 'Ton patrimoine dans le temps',
      icon: kTabMeta[AppTab.proj]!.icon,
      points: const [
        "Tableau d'amortissement du prêt",
        'Simulation de revente à différentes échéances',
        'TRI en mode avancé',
      ],
    ),
    _TutoSlide(
      title: 'Personnalise ton affichage',
      caption: 'Onglets et blocs',
      icon: Icons.dashboard_customize_outlined,
      points: const [
        'Réordonne ou masque les onglets',
        "Personnalise aussi les blocs à l'intérieur de chaque onglet",
        'Tout reste modifiable ensuite',
      ],
    ),
    _TutoSlide(
      title: 'Suis tes biens',
      caption: 'Une fois enregistrés',
      icon: kTabMeta[AppTab.biens]!.icon,
      points: const [
        '"Enregistrer ce bien" l\'ajoute à "Comparer" et "Patrimoine"',
        'Modifie-le à tout moment, compare plusieurs biens entre eux',
        'Exporte tes données en PDF ou CSV',
      ],
    ),
  ];

  int _step = 0;
  RentalMode _mode = RentalMode.longue;
  double _budget = 180000;

  int get _totalSteps => widget.tutoOnly ? _tutoSlides.length : _tutoSlides.length + 2;
  bool get _onTutoSlide => _step < _tutoSlides.length;
  bool get _onModeStep => !widget.tutoOnly && _step == _tutoSlides.length;

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

  void _finish() => widget.onFinish(widget.tutoOnly ? null : _mode, widget.tutoOnly ? null : _budget);

  void _goTo(int step) {
    setState(() => _step = step);
    // Rejoue le petit rebond d'arrivée de Didou à chaque étape plutôt
    // qu'une seule fois au tout premier affichage — un repère visuel que
    // le contenu vient de changer.
    _didouController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final title = _onTutoSlide
        ? _tutoSlides[_step].title
        : _onModeStep
            ? 'Pour commencer'
            : 'Ton budget';
    final caption = _onTutoSlide
        ? _tutoSlides[_step].caption
        : _onModeStep
            ? 'Encore deux questions rapides'
            : 'Une dernière question et on y est';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                            Text(title, style: AppTextStyles.serif(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text(caption, style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStepDots(),
                  const SizedBox(height: 8),
                  if (_onTutoSlide)
                    ..._buildTutoSlide(_tutoSlides[_step])
                  else if (_onModeStep)
                    ..._buildStepMode()
                  else
                    ..._buildStepBudget(),
                  const SizedBox(height: 24),
                  Row(children: [
                    if (_step > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => _goTo(_step - 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          ),
                          child: const Text('Retour'),
                        ),
                      ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _step < _totalSteps - 1 ? _goTo(_step + 1) : _finish(),
                        icon: const Icon(Icons.arrow_forward, size: 15),
                        label: Text(_step < _totalSteps - 1 ? 'Continuer' : (widget.tutoOnly ? 'Fermer' : "C'est parti")),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                  // "Passer" n'a de sens que pour sauter aux questions
                  // mode/budget — en relecture du tuto seul ([tutoOnly]),
                  // il n'y a rien de plus à sauter, "Fermer" suffit.
                  if (!widget.tutoOnly) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => widget.onFinish(null, null),
                        child: Text('Passer', style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.4))),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Petits points de progression — repère discret sur les étapes
  // (`_tutoSlides.length`, plus les 2 questions hors du mode [tutoOnly]),
  // pas la peine de compter le nombre exact affiché en toutes lettres.
  Widget _buildStepDots() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final active = i == _step;
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Container(
            width: active ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.accent : AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildTutoSlide(_TutoSlide slide) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // La flèche vive pointe vers l'icône qui représente ce dont
              // parle le slide (celle qu'on retrouve ensuite dans la vraie
              // barre du bas) — un repère qui "montre" plutôt qu'une
              // simple liste, sans dépendre de la position réelle de
              // cette icône à l'écran (masquée par la feuille du tuto
              // elle-même). Clé sur `_step` : sans elle, Flutter réutilise
              // le même État (et donc la même animation déjà épuisée)
              // d'un slide à l'autre au lieu de rejouer le rebond à
              // chaque fois.
              PointingArrow(key: ValueKey(_step)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(slide.icon, size: 18, color: AppColors.accent),
              ),
            ]),
            const SizedBox(height: 12),
            // Quelques puces courtes plutôt qu'un paragraphe continu — un
            // bloc de texte "monolithique" se parcourt moins bien et donne
            // moins envie de lire que des points séparés.
            for (final point in slide.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 7, right: 10),
                      decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(point, style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.85))),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildStepMode() {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 8),
        child: Text('Deux questions rapides pour préparer ton premier calcul. Tout reste modifiable ensuite.',
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
          color: active ? AppColors.accent : AppColors.surface,
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
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
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
