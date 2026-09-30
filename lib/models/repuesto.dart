import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
//  MODELO REPUESTO
// ═══════════════════════════════════════════════════════════════════════
class Repuesto {
  final String id;
  final String codigo;
  final String nombre;
  final String categoria;
  final int cantidad;
  final int cantidadMinima;
  final String ubicacion;
  final String estado;
  final String marca;
  final String modeloCompatible;
  final String proveedor;
  final double precio;

  const Repuesto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.cantidadMinima,
    required this.ubicacion,
    required this.estado,
    required this.marca,
    required this.modeloCompatible,
    required this.proveedor,
    required this.precio,
  });

  factory Repuesto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return Repuesto(
      id:               doc.id,
      codigo:           j['codigo']           ?? '',
      nombre:           j['nombre']           ?? '',
      categoria:        j['categoria']        ?? '',
      cantidad:         (j['cantidad']        ?? 0) as int,
      cantidadMinima:   (j['cantidadMinima']  ?? 0) as int,
      ubicacion:        j['ubicacion']        ?? '',
      estado:           j['estado']           ?? 'Disponible',
      marca:            j['marca']            ?? '',
      modeloCompatible: j['modeloCompatible'] ?? '',
      proveedor:        j['proveedor']        ?? '',
      precio:           ((j['precio']         ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo':           codigo,
        'nombre':           nombre,
        'categoria':        categoria,
        'cantidad':         cantidad,
        'cantidadMinima':   cantidadMinima,
        'ubicacion':        ubicacion,
        'estado':           estadoReal,
        'marca':            marca,
        'modeloCompatible': modeloCompatible,
        'proveedor':        proveedor,
        'precio':           precio,
      };

  String get estadoReal {
    if (cantidad <= 0) return 'Agotado';
    if (cantidad <= cantidadMinima) return 'Bajo stock';
    return 'Disponible';
  }

  Color get colorEstado {
    if (cantidad <= 0) return const Color(0xFFEF4444);
    if (cantidad <= cantidadMinima) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }
}
