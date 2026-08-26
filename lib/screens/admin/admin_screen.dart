import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/user_account_state.dart';

/// Génération de codes cadeaux (accès gratuit) — réservé aux comptes dont
/// le document Firestore `users/{uid}` porte `isAdmin: true`. Ce flag doit
/// être activé manuellement depuis la console Firebase : il n'existe pas
/// de compte admin par défaut.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _codeController = TextEditingController();
  final _usesController = TextEditingController(text: '1');
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    _usesController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final uses = int.tryParse(_usesController.text.trim()) ?? 1;
    setState(() {
      _loading = true;
      _message = null;
    });
    await context.read<UserAccountState>().createGiftCode(code, uses: uses);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = 'Code "$code" créé — utilisable $uses fois.';
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration — codes cadeaux')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Un code cadeau rend l'app gratuite à vie pour le compte qui l'utilise "
            "(bascule `grantedFree` sur son document Firestore).",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Code (ex. DIDOU-NOEL)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nombre d'utilisations", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _generate,
            child: Text(_loading ? 'Création...' : 'Générer le code'),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!, style: const TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }
}
