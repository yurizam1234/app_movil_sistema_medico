import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/incidencia.dart';
import '../../widgets/status_chip.dart';

// ═══════════════════════════════════════════════════════════════════════
//  DETALLE DE SOLICITUD — MÓDULO ENFERMERA
// ═══════════════════════════════════════════════════════════════════════
class DetalleSolicitudEnfermeraScreen extends StatefulWidget {
  final Incidencia incidencia;
  const DetalleSolicitudEnfermeraScreen({super.key, required this.incidencia});

  @override
  State<DetalleSolicitudEnfermeraScreen> createState() =>
      _DetalleSolicitudEnfermeraScreenState();
}

class _DetalleSolicitudEnfermeraScreenState
    extends State<DetalleSolicitudEnfermeraScreen> {
  final _comentCtrl = TextEditingController();

  Incidencia get inc => widget.incidencia;

  @override
  void dispose() {
    _comentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                // ID Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Solicitud # ${inc.id}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _buildEquipoCard(),
                const SizedBox(height: 16),
                _buildEstadoCard(),
                const SizedBox(height: 16),
                _buildTecnicoCard(),
                const SizedBox(height: 16),
                _buildDescripcionCard(),
                const SizedBox(height: 16),
                _buildFotosCard(),
                const SizedBox(height: 16),
                _buildTimelineCard(),
                const SizedBox(height: 16),
                _buildComentariosCard(),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar con gradiente ──────────────────────────────────────
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  inc.equipoNombre,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(inc.area,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Información del equipo ──────────────────────────────────────────
  Widget _buildEquipoCard() => _Card(
        title: 'Información del equipo',
        icon: Icons.medical_services_outlined,
        child: Column(
          children: [
            _InfoRow('Equipo', inc.equipoNombre),
            _InfoRow('Marca', inc.equipoMarca.isEmpty ? '—' : inc.equipoMarca),
            _InfoRow('Modelo', inc.equipoModelo.isEmpty ? '—' : inc.equipoModelo),
            _InfoRow('N.º de serie', inc.equipoSerie.isEmpty ? '—' : inc.equipoSerie),
            _InfoRow('Código QR', inc.equipoCodigoQR),
            _InfoRow('Área', inc.area, isLast: true),
          ],
        ),
      );

  // ── Estado de la solicitud ──────────────────────────────────────────
  Widget _buildEstadoCard() => _Card(
        title: 'Estado de la solicitud',
        icon: Icons.info_outline,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Text('Estado actual',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  StatusChip(estado: inc.estado),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            _InfoRow('Tipo de incidencia', inc.tipoIncidencia),
            _InfoRow('Fecha de registro', _formatFechaLarga(inc.fechaCreacion),
                isLast: true),
          ],
        ),
      );

  // ── Técnico asignado ────────────────────────────────────────────────
  Widget _buildTecnicoCard() => _Card(
        title: 'Técnico asignado',
        icon: Icons.engineering_outlined,
        child: inc.tieneTecnico
            ? Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.engineering,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inc.tecnicoNombre!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        const Text('Técnico Biomédico',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.resolved.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.resolved, size: 14),
                        SizedBox(width: 4),
                        Text('Asignado',
                            style: TextStyle(
                                color: AppColors.resolved,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_empty,
                        color: AppColors.pending, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sin asignar',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.pending)),
                          SizedBox(height: 2),
                          Text(
                              'El área biomédica revisará tu solicitud a la brevedad.',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      );

  // ── Descripción ─────────────────────────────────────────────────────
  Widget _buildDescripcionCard() => _Card(
        title: 'Descripción del problema',
        icon: Icons.description_outlined,
        child: Text(
          inc.descripcion.isEmpty ? 'Sin descripción adicional.' : inc.descripcion,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14, height: 1.6),
        ),
      );

  // ── Fotografías ─────────────────────────────────────────────────────
  Widget _buildFotosCard() => _Card(
        title: 'Fotografías (${inc.fotografias.length})',
        icon: Icons.photo_library_outlined,
        child: inc.fotografias.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        color: AppColors.textLight, size: 22),
                    SizedBox(width: 10),
                    Text('No se adjuntaron fotografías.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: inc.fotografias.length,
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
      );

  // ── Timeline del historial ──────────────────────────────────────────
  Widget _buildTimelineCard() {
    final historial = inc.historial;
    if (historial.isEmpty) return const SizedBox.shrink();

    return _Card(
      title: 'Historial de la solicitud',
      icon: Icons.timeline_outlined,
      child: Column(
        children: historial.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == historial.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Línea de tiempo ──────────────────────────────
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isLast
                              ? StatusChip.colorFor(item.estado)
                              : AppColors.divider,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                          boxShadow: isLast
                              ? [
                                  BoxShadow(
                                      color: StatusChip.colorFor(item.estado)
                                          .withOpacity(0.4),
                                      blurRadius: 4)
                                ]
                              : [],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: AppColors.divider),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Contenido ──────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(estado: item.estado, small: true),
                        const SizedBox(height: 4),
                        Text(item.descripcion,
                            style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                                height: 1.4)),
                        if (item.autor != null) ...[
                          const SizedBox(height: 2),
                          Text('por ${item.autor}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                        const SizedBox(height: 2),
                        Text(_formatFechaLarga(item.fecha),
                            style: const TextStyle(
                                color: AppColors.textLight, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Comentarios ─────────────────────────────────────────────────────
  Widget _buildComentariosCard() => _Card(
        title: 'Comentarios',
        icon: Icons.chat_bubble_outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (inc.comentarios.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text('Sin comentarios aún.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
            ...inc.comentarios.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.4)),
                )),
            const SizedBox(height: 8),
            // Agregar comentario
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Escribir comentario...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColors.textLight),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_comentCtrl.text.trim().isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Comentario agregado'),
                          backgroundColor: AppColors.resolved,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _comentCtrl.clear();
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  String _formatFechaLarga(DateTime fecha) {
    const meses = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month]} de ${fecha.year}, '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Card reutilizable ────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Fila de información ──────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}
