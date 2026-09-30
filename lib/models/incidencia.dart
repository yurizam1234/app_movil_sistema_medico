import 'package:cloud_firestore/cloud_firestore.dart';

// ── Historia del ciclo de vida de la incidencia ──────────────────────────
class HistorialItem {
  final DateTime fecha;
  final String descripcion;
  final String estado;
  final String? autor;

  const HistorialItem({
    required this.fecha,
    required this.descripcion,
    required this.estado,
    this.autor,
  });

  factory HistorialItem.fromJson(Map<String, dynamic> j) => HistorialItem(
        fecha: j['fecha'] != null
            ? (j['fecha'] as Timestamp).toDate()
            : DateTime.now(),
        descripcion: j['descripcion'] ?? '',
        estado: j['estado'] ?? '',
        autor: j['autor'],
      );

  Map<String, dynamic> toJson() => {
        'fecha': Timestamp.fromDate(fecha),
        'descripcion': descripcion,
        'estado': estado,
        if (autor != null) 'autor': autor,
      };
}

// ── Modelo principal ─────────────────────────────────────────────────────
class Incidencia {
  final String id;
  final String equipoId;
  final String equipoNombre;
  final String equipoMarca;
  final String equipoModelo;
  final String equipoSerie;
  final String equipoCodigoQR;
  final String area;
  final String tipoIncidencia;
  final String descripcion;
  final String estado; // Pendiente | Asignada | En Proceso | Resuelta
  final String? tecnicoId;
  final String? tecnicoNombre;
  final String solicitanteId;
  final String solicitanteNombre;
  final DateTime fechaCreacion;
  final List<String> fotografias;
  final List<HistorialItem> historial;
  final List<String> comentarios;

  const Incidencia({
    required this.id,
    required this.equipoId,
    required this.equipoNombre,
    required this.equipoMarca,
    required this.equipoModelo,
    required this.equipoSerie,
    required this.equipoCodigoQR,
    required this.area,
    required this.tipoIncidencia,
    required this.descripcion,
    required this.estado,
    this.tecnicoId,
    this.tecnicoNombre,
    required this.solicitanteId,
    required this.solicitanteNombre,
    required this.fechaCreacion,
    this.fotografias = const [],
    this.historial = const [],
    this.comentarios = const [],
  });

  bool get tieneTecnico => tecnicoId != null && tecnicoId!.isNotEmpty;

  // ── Firestore ──────────────────────────────────────────────────────────
  factory Incidencia.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return Incidencia(
      id: doc.id,
      equipoId: j['equipoId'] ?? '',
      equipoNombre: j['equipoNombre'] ?? '',
      equipoMarca: j['equipoMarca'] ?? '',
      equipoModelo: j['equipoModelo'] ?? '',
      equipoSerie: j['equipoSerie'] ?? '',
      equipoCodigoQR: j['equipoCodigoQR'] ?? '',
      area: j['area'] ?? '',
      tipoIncidencia: j['tipoIncidencia'] ?? '',
      descripcion: j['descripcion'] ?? '',
      estado: j['estado'] ?? 'Pendiente',
      tecnicoId: j['tecnicoId'],
      tecnicoNombre: j['tecnicoNombre'],
      solicitanteId: j['solicitanteId'] ?? '',
      solicitanteNombre: j['solicitanteNombre'] ?? '',
      fechaCreacion: j['fechaCreacion'] != null
          ? (j['fechaCreacion'] as Timestamp).toDate()
          : DateTime.now(),
      fotografias: List<String>.from(j['fotografias'] ?? []),
      historial: (j['historial'] as List<dynamic>? ?? [])
          .map((h) => HistorialItem.fromJson(h as Map<String, dynamic>))
          .toList(),
      comentarios: List<String>.from(j['comentarios'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'equipoId': equipoId,
        'equipoNombre': equipoNombre,
        'equipoMarca': equipoMarca,
        'equipoModelo': equipoModelo,
        'equipoSerie': equipoSerie,
        'equipoCodigoQR': equipoCodigoQR,
        'area': area,
        'tipoIncidencia': tipoIncidencia,
        'descripcion': descripcion,
        'estado': estado,
        'tecnicoId': tecnicoId,
        'tecnicoNombre': tecnicoNombre,
        'solicitanteId': solicitanteId,
        'solicitanteNombre': solicitanteNombre,
        'fechaCreacion': Timestamp.fromDate(fechaCreacion),
        'fotografias': fotografias,
        'historial': historial.map((h) => h.toJson()).toList(),
        'comentarios': comentarios,
      };
}

// ── Datos de demo (reemplazar con Firestore en producción) ────────────────
class IncidenciaDemo {
  static List<Incidencia> get lista => [
        Incidencia(
          id: 'INC-001',
          equipoId: 'eq001',
          equipoNombre: 'Ventilador Mecánico Drager Evita 4',
          equipoMarca: 'Drager',
          equipoModelo: 'Evita 4',
          equipoSerie: 'SN-20241',
          equipoCodigoQR: 'QR-EQ001',
          area: 'UCI — Unidad de Cuidados Intensivos',
          tipoIncidencia: 'Avería',
          descripcion:
              'El ventilador presenta alarmas intermitentes y ruido anormal durante el ciclo de exhalación.',
          estado: 'En Proceso',
          tecnicoId: 'tec001',
          tecnicoNombre: 'Ing. Carlos Rojas',
          solicitanteId: 'enf001',
          solicitanteNombre: 'Enf. María García',
          fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
          historial: [
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 2)),
              descripcion: 'Incidencia registrada',
              estado: 'Pendiente',
              autor: 'Enf. María García',
            ),
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 1)),
              descripcion: 'Asignado a técnico biomédico',
              estado: 'Asignada',
              autor: 'Sistema',
            ),
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(hours: 3)),
              descripcion: 'Técnico inició diagnóstico en sitio',
              estado: 'En Proceso',
              autor: 'Ing. Carlos Rojas',
            ),
          ],
        ),
        Incidencia(
          id: 'INC-002',
          equipoId: 'eq002',
          equipoNombre: 'Monitor Multiparamétrico Mindray',
          equipoMarca: 'Mindray',
          equipoModelo: 'MEC-1200',
          equipoSerie: 'SN-30582',
          equipoCodigoQR: 'QR-EQ002',
          area: 'Urgencias',
          tipoIncidencia: 'Mal funcionamiento',
          descripcion:
              'La pantalla de SpO2 muestra valores erráticos y la alarma audible no responde.',
          estado: 'Pendiente',
          solicitanteId: 'enf001',
          solicitanteNombre: 'Enf. María García',
          fechaCreacion: DateTime.now().subtract(const Duration(hours: 5)),
          historial: [
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(hours: 5)),
              descripcion: 'Incidencia registrada',
              estado: 'Pendiente',
              autor: 'Enf. María García',
            ),
          ],
        ),
        Incidencia(
          id: 'INC-003',
          equipoId: 'eq003',
          equipoNombre: 'Electrocardiógrafo EDAN SE-1201',
          equipoMarca: 'EDAN',
          equipoModelo: 'SE-1201',
          equipoSerie: 'SN-41209',
          equipoCodigoQR: 'QR-EQ003',
          area: 'Cardiología',
          tipoIncidencia: 'Calibración',
          descripcion: 'Requiere calibración periódica de electrodos.',
          estado: 'Asignada',
          tecnicoId: 'tec002',
          tecnicoNombre: 'Ing. Luis Mendoza',
          solicitanteId: 'enf001',
          solicitanteNombre: 'Enf. María García',
          fechaCreacion: DateTime.now().subtract(const Duration(days: 3)),
          historial: [
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 3)),
              descripcion: 'Incidencia registrada',
              estado: 'Pendiente',
              autor: 'Enf. María García',
            ),
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 2)),
              descripcion: 'Asignado a Ing. Luis Mendoza',
              estado: 'Asignada',
              autor: 'Sistema',
            ),
          ],
        ),
        Incidencia(
          id: 'INC-004',
          equipoId: 'eq004',
          equipoNombre: 'Bomba de Infusión Baxter AS50',
          equipoMarca: 'Baxter',
          equipoModelo: 'AS50',
          equipoSerie: 'SN-55318',
          equipoCodigoQR: 'QR-EQ004',
          area: 'Pediatría',
          tipoIncidencia: 'Mantenimiento preventivo',
          descripcion:
              'Mantenimiento preventivo semestral según protocolo institucional.',
          estado: 'Resuelta',
          tecnicoId: 'tec001',
          tecnicoNombre: 'Ing. Carlos Rojas',
          solicitanteId: 'enf001',
          solicitanteNombre: 'Enf. María García',
          fechaCreacion: DateTime.now().subtract(const Duration(days: 7)),
          historial: [
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 7)),
              descripcion: 'Incidencia registrada',
              estado: 'Pendiente',
              autor: 'Enf. María García',
            ),
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 6)),
              descripcion: 'Asignado a Ing. Carlos Rojas',
              estado: 'Asignada',
              autor: 'Sistema',
            ),
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 5)),
              descripcion: 'Mantenimiento preventivo ejecutado',
              estado: 'En Proceso',
              autor: 'Ing. Carlos Rojas',
            ),
            HistorialItem(
              fecha: DateTime.now().subtract(const Duration(days: 4)),
              descripcion: 'Equipo verificado y operativo',
              estado: 'Resuelta',
              autor: 'Ing. Carlos Rojas',
            ),
          ],
        ),
      ];
}
