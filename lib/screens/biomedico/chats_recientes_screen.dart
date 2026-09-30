import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_colors.dart';
import 'chat_enfermeria_screen.dart';

// ═══════════════════════════════════════════════════════════════════════
//  CHATS RECIENTES — lista de conversaciones activas del biomédico
// ═══════════════════════════════════════════════════════════════════════
class ChatsRecientesScreen extends StatelessWidget {
  const ChatsRecientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Chat con Enfermería',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('incidencias')
            .where('tecnicoId', isEqualTo: uid)
            .where('estado', whereIn: ['Asignada', 'En Proceso'])
            .orderBy('fechaCreacion', descending: true)
            .limit(30)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No tienes conversaciones activas',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 8),
                  const Text(
                    'El chat se activa cuando aceptas una solicitud',
                    style:
                        TextStyle(color: AppColors.textLight, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data  = docs[i].data();
              final id    = docs[i].id;
              final equipo = data['equipoNombre'] ?? 'Equipo';
              final area   = data['equipoArea']   ?? '—';
              final estado = data['estado']        ?? '—';
              final enfermera = data['enfermeraNombre'] ?? 'Enfermería';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accent.withOpacity(0.15),
                  child: Text(
                    enfermera.isNotEmpty ? enfermera[0].toUpperCase() : 'E',
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(equipo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                subtitle: Text(
                    '$enfermera · $area',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(estado,
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatEnfermeriaScreen(
                      incidenciaId: id,
                      titulo: equipo,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
