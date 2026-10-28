import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_tab.dart';
import '../../services/pdf_export_service.dart';
import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../widgets/commune_picker.dart';
import '../../widgets/digit_readout.dart';
import '../../widgets/mode_toggle.dart';
import '../../widgets/number_field.dart';
import '../../widgets/arrival_bounce.dart';
import '../../widgets/section_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/synced_text_field.dart';
import '../../widgets/tip.dart';
import '../../widgets/verdict_card.dart';

/// Nombre de comparaisons vraies dans [diffs] — sert à compter, pour un
/// encart donné, combien de ses champs diffèrent déjà de l'exemple
/// pré-rempli (voir `SectionTitle.progress`).
int _countDiff(List<bool> diffs) => diffs.where((d) => d).length;

/// Onglet "Bien" — équivalent de `CalcScreen` du prototype.
class CalcScreen extends StatefulWidget {
  final VoidCallback onSave;
  const CalcScreen({super.key, required this.onSave});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  bool _stressTaux = false;
  bool _stressOccupation = false;
  bool _stressTravaux = false;
  // Amplitude de chaque scénario — librement réglable au lieu de valeurs
  // fixes (+1 point, -25 %, +5 000 €).
  double _stressTauxPts = 1;
  double _stressOccupationPct = 25;
  double _stressTravauxEuros = 5000;
  bool _showVisite = false;
  bool _showFraisAnnexes = false;
  final Set<int> _visiteChecked = {};

  // Étape courante de l'assistant pas-à-pas (mode Débutant uniquement — voir
  // `_buildWizard`). Jamais persistée : revenir sur l'onglet "Bien" repart
  // de la première étape, ce qui reste le comportement le plus simple à
  // comprendre pour quelqu'un qui découvre l'outil — sauf si on y revient
  // via `RendementState.focusStressTest` (voir plus bas), qui saute
  // directement à la dernière étape.
  int _wizardStep = 0;

  // Repère le widget du stress-test (voir `_sectionStressTest`), construit
  // soit dans la liste classique soit dans l'assistant selon le profil —
  // jamais les deux en même temps (une seule `_CalcScreenState` à la fois
  // suit la branche Débutant OU la branche classique). Permet d'y scroller
  // directement sans connaître sa position dans la liste.
  final GlobalKey _stressTestKey = GlobalKey();

  bool get _anyStress => _stressTaux || _stressOccupation || _stressTravaux;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    // Demandé par l'utilisateur : le bouton "Faire le stress-test" de la
    // pop-up de sauvegarde (voir `property_saved_dialog.dart`,
    // `RendementState.requestStressTestFocus`) doit ouvrir directement sur
    // le stress-test, pas juste sur l'onglet "Bien" tel quel. En Débutant,
    // ça veut dire sauter à la dernière étape de l'assistant (où vit le
    // stress-test, voir `_buildWizard`) ; dans tous les cas, y scroller une
    // fois le cadre construit (voir `_stressTestKey`). La remise à `false`
    // ci-dessous n'a pas besoin de notifier : rien d'autre n'en dépend.
    if (state.focusStressTest) {
      state.focusStressTest = false;
      // Grande valeur plutôt que l'index exact de "Le verdict" : `_buildWizard`
      // la ramène de toute façon à la dernière étape valide via `.clamp`,
      // sans dépendre ici du nombre d'étapes de l'assistant.
      if (state.niveau == NiveauMode.debutant) _wizardStep = 999;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _stressTestKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic, alignment: 0.1);
        }
      });
    }
    // Mode Débutant : assistant pas-à-pas dédié (voir `_buildWizard`), pas
    // la longue liste classique — demandé par l'utilisateur, pour une vraie
    // différence d'expérience entre les 3 profils plutôt que juste masquer
    // quelques champs. Intermédiaire et Expérimenté partagent aujourd'hui
    // la même liste complète (ce qui distinguera vraiment "Expérimenté"
    // viendra dans un second temps).
    if (state.niveau == NiveauMode.debutant) {
      return _buildWizard(state);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (state.identityLocked) _newPropertyBanner(state),
        for (final id in state.visibleSections(AppTab.calc)) ..._buildSection(id, state, false),
      ],
    );
  }

  /// Une fois un bien enregistré, sa localisation/son prix/sa surface/son
  /// type sont verrouillés (voir `_sectionBien`) — seul "Étudier un nouveau
  /// bien" permet d'en évaluer un autre, pour qu'analyser un bien différent
  /// consomme bien un nouvel essai gratuit plutôt que de détourner
  /// discrètement le même bien enregistré.
  ///
  /// Rendu volontairement très visible (fond/bordure teintés, titre en
  /// gras, bouton pleine largeur) — signalé par l'utilisateur : l'ancien
  /// bandeau discret ne distinguait pas assez ce bouton de "Mettre à jour
  /// ce bien" tout en bas de la page, deux actions aux effets opposés
  /// (créer un AUTRE bien vs modifier CELUI-CI) trop faciles à confondre.
  Widget _newPropertyBanner(RendementState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock_outline, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tu modifies un bien déjà enregistré',
              style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          "Pour enregistrer tes changements SUR CE bien : utilise \"Mettre à jour ce bien\" tout en bas de la page.\n"
          "Pour étudier un AUTRE bien sans toucher à celui-ci : utilise le bouton ci-dessous — localisation, prix, "
          "surface et type se déverrouillent pour un nouveau calcul.",
          style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.7)).copyWith(height: 1.45),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmNewProperty(context, state),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Étudier un nouveau bien'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  /// Avertit avant de perdre un calcul non enregistré (`state.formDirty`)
  /// — même logique que `BiensScreen._openForEditing`.
  Future<void> _confirmNewProperty(BuildContext context, RendementState state) async {
    if (state.formDirty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.paper,
          title: Text('Calcul non enregistré', style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
          content: Text(
            "Tu as des modifications non enregistrées sur ce bien — commencer un nouveau bien les remplacera, tu les perdras.",
            style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Continuer sans enregistrer', style: TextStyle(color: AppColors.alert)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    state.startNewProperty();
  }

  /// Blocs de l'onglet "Bien" — voir `kTabSections[AppTab.calc]` et
  /// `SectionCustomizationScreen`. 'stress_test' et 'seuils_rentabilite'
  /// restent filtrés par niveau ici, quel que soit l'ordre/la visibilité
  /// choisis par l'utilisateur (voir `tab_sections.dart`) ;
  /// 'resultats'/'comparatif'/'stress_test'/'seuils_rentabilite' restent
  /// verrouillés (voir `_sectionResultats`) tant que ce bien n'a jamais été
  /// enregistré.
  List<Widget> _buildSection(String id, RendementState state, bool isNovice) {
    switch (id) {
      case 'bien':
        return [_sectionBien(state)];
      case 'revenus':
        return [_sectionRevenus(state)];
      case 'financement':
        return [_sectionFinancement(state)];
      case 'capacite':
        return [_sectionCapacite(state)];
      case 'resultats':
        return [_sectionResultats(state)];
      case 'comparatif':
        return state.identityLocked ? [_sectionComparatif(state)] : const [];
      case 'stress_test':
        return isNovice || !state.identityLocked ? const [] : [KeyedSubtree(key: _stressTestKey, child: _sectionStressTest(state))];
      case 'seuils_rentabilite':
        return state.niveau != NiveauMode.experimente || !state.identityLocked ? const [] : [_sectionSeuils(state)];
      case 'save':
        return [_sectionSave(state)];
      case 'export':
        return [_sectionExport(state)];
      default:
        return const [];
    }
  }

  Widget _sectionBien(RendementState state) {
    final form = state.form;
    final isNovice = state.niveau == NiveauMode.debutant;
    void set(PropertyInput Function(PropertyInput f) updater) => state.updateForm(updater);

    // "Le bien" reste 3 groupes distincts (Informations générales /
    // Caractéristiques du bien / Prix et travaux), chacun désormais posé
    // sur une carte légère (fond surface, ombre très discrète, pas de
    // bordure) plutôt que simplement séparé par de l'espace — repris de la
    // nouvelle maquette de référence. Un essai précédent de "cartes" plus
    // marquées (bordure visible) n'avait pas plu à l'utilisateur ; celle-ci
    // reste volontairement sobre (voir `_card`).
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(children: [
      SectionTitle(
        'Informations générales',
        icon: Icons.badge_outlined,
        color: const Color(0xFF7C6FE0),
        // 2 champs à remplir ici : le nom et la localisation (la checklist
        // de visite, juste en dessous, est un outil à part, pas un champ du
        // bien). `commune` pointe vers le même objet `const` tant que le
        // picker n'a jamais été utilisé : toute sélection (même "Nantes" à
        // nouveau) crée une nouvelle instance, détectée par cette
        // comparaison de référence.
        progress: (
          _countDiff([
            form.nom.trim().isNotEmpty,
            form.commune != PropertyInput.defaultForm().commune,
          ]),
          2
        ),
      ),
      _blockLabel('Nom du bien'),
      const SizedBox(height: 8),
      SyncedTextField(
        value: form.nom,
        onChanged: (v) => set((f) => f.copyWith(nom: v)),
        decoration: InputDecoration(
          hintText: 'ex. T2 Rue des Lilas',
          hintStyle: AppTextStyles.sans(fontSize: 15, color: AppColors.ink.withValues(alpha: 0.45)),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
        ),
        style: AppTextStyles.sans(fontSize: 15, color: AppColors.ink),
      ),
      const SizedBox(height: 26),
      // Localisation — juste après le nom : c'est elle qui détermine les
      // repères de prix/marché affichés dans l'onglet "Marché" (regroupée
      // ici avec "Le bien" plutôt qu'en bloc séparé, à la demande de
      // l'utilisateur).
      _blockLabel('Localisation'),
      const SizedBox(height: 4),
      Text("Recherche n'importe quelle commune de France",
          style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
      const SizedBox(height: 8),
      AbsorbPointer(
        absorbing: state.identityLocked,
        child: Opacity(opacity: state.identityLocked ? 0.55 : 1, child: const CommunePicker()),
      ),
      const SizedBox(height: 26),
      // Checklist de visite
      _blockLabel('Quoi vérifier pendant la visite du bien'),
      const SizedBox(height: 8),
      InkWell(
        onTap: () => setState(() => _showVisite = !_showVisite),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          // paperSecondary (pas surface) : ce bloc est désormais niché dans
          // la carte "Informations générales", elle-même en surface — sans
          // ça, il s'y fondait complètement, seule sa bordure le distinguait.
          decoration: BoxDecoration(
            color: AppColors.paperSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.fact_check_outlined, size: 15, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Checklist de visite',
                    style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
              ]),
              Icon(_showVisite ? Icons.expand_less : Icons.expand_more, color: AppColors.ink.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
      if (_showVisite)
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.paperSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(checklistVisite.length, (i) {
              final checked = _visiteChecked.contains(i);
              return InkWell(
                onTap: () => setState(() => checked ? _visiteChecked.remove(i) : _visiteChecked.add(i)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: checked ? AppColors.accent : Colors.transparent,
                          border: Border.all(color: checked ? AppColors.accent : AppColors.border),
                        ),
                        child: checked ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          checklistVisite[i],
                          style: AppTextStyles.sans(
                            fontSize: 12.5,
                            color: AppColors.ink.withValues(alpha: checked ? 0.4 : 1),
                            decoration: checked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      SectionCard(children: [
      const SectionTitle('Caractéristiques du bien', icon: Icons.home_work_outlined, color: Color(0xFF4A9B6E)),
      ModeToggle(mode: form.mode, onChanged: (m) => set((f) => f.copyWith(mode: m))),
      const SizedBox(height: 26),
      _blockLabel('Typologie'),
      const SizedBox(height: 8),
      Opacity(
        opacity: state.identityLocked ? 0.55 : 1,
        child: Row(
        children: typologies.map((t) {
          final active = form.typeBien == t.id;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: state.identityLocked ? null : () => set((f) => f.copyWith(typeBien: t.id, capacite: t.capaciteDefaut.toDouble())),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: active ? AppColors.accent : AppColors.border),
                    boxShadow: active ? AppShadows.sm : null,
                  ),
                  child: Text(t.label,
                      style: AppTextStyles.sans(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? Colors.white : AppColors.textMuted)),
                ),
              ),
            ),
          );
        }).toList(),
        ),
      ),
      if (form.mode == RentalMode.longue) ...[
        const SizedBox(height: 26),
        _blockLabel('Location'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => set((f) => f.copyWith(meuble: false)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !form.meuble ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(AppRadius.sm)),
                  border: Border.all(color: !form.meuble ? AppColors.accent : AppColors.border),
                  boxShadow: !form.meuble ? AppShadows.sm : null,
                ),
                child: Text('Nu',
                    style: AppTextStyles.sans(fontSize: 12, fontWeight: !form.meuble ? FontWeight.w600 : FontWeight.w500, color: !form.meuble ? Colors.white : AppColors.textMuted)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => set((f) => f.copyWith(meuble: true)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: form.meuble ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.sm)),
                  border: Border.all(color: form.meuble ? AppColors.accent : AppColors.border),
                  boxShadow: form.meuble ? AppShadows.sm : null,
                ),
                child: Text('Meublé',
                    style: AppTextStyles.sans(fontSize: 12, fontWeight: form.meuble ? FontWeight.w600 : FontWeight.w500, color: form.meuble ? Colors.white : AppColors.textMuted)),
              ),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            form.meuble
                ? 'Détermine les régimes fiscaux éligibles (LMNP micro-BIC / réel) dans l\'onglet Fiscalité.'
                : 'Détermine les régimes fiscaux éligibles (micro-foncier / réel foncier) dans l\'onglet Fiscalité.',
            style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
          ),
        ),
      ],
      const SizedBox(height: 26),
      NumberField(label: "Capacité d'accueil", value: form.capacite, suffix: 'pers.', hint: 'utile surtout en courte durée', onChanged: (v) => set((f) => f.copyWith(capacite: v))),
      const SizedBox(height: 26),
      _blockLabel('Diagnostic de performance énergétique (DPE)'),
      const SizedBox(height: 8),
      Row(
        children: dpeInfo.keys.map((letter) {
          final info = dpeInfo[letter]!;
          final color = colorFromHex(info.colorHex);
          final active = form.dpe == letter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => set((f) => f.copyWith(dpe: letter)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? color : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Text(letter, style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.bold, color: active ? Colors.white : color)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      if (dpeInfo[form.dpe]?.banIssue != null)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.alert)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${dpeInfo[form.dpe]!.banIssue}. Vérifie si des travaux de rénovation énergétique sont nécessaires avant de pouvoir louer.',
                  style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.alert)),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 20),
      SectionCard(children: [
      SectionTitle(
        'Prix et travaux',
        icon: Icons.payments_outlined,
        color: const Color(0xFF3B82C4),
        // "Frais de notaire"/"Travaux" ne comptent dans le total que
        // lorsqu'ils sont réellement affichés (repliés par défaut en mode
        // novice) — sinon le total resterait figé à 2 alors que 4 cases
        // sont visibles à l'écran une fois dépliées. Toujours comptés
        // remplis quand visibles : auto-calculés à partir de prix/surface
        // (voir `notaireAuto`/`travauxAuto`), pas des champs qu'on "oublie"
        // indépendamment.
        progress: (
          _countDiff([
            form.prix != PropertyInput.defaultForm().prix,
            form.surface != PropertyInput.defaultForm().surface,
          ]) +
              (!isNovice || _showFraisAnnexes ? 2 : 0),
          !isNovice || _showFraisAnnexes ? 4 : 2
        ),
      ),
      AbsorbPointer(
        absorbing: state.identityLocked,
        child: Opacity(
          opacity: state.identityLocked ? 0.55 : 1,
          child: Row(children: [
            Expanded(
              child: NumberField(
                label: "Prix d'achat",
                value: form.prix,
                suffix: '€',
                // Tant que les frais de notaire n'ont pas été ajustés à la
                // main, ils suivent automatiquement le prix (voir
                // `notaireAuto`).
                onChanged: (v) => set((f) => f.copyWith(prix: v, notaire: f.notaireAuto ? defaultNotaire(v, pct: f.notairePct) : null)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumberField(
                label: 'Surface',
                value: form.surface,
                suffix: 'm²',
                onChanged: (v) => set((f) => f.copyWith(surface: v, travaux: f.travauxAuto ? defaultTravaux(v) : null)),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 26),
      if (isNovice) ...[
        // En novice, ces deux champs restent inclus dans le calcul avec
        // une estimation raisonnable par défaut — repliés pour ne pas
        // surcharger l'écran, dépliables si besoin d'un chiffre précis.
        InkWell(
          onTap: () => setState(() => _showFraisAnnexes = !_showFraisAnnexes),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Text(
                  'Frais de notaire et travaux — ${eur(form.notaire + form.travaux)} inclus par défaut',
                  style: AppTextStyles.sans(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.8)),
                ),
              ),
              Icon(_showFraisAnnexes ? Icons.expand_less : Icons.expand_more, size: 18, color: AppColors.ink.withValues(alpha: 0.5)),
            ]),
          ),
        ),
        if (_showFraisAnnexes) ...[
          const SizedBox(height: 8),
          _fraisAnnexesFields(form, set),
          const Tip('Une estimation raisonnable est déjà incluse dans le calcul (8 % de frais de notaire dans l\'ancien, 300 €/m² de travaux pour un rafraîchissement) — ajuste seulement si tu as un chiffre plus précis.'),
        ],
      ] else
        _fraisAnnexesFields(form, set),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  /// Intitulé de bloc pour l'onglet "Bien" — police serif (celle des
  /// titres de section) et taille légèrement plus grande que le texte
  /// courant, couleur ink comme le reste (pas d'accent) : la couleur
  /// accent testée précédemment ne convenait pas à l'utilisateur, qui a
  /// préféré miser sur la typographie plutôt que la couleur pour
  /// distinguer chaque bloc d'un coup d'œil.
  Widget _blockLabel(String text) {
    return Text(text, style: AppTextStyles.serif(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink));
  }

  Widget _sectionRevenus(RendementState state) {
    final form = state.form;
    final core = state.core;
    final isNovice = state.niveau == NiveauMode.debutant;
    void set(PropertyInput Function(PropertyInput f) updater) => state.updateForm(updater);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(children: [
      SectionTitle(
        'Revenus & charges',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF2FA39B),
        // Le total compte TOUS les champs visibles de l'encart (6 en longue
        // durée, 12 en courte) — doit correspondre exactement au nombre de
        // cases réellement affichées à l'écran, signalé par l'utilisateur
        // comme incohérent quand ce n'était pas le cas. "Frais de gestion"
        // est compté dans le total (c'est bien une case visible) mais
        // toujours considéré rempli : son défaut est 0, une réponse
        // légitime (bien géré soi-même) qu'exiger différente pénaliserait
        // à tort.
        progress: form.mode == RentalMode.longue
            ? (
                _countDiff([
                  form.loyer != PropertyInput.defaultForm().loyer,
                  form.vacancePct != PropertyInput.defaultForm().vacancePct,
                  form.chargesCopro != PropertyInput.defaultForm().chargesCopro,
                  form.taxeFonciere != PropertyInput.defaultForm().taxeFonciere,
                  form.assurance != PropertyInput.defaultForm().assurance,
                ]) +
                    1, // + "Frais de gestion", toujours compté rempli
                6
              )
            : (
                _countDiff([
                  form.prixNuitBasse != PropertyInput.defaultForm().prixNuitBasse,
                  form.prixNuitHaute != PropertyInput.defaultForm().prixNuitHaute,
                  form.nuitsBasseSaison != PropertyInput.defaultForm().nuitsBasseSaison,
                  form.nuitsHauteSaison != PropertyInput.defaultForm().nuitsHauteSaison,
                  form.dureeSejourMoyenne != PropertyInput.defaultForm().dureeSejourMoyenne,
                  form.commissionPct != PropertyInput.defaultForm().commissionPct,
                  form.menagePartReservation != PropertyInput.defaultForm().menagePartReservation,
                  form.ameublementAnnuel != PropertyInput.defaultForm().ameublementAnnuel,
                  form.abonnements != PropertyInput.defaultForm().abonnements,
                  form.taxeSejour != PropertyInput.defaultForm().taxeSejour,
                  form.taxeFonciere != PropertyInput.defaultForm().taxeFonciere,
                  form.assurance != PropertyInput.defaultForm().assurance,
                ]),
                12
              ),
      ),
      if (form.mode == RentalMode.longue) ...[
        Row(children: [
          Expanded(child: NumberField(label: 'Loyer mensuel', value: form.loyer, suffix: '€', onChanged: (v) => set((f) => f.copyWith(loyer: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(
            label: 'Vacance locative',
            value: form.vacancePct,
            suffix: '%',
            glossaryDefinition: 'Part de l\'année où le logement reste sans locataire entre deux baux (recherche, travaux, période creuse). Compte 4 à 8 % par sécurité, même si tu penses louer facilement.',
            onChanged: (v) => set((f) => f.copyWith(vacancePct: v)),
          )),
        ]),
        if (isNovice) const Tip('La "vacance locative" représente les mois sans locataire entre deux baux. Compte 4 à 8 % par sécurité, même si tu penses louer facilement.'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumberField(label: 'Charges copro / an', value: form.chargesCopro, suffix: '€', onChanged: (v) => set((f) => f.copyWith(chargesCopro: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Frais de gestion / an', value: form.gestion, suffix: '€', onChanged: (v) => set((f) => f.copyWith(gestion: v)))),
        ]),
      ] else ...[
        Text('Tarifs par saison', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.6))),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: NumberField(label: 'Prix / nuit — basse saison', value: form.prixNuitBasse, suffix: '€', onChanged: (v) => set((f) => f.copyWith(prixNuitBasse: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Nuits occupées — basse saison', value: form.nuitsBasseSaison.toDouble(), suffix: '/an', onChanged: (v) => set((f) => f.copyWith(nuitsBasseSaison: v.round())))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumberField(label: 'Prix / nuit — haute saison', value: form.prixNuitHaute, suffix: '€', onChanged: (v) => set((f) => f.copyWith(prixNuitHaute: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Nuits occupées — haute saison', value: form.nuitsHauteSaison.toDouble(), suffix: '/an', onChanged: (v) => set((f) => f.copyWith(nuitsHauteSaison: v.round())))),
        ]),
        if (isNovice) const Tip("Découpe l'année en deux périodes types (ex. été/hiver, vacances/reste de l'année) pour un calcul plus réaliste qu'un prix moyen unique."),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          // paperSecondary (pas surface) : niché dans la carte "Revenus &
          // charges", elle-même en surface.
          decoration: BoxDecoration(color: AppColors.paperSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statMini('Occupation', '${fmt(core.tauxOccupation, 0)}%', AppColors.accent),
              Container(width: 1, height: 32, color: AppColors.border),
              _statMini('Nuits/an', fmt(core.nuitsTotal, 0), AppColors.ink),
              Container(width: 1, height: 32, color: AppColors.border),
              _statMini('Réservations/an', fmt(core.nombreReservations, 0), AppColors.ink),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Séjours & frais', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink.withValues(alpha: 0.6))),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: NumberField(label: "Durée moyenne d'un séjour", value: form.dureeSejourMoyenne, suffix: 'nuits', onChanged: (v) => set((f) => f.copyWith(dureeSejourMoyenne: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Ménage par réservation', value: form.menagePartReservation, suffix: '€', onChanged: (v) => set((f) => f.copyWith(menagePartReservation: v)))),
        ]),
        if (isNovice) const Tip('Le ménage se paie à chaque changement de voyageur, pas une fois par an — plus les séjours sont courts, plus il y a de ménages à financer.'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumberField(label: 'Commission plateforme', value: form.commissionPct, suffix: '%', onChanged: (v) => set((f) => f.copyWith(commissionPct: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Renouvellement mobilier/linge', value: form.ameublementAnnuel, suffix: '€/an', onChanged: (v) => set((f) => f.copyWith(ameublementAnnuel: v)))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: NumberField(label: 'Abonnements (élec, internet...)', value: form.abonnements, suffix: '€/an', onChanged: (v) => set((f) => f.copyWith(abonnements: v)))),
          const SizedBox(width: 12),
          Expanded(child: NumberField(label: 'Taxe de séjour', value: form.taxeSejour, suffix: '€/nuit', hint: 'collectée, reversée', onChanged: (v) => set((f) => f.copyWith(taxeSejour: v)))),
        ]),
        if (isNovice) const Tip('La taxe de séjour est payée par le voyageur et reversée à la commune — elle ne rentre ni dans tes revenus ni dans tes charges, c\'est juste un flux à transmettre.'),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: NumberField(label: 'Taxe foncière / an', value: form.taxeFonciere, suffix: '€', onChanged: (v) => set((f) => f.copyWith(taxeFonciere: v)))),
        const SizedBox(width: 12),
        Expanded(child: NumberField(
          label: 'Assurance PNO / an',
          value: form.assurance,
          suffix: '€',
          glossaryDefinition: 'PNO = Propriétaire Non Occupant. Couvre le logement (dégâts des eaux, incendie...) pendant qu\'il est loué ou vacant — distincte de l\'assurance habitation que souscrit le locataire.',
          onChanged: (v) => set((f) => f.copyWith(assurance: v)),
        )),
      ]),
      if (state.niveau == NiveauMode.experimente) _chargesAnnexesFields(form, set),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  /// Charges annexes avancées — mode Expérimenté uniquement, demandé par
  /// l'utilisateur : « pousser le mode avancé plus loin » avec de vraies
  /// charges qu'un investisseur aguerri budgète déjà, pas seulement plus de
  /// champs pour la forme. Toutes à 0 par défaut (voir `PropertyInput`),
  /// donc sans aucun effet sur le calcul tant qu'elles ne sont pas
  /// explicitement renseignées.
  Widget _chargesAnnexesFields(PropertyInput form, void Function(PropertyInput Function(PropertyInput f)) set) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      Container(height: 1, color: AppColors.border),
      const SizedBox(height: 16),
      Row(children: [
        Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text('Charges annexes avancées', style: AppTextStyles.serif(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: NumberField(
          label: 'Assurance loyers impayés (GLI)',
          value: form.assuranceGliPct,
          suffix: '%',
          glossaryDefinition: 'GLI = Garantie Loyers Impayés. Couvre les loyers non payés par le locataire — calculée ici en % du loyer annuel réellement perçu. Généralement entre 2 et 4 %.',
          onChanged: (v) => set((f) => f.copyWith(assuranceGliPct: v)),
        )),
        const SizedBox(width: 12),
        Expanded(child: NumberField(
          label: 'Provision gros travaux / an',
          value: form.provisionTravaux,
          suffix: '€',
          glossaryDefinition: 'Mets de côté chaque année pour les travaux lourds à venir (ravalement, toiture, chaudière collective...) plutôt que de les découvrir le jour venu.',
          onChanged: (v) => set((f) => f.copyWith(provisionTravaux: v)),
        )),
      ]),
      const SizedBox(height: 12),
      NumberField(
        label: 'CFE / an',
        value: form.cfe,
        suffix: '€',
        glossaryDefinition: 'Cotisation Foncière des Entreprises — due en location meublée (LMNP/LMP) dans la plupart des communes, sauf exonération la première année. Laisse à 0 si tu loues nu.',
        onChanged: (v) => set((f) => f.copyWith(cfe: v)),
      ),
    ]);
  }

  Widget _sectionFinancement(RendementState state) {
    final form = state.form;
    final core = state.core;
    void set(PropertyInput Function(PropertyInput f) updater) => state.updateForm(updater);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(children: [
      SectionTitle(
        'Financement',
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF5B6FD8),
        progress: (
          _countDiff([
            form.apport != PropertyInput.defaultForm().apport,
            form.tauxPct != PropertyInput.defaultForm().tauxPct,
            form.dureePretAns != PropertyInput.defaultForm().dureePretAns,
          ]),
          3
        ),
      ),
      NumberField(label: 'Apport personnel', value: form.apport, suffix: '€', onChanged: (v) => set((f) => f.copyWith(apport: v))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: NumberField(label: "Taux d'intérêt annuel", value: form.tauxPct, suffix: '%', onChanged: (v) => set((f) => f.copyWith(tauxPct: v)))),
        const SizedBox(width: 12),
        Expanded(child: NumberField(label: 'Durée du prêt', value: form.dureePretAns.toDouble(), suffix: 'ans', onChanged: (v) => set((f) => f.copyWith(dureePretAns: v.round())))),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        // paperSecondary (pas surface) : niché dans la carte "Financement".
        decoration: BoxDecoration(color: AppColors.paperSecondary, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _statBlock('Montant emprunté', eur(core.montantEmprunte), AppColors.ink)),
            Expanded(child: _statBlock('Mensualité calculée', eur(core.mensualite), AppColors.accent)),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Text(
            'Coût total du projet : ${eur(core.coutTotalProjet)}',
            style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'dont ${eur(core.interetsTotalPret)} d\'intérêts sur ${form.dureePretAns} ans de prêt',
            style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.55)),
          ),
        ]),
      ),
      const Tip(
        "Avant de signer, vérifie que le TAEG proposé reste sous le taux d'usure en vigueur (plafond légal, publié chaque trimestre par la Banque de France) — une banque n'a pas le droit de prêter au-dessus, même si l'offre te semble avantageuse.",
      ),
      const SizedBox(height: 12),
      if (state.niveau != NiveauMode.debutant) ...[
        const SectionTitle('Comparer des offres de prêt', icon: Icons.compare_arrows, color: Color(0xFFD4A72C)),
        ..._buildOffres(state, core),
      ],
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _sectionCapacite(RendementState state) {
    final form = state.form;
    final core = state.core;
    final isNovice = state.niveau == NiveauMode.debutant;
    void set(PropertyInput Function(PropertyInput f) updater) => state.updateForm(updater);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionCard(children: [
      SectionTitle(
        "Capacité d'emprunt",
        icon: Icons.speed_outlined,
        color: const Color(0xFFE0705C),
        // 2 champs visibles (revenus + autres crédits) : le total doit
        // compter les deux. "Autres crédits en cours" reste toujours
        // considéré rempli : son défaut est 0, une réponse légitime (pas
        // d'autre crédit) qu'exiger différente pénaliserait à tort.
        progress: (
          (form.revenuMensuelNet != PropertyInput.defaultForm().revenuMensuelNet ? 1 : 0) + 1,
          2
        ),
      ),
      if (isNovice) const Tip("On se base sur la règle des 35 % : la banque accepte rarement que tes mensualités (tous crédits compris) dépassent 35 % de tes revenus nets."),
      Row(children: [
        Expanded(child: NumberField(label: 'Revenus mensuels nets', value: form.revenuMensuelNet, suffix: '€', onChanged: (v) => set((f) => f.copyWith(revenuMensuelNet: v)))),
        const SizedBox(width: 12),
        Expanded(child: NumberField(label: 'Autres crédits en cours', value: form.chargesCreditExistantes, suffix: '€/mois', onChanged: (v) => set((f) => f.copyWith(chargesCreditExistantes: v)))),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        // paperSecondary (pas surface) : niché dans la carte "Capacité
        // d'emprunt" ; la bordure reste le repère "hors capacité" (alert).
        decoration: BoxDecoration(
          color: AppColors.paperSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: core.capaciteOk ? AppColors.border : AppColors.alert),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text('Mensualité max (35 % d\'endettement)', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
            ),
            const SizedBox(width: 8),
            Text(eur(core.mensualiteMax), style: AppTextStyles.mono(fontSize: 15, color: AppColors.ink)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(core.capaciteOk ? Icons.check : Icons.warning_amber_rounded, size: 14, color: core.capaciteOk ? AppColors.accent : AppColors.alert),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                core.capaciteOk ? "Ce projet rentre dans ta capacité d'emprunt" : 'Mensualité au-delà de ta capacité estimée',
                style: AppTextStyles.sans(fontSize: 12, color: core.capaciteOk ? AppColors.accent : AppColors.alert),
              ),
            ),
          ]),
        ]),
      ),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _sectionResultats(RendementState state) {
    final form = state.form;
    final core = state.core;
    final isNovice = state.niveau == NiveauMode.debutant;

    if (!state.identityLocked) return _sectionResultatsLocked();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.trending_up, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text('RENTABILITÉ NETTE', style: AppTextStyles.sans(fontSize: 11, color: Colors.white70, letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          DigitReadout(value: core.net, accent: const Color(0xFFEDE6D2)),
          Container(margin: const EdgeInsets.symmetric(vertical: 14), height: 1, color: Colors.white24),
          Row(children: [
            Expanded(child: _statBlockWhite('Brute', '${fmt(core.brut, 2)}%')),
            Expanded(child: _statBlockWhite('Mensualité', eur(core.mensualite))),
            Expanded(child: _statBlockWhite('Cash-flow /mois', '${core.cashflowMensuel >= 0 ? '+' : ''}${fmt(core.cashflowMensuel)} €',
                color: core.cashflowMensuel < 0 ? const Color(0xFFE8B4A4) : const Color(0xFFEDE6D2))),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      if (isNovice) VerdictCard(core: core, form: form),
      const SizedBox(height: 24),
    ]);
  }

  /// Tant que ce bien n'a jamais été enregistré — voir
  /// `RendementState.identityLocked`, mis à `true` par le premier
  /// enregistrement (ou en rouvrant un bien existant depuis "Comparer").
  Widget _sectionResultatsLocked() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock_outline, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Rentabilité verrouillée', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
        const SizedBox(height: 10),
        Text(
          "Enregistre ce bien pour voir sa rentabilité et le retrouver dans l'onglet Comparer.",
          style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 14),
        ArrivalBounce(
          child: ElevatedButton.icon(
            onPressed: widget.onSave,
            icon: const Icon(Icons.add),
            label: const Text('Enregistrer pour voir la rentabilité'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionComparatif(RendementState state) {
    final comparaison = state.comparaison;
    final isNovice = state.niveau == NiveauMode.debutant;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.repeat, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Longue durée vs courte durée', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _compareCard('Longue durée', comparaison.longue, comparaison.gagnant == RentalMode.longue)),
          const SizedBox(width: 12),
          Expanded(child: _compareCard('Courte durée', comparaison.courte, comparaison.gagnant == RentalMode.courte)),
        ]),
        const SizedBox(height: 10),
        Text(
          '${comparaison.gagnant == RentalMode.courte ? "La courte durée" : "La longue durée"} ressort environ ${fmt(comparaison.ecartPct.abs(), 0)}% plus rentable ici, à charges et prix identiques — calculé à partir des champs "Revenus & charges" des deux modes ci-dessus.',
          style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
        ),
        if (isNovice) const Tip('La courte durée demande plus de temps de gestion (ménage, accueil, calendrier) — un rendement plus élevé se paie souvent en implication personnelle.'),
      ]),
    );
  }

  // Accessible dès le mode Débutant (voir `_buildWizard`, étape "Le
  // verdict") — demandé par l'utilisateur : utile pour comprendre ce qui
  // peut arriver même sans maîtriser les chiffres, à condition de garder
  // l'esprit du mode Débutant (expliquer pourquoi et à quoi ça sert, pas
  // juste poser des curseurs). Le `Tip` d'introduction ci-dessous ne
  // s'affiche donc qu'en Débutant ; Intermédiaire/Expérimenté gardent le
  // même outil sans ce préambule, qu'ils n'ont plus besoin de lire à
  // chaque fois.
  Widget _sectionStressTest(RendementState state) {
    final form = state.form;
    final core = state.core;
    final isNovice = state.niveau == NiveauMode.debutant;

    final tauxDelta = _stressTaux ? _stressTauxPts : 0.0;
    final occDelta = _stressOccupation ? _stressOccupationPct : 0.0;
    final travauxDelta = _stressTravaux ? _stressTravauxEuros : 0.0;
    // Même pourcentage de "baisse d'occupation" appliqué de façon cohérente
    // aux deux modes : en longue durée sur le taux d'occupation déduit de
    // la vacance, en courte durée directement sur les nuits réservées.
    final stressForm = form.copyWith(
      tauxPct: form.tauxPct + tauxDelta,
      vacancePct: form.mode == RentalMode.longue
          ? (100 - (100 - form.vacancePct) * (1 - occDelta / 100)).clamp(0, 100).toDouble()
          : form.vacancePct,
      nuitsBasseSaison: form.mode == RentalMode.courte
          ? (form.nuitsBasseSaison * (1 - occDelta / 100)).round()
          : form.nuitsBasseSaison,
      nuitsHauteSaison: form.mode == RentalMode.courte
          ? (form.nuitsHauteSaison * (1 - occDelta / 100)).round()
          : form.nuitsHauteSaison,
      travaux: form.travaux + travauxDelta,
    );
    final stressCore = computeCore(stressForm);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isNovice)
          const Tip(
            "Personne ne peut prédire l'avenir : les taux peuvent monter, un locataire partir, des travaux imprévus arriver. "
            'Coche un ou plusieurs scénarios ci-dessous pour voir si ce bien resterait viable même dans ces cas-là, avant de te décider.',
          ),
        Row(children: [
          Icon(Icons.bolt, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Et si...? (stress-test)', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
        ]),
        const SizedBox(height: 10),
        _stressRow("Le taux d'emprunt monte de ${fmt(_stressTauxPts, 1)} point${_stressTauxPts > 1 ? 's' : ''}", _stressTaux, () => setState(() => _stressTaux = !_stressTaux)),
        if (_stressTaux)
          _stressAmountField(
            label: 'Points de taux en plus',
            value: _stressTauxPts,
            suffix: 'pt',
            onChanged: (v) => setState(() => _stressTauxPts = v.clamp(0, 10)),
          ),
        _stressRow("L'occupation baisse de ${fmt(_stressOccupationPct, 0)} %", _stressOccupation, () => setState(() => _stressOccupation = !_stressOccupation)),
        if (_stressOccupation)
          _stressAmountField(
            label: "Baisse d'occupation",
            value: _stressOccupationPct,
            suffix: '%',
            onChanged: (v) => setState(() => _stressOccupationPct = v.clamp(0, 100)),
          ),
        _stressRow('+ ${eur(_stressTravauxEuros)} de travaux imprévus', _stressTravaux, () => setState(() => _stressTravaux = !_stressTravaux)),
        if (_stressTravaux)
          _stressAmountField(
            label: 'Travaux imprévus en plus',
            value: _stressTravauxEuros,
            suffix: '€',
            onChanged: (v) => setState(() => _stressTravauxEuros = v.clamp(0, 500000)),
          ),
        if (_anyStress)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('RENTABILITÉ NETTE', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.65))),
                  Text('${fmt(core.net, 1)}% → ${fmt(stressCore.net, 1)}%', style: AppTextStyles.mono(fontSize: 14, color: AppColors.alert)),
                ]),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CASH-FLOW /MOIS', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.65))),
                  Text('${fmt(core.cashflowMensuel)}€ → ${fmt(stressCore.cashflowMensuel)}€',
                      style: AppTextStyles.mono(fontSize: 14, color: stressCore.cashflowMensuel < 0 ? AppColors.alert : AppColors.ink)),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }

  // Exclusif au mode Expérimenté : complète le stress-test manuel
  // ci-dessus (où l'utilisateur choisit lui-même l'ampleur du choc) par une
  // lecture automatique des marges de sécurité du dossier — jusqu'où
  // chaque paramètre peut se dégrader avant que le cash-flow passe sous
  // zéro, calculé par recherche binaire (voir `computeBreakeven`).
  Widget _sectionSeuils(RendementState state) {
    final form = state.form;
    final breakeven = computeBreakeven(form);
    final seuils = [breakeven.prixMax, breakeven.tauxMax, breakeven.baisseLoyerMaxPct, breakeven.baisseOccupationMaxPct];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.shield_outlined, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Seuils de rentabilité', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
        ]),
        const SizedBox(height: 4),
        Text(
          "Jusqu'où chaque paramètre peut se dégrader, toutes choses égales par ailleurs, avant que le cash-flow mensuel passe sous zéro.",
          style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 12),
        _seuilRow("Prix d'achat maximum", breakeven.prixMax == null ? null : eur(breakeven.prixMax!), current: 'actuellement ${eur(form.prix)}'),
        _seuilRow("Taux d'emprunt maximum", breakeven.tauxMax == null ? null : '${fmt(breakeven.tauxMax!, 2)} %', current: 'actuellement ${fmt(form.tauxPct, 2)} %'),
        _seuilRow('Baisse de loyer supportable', breakeven.baisseLoyerMaxPct == null ? null : '-${fmt(breakeven.baisseLoyerMaxPct!, 0)} %'),
        _seuilRow("Baisse d'occupation supportable", breakeven.baisseOccupationMaxPct == null ? null : '-${fmt(breakeven.baisseOccupationMaxPct!, 0)} %'),
        if (seuils.contains(null))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '— : déjà négatif à ce niveau, ou marge trop large pour être atteinte dans la plage testée.',
              style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
            ),
          ),
      ]),
    );
  }

  Widget _seuilRow(String label, String? value, {String? current}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7))),
            if (current != null)
              Text(current, style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.4))),
          ]),
        ),
        Text(
          value ?? '—',
          style: AppTextStyles.mono(fontSize: 13.5, color: value == null ? AppColors.ink.withValues(alpha: 0.35) : AppColors.accent),
        ),
      ]),
    );
  }

  Widget _sectionSave(RendementState state) {
    // Demandé par l'utilisateur après avoir eu du mal à retrouver le
    // stress-test/les seuils de rentabilité sur un bien déjà enregistré :
    // dire clairement, ici, que ces outils existent, où ils se trouvent et
    // comment y revenir — plutôt que de les laisser silencieusement
    // apparaître plus haut une fois le bien enregistré. Absent en
    // Débutant, qui n'a accès à aucun des deux (voir `_buildSection`).
    final avantages = switch (state.niveau) {
      NiveauMode.debutant => '',
      NiveauMode.intermediaire => " Tu pourras aussi le stress-tester (scénarios dégradés : taux, vacance, travaux imprévus) juste au-dessus, ou en le rouvrant plus tard depuis Comparer.",
      NiveauMode.experimente => " Tu pourras aussi le stress-tester et consulter ses seuils de rentabilité (jusqu'où le prix, le taux, le loyer ou l'occupation peuvent se dégrader) juste au-dessus, ou en le rouvrant plus tard depuis Comparer.",
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.layers_outlined, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Tu hésites entre plusieurs biens ? Une fois enregistré, celui-ci apparaît dans l'onglet Comparer, aux côtés de tes autres projets.$avantages",
              style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.75)),
            ),
          ),
        ]),
      ),
      // Avant le tout premier enregistrement (`editingId == null`), ce
      // bouton ferait strictement doublon avec celui de
      // `_sectionResultatsLocked` juste au-dessus ("Enregistrer pour voir
      // la rentabilité") — signalé par l'utilisateur : deux boutons
      // "Enregistrer" visibles en même temps sur la page. Une fois le bien
      // enregistré une première fois, ce bouton devient le seul moyen de
      // mettre à jour CE bien (voir aussi `_newPropertyBanner`), donc utile
      // à nouveau.
      if (state.editingId != null) ...[
        ArrivalBounce(
          active: state.formDirty,
          child: ElevatedButton.icon(
            onPressed: widget.onSave,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Mettre à jour ce bien'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (state.formDirty) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.circle, size: 6, color: AppColors.alert),
            const SizedBox(width: 6),
            Text('Modifications non enregistrées', style: AppTextStyles.sans(fontSize: 11, color: AppColors.alert)),
          ]),
        ],
        const SizedBox(height: 16),
      ],
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Calculs indicatifs à titre informatif. Consultez un professionnel (notaire, expert-comptable, courtier) avant toute décision d\'investissement.',
            style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
          ),
        ),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _sectionExport(RendementState state) {
    final canExport = state.savedFormId != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.picture_as_pdf_outlined, size: 15, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('Exporter en PDF', style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
          ]),
          const SizedBox(height: 6),
          Text(
            canExport
                ? "Génère un dossier PDF de ce bien — chiffres clés, régimes fiscaux et tableau d'amortissement — à garder, imprimer ou transmettre à une banque, un notaire ou un associé."
                : "Enregistre d'abord ce bien pour générer son PDF — il reflète toujours la dernière version enregistrée, pas un calcul en cours.",
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 12),
          ArrivalBounce(
            active: canExport,
            child: OutlinedButton.icon(
              onPressed: canExport ? () => _exportPdf(state) : null,
              icon: const Icon(Icons.ios_share, size: 15),
              label: const Text('Générer le PDF'),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }

  /// Champs "Frais de notaire" / "Travaux" — calculés automatiquement (8 %
  /// du prix dans l'ancien par défaut, 300 €/m²) tant que l'utilisateur ne
  /// les a pas modifiés à la main ; un lien permet de revenir au calcul
  /// auto après un ajustement.
  Widget _fraisAnnexesFields(PropertyInput form, void Function(PropertyInput Function(PropertyInput f) updater) set) {
    final anyManual = !form.notaireAuto || !form.travauxAuto;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: NumberField(
            label: 'Frais de notaire',
            value: form.notaire,
            suffix: '€',
            hint: form.notaireAuto ? '${form.notairePct.round()} % auto' : null,
            glossaryDefinition: 'Malgré leur nom, l\'essentiel revient à l\'État (droits de mutation) et aux collectivités, pas au notaire lui-même — environ 7-8 % du prix dans l\'ancien, 2-3 % dans le neuf.',
            onChanged: (v) => set((f) => f.copyWith(notaire: v, notaireAuto: false)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NumberField(
            label: 'Travaux',
            value: form.travaux,
            suffix: '€',
            hint: form.travauxAuto
                ? '${travauxDefaultParM2.round()} / ${travauxRenovationParM2.round()} / ${travauxRemiseANeufParM2.round()} €/m² auto'
                : null,
            glossaryDefinition: '${travauxDefaultParM2.round()} €/m² correspond à un simple rafraîchissement (peinture, sols...). '
                'À titre indicatif, compte plutôt ~${travauxRenovationParM2.round()} €/m² pour une rénovation (cuisine, salle de bain, électricité...), '
                'et ~${travauxRemiseANeufParM2.round()} €/m² pour une remise à neuf complète (tout refaire, gros œuvre inclus).',
            onChanged: (v) => set((f) => f.copyWith(travaux: v, travauxAuto: false)),
          ),
        ),
      ]),
      // Demandé par l'utilisateur : rester sur l'ancien (8 %) par défaut,
      // la plupart des projets portant sur de l'ancien — le bouton ne sert
      // qu'à basculer ponctuellement sur le neuf, jamais l'inverse.
      // N'a de sens que tant que le calcul reste automatique.
      if (form.notaireAuto)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Text('Base : ', style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5))),
            _notairePctChip(form, set, label: 'Ancien', pct: notaireDefaultPct),
            const SizedBox(width: 6),
            _notairePctChip(form, set, label: 'Neuf', pct: notaireNeufDefaultPct),
          ]),
        ),
      if (anyManual)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: () => set((f) => f.copyWith(
                  notaireAuto: true,
                  travauxAuto: true,
                  notaire: defaultNotaire(f.prix, pct: f.notairePct),
                  travaux: defaultTravaux(f.surface),
                )),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh, size: 13, color: AppColors.accent),
              const SizedBox(width: 4),
              Text('Revenir au calcul automatique', style: AppTextStyles.sans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.accent)),
            ]),
          ),
        ),
    ]);
  }

  Widget _notairePctChip(PropertyInput form, void Function(PropertyInput Function(PropertyInput f) updater) set, {required String label, required double pct}) {
    final active = form.notairePct == pct;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => set((f) => f.copyWith(notairePct: pct, notaire: defaultNotaire(f.prix, pct: pct))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.12) : AppColors.border,
          borderRadius: BorderRadius.circular(999),
          border: active ? Border.all(color: AppColors.accent.withValues(alpha: 0.4)) : null,
        ),
        child: Text('$label (${pct.round()} %)',
            style: AppTextStyles.sans(fontSize: 10, fontWeight: FontWeight.w600, color: active ? AppColors.accent : AppColors.ink.withValues(alpha: 0.6))),
      ),
    );
  }

  /// Ouvre l'aperçu natif d'impression/partage/enregistrement du PDF,
  /// disponible aussi bien sur le web (téléchargement) que sur Android
  /// (feuille de partage).
  Future<void> _exportPdf(RendementState state) async {
    try {
      await PdfExportService.exportBien(
        form: state.form,
        core: state.core,
        regimes: state.regimes,
        amortissement: state.amortissement,
        score: state.score,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'export PDF, réessaie dans un instant.")),
      );
    }
  }

  Widget _statMini(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.65))),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.mono(fontSize: 15, color: color)),
    ]);
  }

  Widget _statBlock(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.65))),
      const SizedBox(height: 4),
      Text(value, style: AppTextStyles.mono(fontSize: 16, color: color)),
    ]);
  }

  Widget _statBlockWhite(String label, String value, {Color color = const Color(0xFFEDE6D2)}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 10, color: Colors.white54)),
      const SizedBox(height: 3),
      Text(value, style: AppTextStyles.mono(fontSize: 15, color: color)),
    ]);
  }

  Widget _compareCard(String label, CoreResult c, bool isWinner) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.accent.withValues(alpha: 0.08) : AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isWinner ? AppColors.accent : AppColors.border, width: isWinner ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(label, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.7)))),
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999)),
              child: Text('+ rentable', style: AppTextStyles.sans(fontSize: 9, color: Colors.white)),
            ),
        ]),
        const SizedBox(height: 4),
        DigitReadout(value: c.net, size: ReadoutSize.sm, accent: isWinner ? AppColors.accent : AppColors.ink),
        const SizedBox(height: 4),
        Text('cash-flow ${c.cashflowMensuel >= 0 ? '+' : ''}${fmt(c.cashflowMensuel)} €/mois',
            style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45))),
      ]),
    );
  }

  Widget _stressRow(String label, bool checked, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: checked ? AppColors.alert : AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: checked ? AppColors.alert : AppColors.border, width: 1.5),
            ),
            child: checked ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink))),
        ]),
      ),
    );
  }

  Widget _stressAmountField({
    required String label,
    required double value,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 10),
      child: SizedBox(
        width: 160,
        child: NumberField(label: label, value: value, suffix: suffix, onChanged: onChanged),
      ),
    );
  }

  List<Widget> _buildOffres(RendementState state, CoreResult core) {
    final form = state.form;
    final results = form.offres.map((o) => computeOffre(o, core.montantEmprunte)).toList();
    final minCost = results.isEmpty ? 0.0 : results.map((r) => r.coutTotal).reduce((a, b) => a < b ? a : b);

    final widgets = <Widget>[];
    for (var idx = 0; idx < form.offres.length; idx++) {
      final offre = form.offres[idx];
      final c = results[idx];
      final isBest = form.offres.length > 1 && c.coutTotal == minCost;
      void updateOffre(LoanOffer Function(LoanOffer o) updater) {
        state.updateForm((f) => f.copyWith(
              offres: [for (var i = 0; i < f.offres.length; i++) i == idx ? updater(f.offres[i]) : f.offres[i]],
            ));
      }

      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // paperSecondary (pas surface) : nichée dans la carte "Financement".
          color: AppColors.paperSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isBest ? AppColors.accent : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: SyncedTextField(
                value: offre.nom,
                onChanged: (v) => updateOffre((o) => o.copyWith(nom: v)),
                style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
              ),
            ),
            if (isBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Text('Moins cher', style: AppTextStyles.sans(fontSize: 10, color: AppColors.accent)),
              ),
            IconButton(
              onPressed: () => state.updateForm((f) => f.copyWith(offres: [for (var i = 0; i < f.offres.length; i++) if (i != idx) f.offres[i]])),
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.ink.withValues(alpha: 0.3),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 10),
          // 2 champs par ligne (pas 3) : avec le badge de suffixe ("%",
          // "ans"), 3 champs sur une ligne ne laissaient presque plus de
          // place pour le chiffre lui-même sur un écran de téléphone — il
          // défilait hors de vue derrière le badge pendant la saisie,
          // illisible (signalé par l'utilisateur, capture à l'appui).
          Row(children: [
            Expanded(child: NumberField(label: 'Taux', value: offre.tauxPct, suffix: '%', onChanged: (v) => updateOffre((o) => o.copyWith(tauxPct: v)))),
            const SizedBox(width: 8),
            Expanded(child: NumberField(label: 'Durée', value: offre.dureePretAns.toDouble(), suffix: 'ans', onChanged: (v) => updateOffre((o) => o.copyWith(dureePretAns: v.round())))),
          ]),
          const SizedBox(height: 10),
          NumberField(label: 'Assurance', value: offre.assurancePct, suffix: '%', onChanged: (v) => updateOffre((o) => o.copyWith(assurancePct: v))),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Mensualité tot. : ', style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
              TextSpan(text: eur(c.mensualiteTotale), style: AppTextStyles.mono(fontSize: 12, color: AppColors.ink)),
            ])),
            const SizedBox(height: 4),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Coût total du crédit (intérêts + assurance) : ', style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6))),
              TextSpan(text: eur(c.coutTotal), style: AppTextStyles.mono(fontSize: 12, color: isBest ? AppColors.accent : AppColors.ink)),
            ])),
          ]),
        ]),
      ));
    }
    if (form.offres.length < 3) {
      widgets.add(OutlinedButton(
        onPressed: () => state.updateForm((f) => f.copyWith(offres: [
              ...f.offres,
              LoanOffer(
                id: DateTime.now().millisecondsSinceEpoch,
                nom: 'Banque ${String.fromCharCode(65 + f.offres.length)}',
                tauxPct: 3.8,
                dureePretAns: 20,
                assurancePct: 0.3,
              ),
            ])),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.border, style: BorderStyle.solid),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('+ Ajouter une offre'),
      ));
    }
    return widgets;
  }

  // ---------------------------------------------------------------------
  // Mode Débutant — assistant pas-à-pas
  // ---------------------------------------------------------------------

  /// Assistant pas-à-pas du mode Débutant — demandé par l'utilisateur :
  /// une vraie différence avec les deux autres profils, pas juste quelques
  /// champs masqués. Reprend EXACTEMENT les mêmes blocs de saisie que la
  /// liste classique (`_sectionBien`, `_sectionRevenus`...), un seul à la
  /// fois, avec une courte explication de l'étape en plus des conseils
  /// ("Tip") déjà prévus pour ce niveau (voir leurs `if (isNovice) ...`,
  /// désormais vrais tant que `niveau == debutant`). Le calcul et
  /// l'enregistrement restent strictement identiques aux autres profils —
  /// seule la présentation change.
  Widget _buildWizard(RendementState state) {
    // Les titres d'étape sont volontairement différents des titres de
    // section affichés juste en dessous (ex. "Financement" existe déjà
    // comme SectionTitle dans `_sectionFinancement`) — pas de doublon de
    // texte à l'écran.
    final steps = <({String title, String intro, Widget Function() build})>[
      (
        title: 'Le bien que tu étudies',
        intro: "Commence par décrire le bien que tu étudies : où il se trouve, son type, son prix. "
            "Tu pourras toujours revenir modifier cette étape avant d'enregistrer.",
        build: () => _sectionBien(state),
      ),
      (
        title: 'Ce que ça rapporte, ce que ça coûte',
        intro: "Combien ce bien peut rapporter chaque mois, et ce qu'il coûte à faire tourner "
            "(copropriété, taxe foncière, assurance...).",
        build: () => _sectionRevenus(state),
      ),
      (
        title: 'Comment tu le finances',
        intro: "Comment tu comptes financer l'achat — apport, prêt — et si la mensualité reste dans "
            "ce que les banques acceptent généralement de t'accorder.",
        build: () => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sectionFinancement(state),
          _sectionCapacite(state),
        ]),
      ),
      (
        title: 'Le verdict',
        intro: "Voici ce que ce bien donnerait, chiffres à l'appui — et ce qu'il faudrait surveiller "
            "avant de te décider.",
        build: () => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _sectionResultats(state),
          if (state.identityLocked) _resultsExplainer(state.core),
          if (state.identityLocked) KeyedSubtree(key: _stressTestKey, child: _sectionStressTest(state)),
          _sectionSave(state),
        ]),
      ),
    ];
    final step = _wizardStep.clamp(0, steps.length - 1);

    return Column(children: [
      _wizardProgress(steps.length, step),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (state.identityLocked) _newPropertyBanner(state),
            Text(steps[step].title, style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(
              steps[step].intro,
              style: AppTextStyles.sans(fontSize: 13.5, color: AppColors.ink.withValues(alpha: 0.65)).copyWith(height: 1.45),
            ),
            const SizedBox(height: 20),
            steps[step].build(),
          ],
        ),
      ),
      _wizardNav(step, steps.length),
    ]);
  }

  /// Fil de progression en haut de l'assistant — chaque pastille est
  /// cliquable pour revenir en arrière sans perdre ce qui est déjà saisi
  /// (rien n'est jamais perdu en changeant d'étape, seul "Enregistrer"
  /// compte vraiment).
  Widget _wizardProgress(int total, int step) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(color: AppColors.paper, border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i <= step ? AppColors.accent : AppColors.border,
              ),
            ),
          GestureDetector(
            onTap: () => setState(() => _wizardStep = i),
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= step ? AppColors.accent : AppColors.surface,
                border: Border.all(color: i <= step ? AppColors.accent : AppColors.border, width: 1.5),
              ),
              child: i < step
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : Text(
                      '${i + 1}',
                      style: AppTextStyles.mono(fontSize: 12, fontWeight: FontWeight.w600, color: i == step ? Colors.white : AppColors.textMuted),
                    ),
            ),
          ),
        ],
      ]),
    );
  }

  /// Navigation bas de page — "Suivant" disparaît à la dernière étape : le
  /// bouton d'enregistrement de `_sectionResultats`/`_sectionSave` prend
  /// le relais, pas de doublon d'action.
  Widget _wizardNav(int step, int total) {
    final isLast = step == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(color: AppColors.paper, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        if (step > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _wizardStep--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Précédent'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        if (step > 0 && !isLast) const SizedBox(width: 12),
        if (!isLast)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _wizardStep++),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
      ]),
    );
  }

  /// Explique les 3 chiffres clés en mots simples, avec les montants réels
  /// de CE bien — demandé par l'utilisateur : la rentabilité/le cash-flow
  /// ne doivent pas rester une boîte noire pour un premier investisseur.
  /// Uniquement une fois le bien enregistré (`state.identityLocked`) : tant
  /// qu'il ne l'est pas, `_sectionResultats` masque déjà ces chiffres
  /// derrière `_sectionResultatsLocked`, pas la peine de les détailler.
  Widget _resultsExplainer(CoreResult core) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.calculate_outlined, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Comment ces chiffres sont calculés', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
        const SizedBox(height: 12),
        _explainRow(
          'Rentabilité brute',
          '${fmt(core.brut, 2)} %',
          'Les loyers que tu encaisserais sur une année (${eur(core.loyerAnnuelBrut)}), divisés par le prix total du '
              'projet (${eur(core.prixTotal)}) — sans compter les charges.',
        ),
        const SizedBox(height: 12),
        _explainRow(
          'Rentabilité nette',
          '${fmt(core.net, 2)} %',
          'Pareil, mais après avoir retiré les charges annuelles (${eur(core.chargesAnnuelles)}) — c\'est le chiffre '
              'le plus honnête pour comparer deux biens entre eux.',
        ),
        const SizedBox(height: 12),
        _explainRow(
          'Cash-flow mensuel',
          '${core.cashflowMensuel >= 0 ? '+' : ''}${fmt(core.cashflowMensuel)} €',
          core.cashflowMensuel >= 0
              ? 'Ce qu\'il te reste chaque mois une fois le crédit (${eur(core.mensualite)}) et les charges payés avec le loyer.'
              : 'Ce que tu devras ajouter de ta poche chaque mois une fois le crédit (${eur(core.mensualite)}) et les charges payés.',
        ),
      ]),
    );
  }

  Widget _explainRow(String label, String value, String explanation) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: AppTextStyles.sans(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink))),
        Text(value, style: AppTextStyles.mono(fontSize: 13, color: AppColors.accent)),
      ]),
      const SizedBox(height: 3),
      Text(explanation, style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.ink.withValues(alpha: 0.6)).copyWith(height: 1.4)),
    ]);
  }
}
