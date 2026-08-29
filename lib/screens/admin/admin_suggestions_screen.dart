import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';

/// Liste des suggestions envoyées par les utilisateurs (voir
/// `SuggestionsScreen`), réservée aux comptes admin (voir
/// `firestore.rules` — `allow read, delete: if isAdmin()`).
class AdminSuggestionsScreen extends StatelessWidget {
  const AdminSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Suggestions')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.watchSuggestions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erreur de chargement : ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucune suggestion pour le moment.', style: TextStyle(color: Colors.black54)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final title = (data['title'] as String?)?.trim();
              final body = (data['body'] as String?)?.trim();
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(title?.isNotEmpty == true ? title! : '(sans titre)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () => _confirmDelete(context, firestore, doc.id),
                    ),
                  ]),
                  if (body?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(body!, style: const TextStyle(fontSize: 13)),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(dateFr(createdAt), style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, FirestoreService firestore, String suggestionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette suggestion ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await firestore.deleteSuggestion(suggestionId);
    }
  }
}
