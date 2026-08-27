import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/rendement_state.dart';
import '../theme/app_theme.dart';
import '../utils/calculations.dart';
import '../utils/formatters.dart';
import '../utils/geo_api.dart';

/// Recherche + sélection de la commune du bien — extrait de l'onglet Marché
/// pour être utilisable directement dans l'onglet Bien (là où on saisit le
/// reste des caractéristiques du bien).
class CommunePicker extends StatefulWidget {
  const CommunePicker({super.key});

  @override
  State<CommunePicker> createState() => _CommunePickerState();
}

enum _SearchStatus { idle, loading, ok, error }

class _CommunePickerState extends State<CommunePicker> {
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
    final commune = state.form.commune;
    final ref = state.refInfoAjuste?.ref;

    void selectCommune(CommuneResult c) {
      state.updateForm((f) => f.copyWith(
            commune: CommuneRef(
              nom: c.nom,
              codePostal: c.codesPostaux.isNotEmpty ? c.codesPostaux.first : '',
              departement: c.departementNom ?? '',
              population: c.population,
              codeInsee: c.code,
              codeDepartement: c.departementCode ?? '',
            ),
          ));
      setState(() => _open = false);
      _controller.clear();
      _focusNode.unfocus();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              Icon(Icons.search, size: 15, color: const Color(0xFF16211C).withValues(alpha: 0.4)),
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
                    hintStyle: AppTextStyles.sans(fontSize: 14, color: const Color(0xFF16211C)),
                  ),
                  style: AppTextStyles.sans(fontSize: 14, color: const Color(0xFF16211C)),
                ),
              ),
              if (_status == _SearchStatus.loading)
                const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(Icons.expand_more, size: 15, color: const Color(0xFF16211C).withValues(alpha: 0.4)),
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
      if (commune != null)
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
          Icon(Icons.location_on_outlined, size: 14, color: AppColors.accent),
          Text(commune.nom, style: AppTextStyles.sans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
          Text(commune.departement, style: AppTextStyles.sans(fontSize: 11, color: AppColors.ink.withValues(alpha: 0.45))),
          if (ref?.tension == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.alert.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
              child: Text('Zone tendue possible', style: AppTextStyles.sans(fontSize: 10, color: AppColors.alert)),
            ),
        ]),
    ]);
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
            style: AppTextStyles.sans(fontSize: 12, color: const Color(0xFF16211C).withValues(alpha: 0.5))),
      );
    }
    if (_status == _SearchStatus.ok && _results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Aucune commune trouvée', style: AppTextStyles.sans(fontSize: 12, color: const Color(0xFF16211C).withValues(alpha: 0.5))),
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
                    TextSpan(text: c.nom, style: AppTextStyles.sans(fontSize: 13.5, color: const Color(0xFF16211C))),
                    TextSpan(
                        text: '  ${c.codesPostaux.isNotEmpty ? c.codesPostaux.first : ''} · ${c.departementNom ?? ''}',
                        style: AppTextStyles.sans(fontSize: 11, color: const Color(0xFF16211C).withValues(alpha: 0.55))),
                  ]),
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 11, color: const Color(0xFF16211C).withValues(alpha: 0.4)),
                const SizedBox(width: 3),
                Text(fmt(c.population, 0), style: AppTextStyles.mono(fontSize: 10.5, color: const Color(0xFF16211C).withValues(alpha: 0.5))),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
