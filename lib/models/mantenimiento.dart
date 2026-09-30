import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════
//  MODELO MANTENIMIENTO
// ═══════════════════════════════════════════════════════════════════════
class Mantenimiento {
  final String id;
  final String equipoId;
  final String equipoNombre;
  final String equipoArea;
  final String incidenciaId;
  final String biomedicoId;
  final String tipo;            // Preventivo | Correctivo
  final String diagnostico;
  final String accionesRealizadas;
  final String observaciones;
  final String estadoFinal;     // Operativo | Fuera de servicio | En observación
  final DateTime horaInicio;
  final DateTime horaFin;
  final List<String> fotosAntes;
  final List<String> fotosDurante;
  final List<String> fotosDespues;
  final List<RepuestoUsado> repuestosUsados;
  final DateTime fechaCreacion;

  const Mantenimiento({
    required this.id,
    required this.equipoId,
    required this.equipoNombre,
    required this.equipoArea,
    required this.incidenciaId,
    required this.biomedicoId,
    required this.tipo,
    required this.diagnostico,
    required this.accionesRealizadas,
    required this.observaciones,
    required this.estadoFinal,
    required this.horaInicio,
    required this.horaFin,
    required this.fotosAntes,
    required this.fotosDurante,
    required this.fotosDespues,
    required this.repuestosUsados,
    required this.fechaCreacion,
  });

  factory Mantenimiento.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return Mantenimiento(
      id:                doc.id,
      equipoId:          j['equipoId']          ?? '',
      equipoNombre:      j['equipoNombre']       ?? '',
      equipoArea:        j['equipoArea']         ?? '',
      incidenciaId:      j['incidenciaId']       ?? '',
      biomedicoId:       j['biomedicoId']        ?? '',
      tipo:              j['tipo']               ?? 'Correctivo',
      diagnostico:       j['diagnostico']        ?? '',
      accionesRealizadas:j['accionesRealizadas'] ?? '',
      observaciones:     j['observaciones']      ?? '',
      estadoFinal:       j['estadoFinal']        ?? 'Operativo',
      horaInicio:       (j['horaInicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      horaFin:          (j['horaFin']    as Timestamp?)?.toDate() ?? DateTime.now(),
      fotosAntes:       List<String>.from(j['fotosAntes']   ?? []),
      fotosDurante:     List<String>.from(j['fotosDurante'] ?? []),
      fotosDespues:     List<String>.from(j['fotosDespues'] ?? []),
      repuestosUsados:  (j['repuestosUsados'] as List? ?? [])
          .map((r) => RepuestoUsado.fromJson(r as Map<String, dynamic>))
          .toList(),
      fechaCreacion:    (j['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'equipoId':           equipoId,
        'equipoNombre':       equipoNombre,
        'equipoArea':         equipoArea,
        'incidenciaId':       incidenciaId,
        'biomedicoId':        biomedicoId,
        'tipo':               tipo,
        'diagnostico':        diagnostico,
        'accionesRealizadas': accionesRealizadas,
        'observaciones':      observaciones,
        'estadoFinal':        estadoFinal,
        'horaInicio':         Timestamp.fromDate(horaInicio),
        'horaFin':            Timestamp.fromDate(horaFin),
        'fotosAntes':         fotosAntes,
        'fotosDurante':       fotosDurante,
        'fotosDespues':       fotosDespues,
        'repuestosUsados':    repuestosUsados.map((r) => r.toJson()).toList(),
        'fechaCreacion':      Timestamp.fromDate(fechaCreacion),
      };
}

class RepuestoUsado {
  final String repuestoId;
  final String nombre;
  final String codigo;
  final int cantidad;

  const RepuestoUsado({
    required this.repuestoId,
    required this.nombre,
    required this.codigo,
    required this.cantidad,
  });

  factory RepuestoUsado.fromJson(Map<String, dynamic> j) => RepuestoUsado(
        repuestoId: j['repuestoId'] ?? '',
        nombre:     j['nombre']     ?? '',
        codigo:     j['codigo']     ?? '',
        cantidad:   j['cantidad']   ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'repuestoId': repuestoId,
        'nombre':     nombre,
        'codigo':     codigo,
        'cantidad':   cantidad,
      };
}
