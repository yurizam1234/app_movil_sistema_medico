import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../config/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════
//  CHAT CON ENFERMERÍA — TIEMPO REAL CON FIRESTORE
// ═══════════════════════════════════════════════════════════════════════
class ChatEnfermeriaScreen extends StatefulWidget {
  final String incidenciaId;
  final String titulo;

  const ChatEnfermeriaScreen({
    super.key,
    required this.incidenciaId,
    this.titulo = 'Chat Enfermería',
  });

  @override
  State<ChatEnfermeriaScreen> createState() => _ChatEnfermeriaScreenState();
}

class _ChatEnfermeriaScreenState extends State<ChatEnfermeriaScreen> {
  final _msgCtrl     = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _picker      = ImagePicker();
  bool _enviando     = false;

  String get _chatPath => 'chats/${widget.incidenciaId}/mensajes';
  String get _uid      => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Enviar mensaje de texto ─────────────────────────────────────
  Future<void> _enviarTexto() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty || _enviando) return;

    _msgCtrl.clear();
    setState(() => _enviando = true);

    await _guardarMensaje(texto: texto);
    setState(() => _enviando = false);
    _scrollAlFinal();
  }

  // ── Enviar imagen ───────────────────────────────────────────────
  Future<void> _enviarImagen(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 75, maxWidth: 1024);
    if (xfile == null) return;

    setState(() => _enviando = true);

    try {
      final file = File(xfile.path);
      final msgId = FirebaseFirestore.instance.collection(_chatPath).doc().id;
      final ref = FirebaseStorage.instance
          .ref('chats/${widget.incidenciaId}/$msgId.jpg');
      final task = await ref.putFile(
          file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();
      await _guardarMensaje(fotoUrl: url);
      _scrollAlFinal();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al enviar imagen'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }

    if (mounted) setState(() => _enviando = false);
  }

  Future<void> _guardarMensaje({String? texto, String? fotoUrl}) async {
    final ahora = DateTime.now();
    final user  = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection(_chatPath).add({
      'texto':         texto ?? '',
      'fotoUrl':       fotoUrl ?? '',
      'tipo':          fotoUrl != null ? 'imagen' : 'texto',
      'remitenteId':   _uid,
      'remitenteName': user?.displayName ?? 'Biomédico',
      'timestamp':     Timestamp.fromDate(ahora),
      'leido':         false,
    });

    // Marcar mensajes del otro como leídos
    await _marcarLeidos();
  }

  Future<void> _marcarLeidos() async {
    final snap = await FirebaseFirestore.instance
        .collection(_chatPath)
        .where('remitenteId', isNotEqualTo: _uid)
        .where('leido', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'leido': true});
    }
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white)),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _enviarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white)),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _enviarImagen(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('Chat con Enfermería',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Mensajes ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(_chatPath)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snap.data?.docs ?? [];

                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Inicia la conversación',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 15)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollAlFinal());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg   = msgs[i].data();
                    final esMio = msg['remitenteId'] == _uid;
                    final prev  = i > 0 ? msgs[i - 1].data() : null;
                    final mismoRemitente =
                        prev?['remitenteId'] == msg['remitenteId'];

                    return _BurbujaMensaje(
                      msg:             msg,
                      esMio:           esMio,
                      mostrarNombre:   !mismoRemitente,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input ─────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            color: Colors.white,
            child: Row(
              children: [
                // Botón imagen
                IconButton(
                  onPressed: _enviando ? null : _mostrarOpcionesImagen,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  color: AppColors.primary,
                ),

                // Campo de texto
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviarTexto(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Botón enviar
                GestureDetector(
                  onTap: _enviando ? null : _enviarTexto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _enviando
                          ? Colors.grey.shade300
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _enviando
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  BURBUJA DE MENSAJE
// ════════════════════════════════════════════════════════════════════
class _BurbujaMensaje extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool esMio;
  final bool mostrarNombre;

  const _BurbujaMensaje({
    required this.msg,
    required this.esMio,
    required this.mostrarNombre,
  });

  @override
  Widget build(BuildContext context) {
    final texto    = msg['texto']  as String? ?? '';
    final fotoUrl  = msg['fotoUrl'] as String? ?? '';
    final tipo     = msg['tipo']   as String? ?? 'texto';
    final nombre   = msg['remitenteName'] as String? ?? '';
    final ts       = msg['timestamp'] as Timestamp?;
    final hora     = ts != null
        ? '${ts.toDate().hour.toString().padLeft(2, '0')}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';
    final leido    = msg['leido'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esMio) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accent.withOpacity(0.2),
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 6),
          ],

          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.70,
              ),
              child: Column(
                crossAxisAlignment:
                    esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (mostrarNombre && !esMio)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(nombre,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),

                  Container(
                    padding: tipo == 'imagen'
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: esMio
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft:     const Radius.circular(18),
                        topRight:    const Radius.circular(18),
                        bottomLeft:  Radius.circular(esMio ? 18 : 4),
                        bottomRight: Radius.circular(esMio ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: tipo == 'imagen' && fotoUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(fotoUrl,
                                width: 200,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox(
                                    width: 200, height: 150,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }),
                          )
                        : Text(
                            texto,
                            style: TextStyle(
                                color: esMio ? Colors.white : AppColors.textPrimary,
                                fontSize: 14,
                                height: 1.35),
                          ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hora,
                            style: const TextStyle(
                                color: AppColors.textLight, fontSize: 10)),
                        if (esMio) ...[
                          const SizedBox(width: 4),
                          Icon(
                            leido ? Icons.done_all : Icons.done,
                            size: 12,
                            color: leido
                                ? AppColors.accent
                                : AppColors.textLight,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (esMio) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
