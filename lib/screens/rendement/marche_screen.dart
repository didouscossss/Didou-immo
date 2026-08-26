import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/calculations.dart';
import '../../utils/formatters.dart';
import '../../utils/geo_api.dart';
import '../../widgets/section_title.dart';
import '../../widgets/tip.dart';

/// Onglet "Marché" — équivalent de `MarcheScreen` du prototype.
class MarcheScreen extends StatefulWidget {
  const MarcheScreen({super.key});

  @override
  State<MarcheScreen> createState() => _MarcheScreenState();
}

enum _SearchStatus { idle, loading, ok, error }

class _MarcheScreenState extends State<MarcheScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _open = false;
  List<CommuneResult> _results = [];
  _SearchStatus _status = _SearchStatus.idle;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _open = true;
          _controller.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _status = _SearchStatus.idle;
      });
      return;
    }
    setState(() => _status = _SearchStatus.loading);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final outcome = await searchCommunes(query);
      if (!mounted) return;
      setState(() {
        if (outcome.ok) {
          _results = outcome.results;
          _status = _SearchStatus.ok;
        } else {
          _status = _SearchStatus.error;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RendementState>();
    final form = state.form;
    final core = state.core;
    final refInfo = state.refInfoAjuste;
    final refs = state.refs;
    final typology = state.typology;
    final score = state.score;
    final isNovice = state.niveau == NiveauMode.novice;
    final commune = form.commune;
    final ref = refInfo?.ref;

    final ecartPrix = (ref != null && core.prixM2 > 0) ? ((core.prixM2 - ref.prixM2) / ref.prixM2) * 100 : null;
    final ecartLoyer = (ref != null && core.loyerM2 > 0) ? ((core.loyerM2 - ref.loyerM2) / ref.loyerM2) * 100 : null;

    void selectCommune(CommuneResult c) {
      state.updateForm((f) => f.copyWith(
            commune: CommuneRef(
              nom: c.nom,
              codePostal: c.codesPostaux.isNotEmpty ? c.codesPostaux.first : '',
              departement: c.departementNom ?? '',
              population: c.population,
            ),
          ));
      setState(() => _open = false);
      _controller.clear();
      _focusNode.unfocus();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SectionTitle('Localisation & marché'),
        Text("Recherche n'importe quelle commune de France",
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 12),
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Icon(Icons.search, size: 15, color: AppColors.ink.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onQueryChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: !_open && commune != null
                          ? '${commune.nom}${commune.codePostal.isNotEmpty ? ' (${commune.codePostal})' : ''}'
                          : 'Ville, village, code postal...',
                      hintStyle: AppTextStyles.sans(fontSize: 14, color: AppColors.ink),
                    ),
                    style: AppTextStyles.sans(fontSize: 14, color: AppColors.ink),
                  ),
                ),
                if (_status == _SearchStatus.loading)
                  const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Icon(Icons.expand_more, size: 15, color: AppColors.ink.withValues(alpha: 0.4)),
              ]),
            ),
            if (_open)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: _buildDropdownContent(selectCommune),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Recherche officielle IGN/INSEE (geo.api.gouv.fr) — gratuite, sans clé, aucune ville n\'est codée en dur.',
            style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.4)),
          ),
        ),
        if (commune != null) ...[
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accent),
            Text(commune.nom, style: AppTextStyles.sans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
            Text(commune.departement, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
            if (ref?.tension == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                child: Text('Zone tendue possible', style: AppTextStyles.sans(fontSize: 10, color: AppColors.alert)),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _statCard('Prix repère / m²', eur(ref?.prixM2))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Loyer repère / m²', eur(ref?.loyerM2))),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              refInfo?.precise == true
                  ? 'Donnée rattachée directement à ${ref!.name}.'
                  : "Pas de moyenne fiable pour une commune de cette taille — repère basé sur ${ref?.name == 'Moyenne nationale' ? 'la moyenne nationale' : '${ref?.name}, la référence la plus proche'}. À vérifier avec un notaire local ou l'observatoire des loyers du secteur.",
              style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ton bien vs le repère', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink)),
              const SizedBox(height: 10),
              if (form.surface > 0) ...[
                _ecartRow('Prix/m² du bien : ${eur(core.prixM2)}', ecartPrix, invert: false),
                const SizedBox(height: 6),
                _ecartRow('Loyer/m² du bien : ${eur(core.loyerM2)}', ecartLoyer, invert: true),
              ] else
                Text('Renseigne la surface du bien dans l\'onglet "Bien" pour comparer.',
                    style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.45))),
            ]),
          ),
          if (refs != null && form.surface > 0)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('Repère par typologie — ${typology.label}', style: AppTextStyles.sans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink))),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_outline, size: 11, color: AppColors.ink.withValues(alpha: 0.45)),
                    const SizedBox(width: 3),
                    Text('${fmt(form.capacite, 0)} pers. max', style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45))),
                  ]),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('LOYER REPÈRE (LONGUE)', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.5))),
                        Text('${eur(refs.loyerMensuelRef)}/mois', style: AppTextStyles.mono(fontSize: 15, color: AppColors.ink)),
                        if (form.mode == RentalMode.longue)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('ton loyer : ${eur(form.loyer)}',
                                style: AppTextStyles.mono(fontSize: 10.5, color: form.loyer <= refs.loyerMensuelRef ? AppColors.accent : AppColors.alert)),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NUITÉE REPÈRE (COURTE)', style: AppTextStyles.sans(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.5))),
                        Text('${eur(refs.nuiteeRef)}/nuit', style: AppTextStyles.mono(fontSize: 15, color: AppColors.ink)),
                        if (form.mode == RentalMode.courte && (core.prixNuitMoyen ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('ta nuitée moy. : ${eur(core.prixNuitMoyen)}',
                                style: AppTextStyles.mono(fontSize: 10.5, color: (core.prixNuitMoyen ?? 0) <= refs.nuiteeRef ? AppColors.accent : AppColors.alert)),
                          ),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Repères ajustés selon la typologie (${typology.label}, coefficient indicatif) et la capacité d\'accueil déclarée — pas de moyenne réelle par village pour la courte durée, à confronter aux annonces comparables sur place.',
                  style: AppTextStyles.sans(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.45)),
                ),
              ]),
            ),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.ink, AppColors.accent]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
                child: Text('${score.score}', style: AppTextStyles.mono(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Score d'investissement", style: AppTextStyles.sans(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                  Text('${score.label} · basé sur rendement, cash-flow, prix marché, occupation',
                      style: AppTextStyles.sans(fontSize: 12, color: Colors.white70)),
                ]),
              ),
            ]),
            if (!isNovice) ...[
              Container(margin: const EdgeInsets.symmetric(vertical: 14), height: 1, color: Colors.white24),
              _scorePartRow('Rendement', score.parts.rendement, 40),
              _scorePartRow('Cash-flow', score.parts.cashflow, 25),
              _scorePartRow('Prix vs marché', score.parts.marche, 20),
              _scorePartRow('Occupation', score.parts.occupation, 15),
            ],
          ]),
        ),
        if (isNovice) const Tip("Un score au-dessus de 60 est généralement un bon signal. En dessous de 40, ce bien mérite d'être comparé avec d'autres avant de te décider."),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.info_outline, size: 13, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Repères de prix indicatifs et arrondis — vérifie les données locales réelles (notaires, observatoires des loyers) avant de décider.',
              style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildDropdownContent(void Function(CommuneResult) onSelect) {
    if (_status == _SearchStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Recherche indisponible pour le moment. Vérifie ta connexion réseau.',
          style: AppTextStyles.sans(fontSize: 11.5, color: AppColors.alert),
        ),
      );
    }
    if (_status == _SearchStatus.idle && _controller.text.trim().length < 2) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Tape au moins 2 lettres — n\'importe quel village compte.',
            style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.4))),
      );
    }
    if (_status == _SearchStatus.ok && _results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Aucune commune trouvée', style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.4))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final c = _results[i];
        return InkWell(
          onTap: () => onSelect(c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: c.nom, style: AppTextStyles.sans(fontSize: 13.5, color: AppColors.ink)),
                    TextSpan(
                        text: '  ${c.codesPostaux.isNotEmpty ? c.codesPostaux.first : ''} · ${c.departementNom ?? ''}',
                        style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
                  ]),
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 11, color: AppColors.ink.withValues(alpha: 0.4)),
                const SizedBox(width: 3),
                Text(fmt(c.population, 0), style: AppTextStyles.mono(fontSize: 10.5, color: AppColors.ink.withValues(alpha: 0.4))),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.mono(fontSize: 17, color: AppColors.ink)),
      ]),
    );
  }

  Widget _ecartRow(String label, double? ecart, {required bool invert}) {
    final positive = invert ? (ecart ?? 0) >= 0 : (ecart ?? 0) <= 0;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(label, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7)))),
      if (ecart != null)
        Text('${ecart > 0 ? '+' : ''}${fmt(ecart, 1)}%', style: AppTextStyles.mono(fontSize: 12.5, color: positive ? AppColors.accent : AppColors.alert)),
    ]);
  }

  Widget _scorePartRow(String label, double value, double max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: AppTextStyles.sans(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.7)))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value / max).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text('${fmt(value, 0)}/${fmt(max, 0)}',
              textAlign: TextAlign.right,
              style: AppTextStyles.mono(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
        ),
      ]),
    );
  }
}
