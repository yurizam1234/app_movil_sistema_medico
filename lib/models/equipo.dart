class Equipo {
  final String equipoId;
  String nombre;
  final String modelo;
  final String serie;
  final String marca;
  final int areaId;
  String area;
  final int anioFabricacion;
  final int anioAdquisicion;
  String solicitante;
  final String observaciones;

  Equipo({
    required this.equipoId,
    required this.nombre,
    required this.modelo,
    required this.serie,
    required this.marca,
    required this.areaId,
    required this.area,
    required this.anioFabricacion,
    required this.anioAdquisicion,
    required this.solicitante,
    required this.observaciones,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      equipoId: json['equipoID'] as String? ?? '',
      nombre: json['NombreEquipo'] as String? ?? '',
      modelo: json['Modelo'] as String? ?? '',
      serie: json['Serie'] as String? ?? '',
      marca: json['Marca'] as String? ?? '',
      areaId: json['areaID'] as int? ?? 0,
      area: json['area'] as String? ?? '',
      anioFabricacion: json['Fabricacion'] as int? ?? 0,
      anioAdquisicion: json['Adquisicion'] as int? ?? 0,
      solicitante: json['solicitante'] as String? ?? '',
      observaciones: json['Observaciones'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'equipoID': equipoId,
      'NombreEquipo': nombre,
      'Modelo': modelo,
      'Serie': serie,
      'Marca': marca,
      'areaID': areaId,
      'area': area,
      'Fabricacion': anioFabricacion,
      'Adquisicion': anioAdquisicion,
      'solicitante': solicitante,
      'Observaciones': observaciones,
    };
  }
}

