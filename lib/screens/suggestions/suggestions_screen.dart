import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/arrival_bounce.dart';

/// Petit formulaire "Proposer une amélioration" — écrit directement dans
/// Firestore (collection `suggestions`), consultable depuis la console
/// Firebase sans back-office à construire pour démarrer.
class SuggestionsScreen extends StatefulWidget {
  final String uid;
  const SuggestionsScreen({super.key, required this.uid});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _firestore = FirestoreService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await _firestore.submitSuggestion(
      widget.uid,
      _titleController.text.trim(),
      _bodyController.text.trim(),
    );
    setState(() {
      _sending = false;
      _sent = true;
      _titleController.clear();
      _bodyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proposer une amélioration')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Une idée pour améliorer l'app ? Décris-la ci-dessous.",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre court',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Détails (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ArrivalBounce(
              active: !_sending,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: Text(_sending ? 'Envoi...' : 'Envoyer la suggestion'),
              ),
            ),
            if (_sent)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Merci, ta suggestion a bien été envoyée !',
                    style: TextStyle(color: Colors.green)),
              ),
          ],
        ),
      ),
    );
  }
}
