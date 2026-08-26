import 'package:flutter/material.dart';
import '../../services/referral_service.dart';

/// Un seul écran, deux usages : partager/saisir un code de parrainage
/// (-10 % équivalent), ou saisir un code cadeau (accès gratuit).
class ReferralScreen extends StatefulWidget {
  final String uid;
  final String? myReferralCode;
  const ReferralScreen({super.key, required this.uid, this.myReferralCode});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _referral = ReferralService();
  final _parrainageController = TextEditingController();
  final _cadeauController = TextEditingController();
  String? _parrainageMessage;
  String? _cadeauMessage;
  bool _loadingParrainage = false;
  bool _loadingCadeau = false;

  Future<void> _applyParrainage() async {
    if (_parrainageController.text.trim().isEmpty) return;
    setState(() => _loadingParrainage = true);
    String? error;
    try {
      error = await _referral.applyReferralCode(_parrainageController.text);
    } catch (_) {
      error = "Une erreur est survenue, réessaie dans un instant.";
    }
    if (!mounted) return;
    setState(() {
      _loadingParrainage = false;
      _parrainageMessage = error ??
          'Code appliqué ! Ton bonus sera crédité à ton prochain abonnement.';
    });
  }

  Future<void> _applyCadeau() async {
    if (_cadeauController.text.trim().isEmpty) return;
    setState(() => _loadingCadeau = true);
    String? error;
    try {
      error =
          await _referral.redeemAccessCode(widget.uid, _cadeauController.text);
    } catch (_) {
      error = "Une erreur est survenue, réessaie dans un instant.";
    }
    if (!mounted) return;
    setState(() {
      _loadingCadeau = false;
      _cadeauMessage = error ?? 'App débloquée gratuitement, profite-en !';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Codes & parrainage')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.myReferralCode != null) ...[
            const Text('Ton code de parrainage',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0E6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.myReferralCode!,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Icon(Icons.share, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Partage-le : toi et ton filleul recevez chacun un bonus '
              "équivalent à -10% sur l'abonnement.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 28),
          ],
          const Text('J\'ai un code de parrainage',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _parrainageController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'DIDOU-XXXX',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadingParrainage ? null : _applyParrainage,
                child: const Text('Valider'),
              ),
            ],
          ),
          if (_parrainageMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_parrainageMessage!,
                  style: const TextStyle(fontSize: 12.5)),
            ),
          const SizedBox(height: 28),
          const Text('J\'ai un code cadeau',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cadeauController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Code reçu',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadingCadeau ? null : _applyCadeau,
                child: const Text('Valider'),
              ),
            ],
          ),
          if (_cadeauMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child:
                  Text(_cadeauMessage!, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}
