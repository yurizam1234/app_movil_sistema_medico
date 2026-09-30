import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de usuario autenticado leído desde Firestore → colección 'usuarios'
class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String rol;    // enfermera | biomedico | administrador
  final String cargo;
  final String hospital;
  final String telefono;
  final String photoUrl;
  final String estado; // activo | inactivo

  const UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.cargo,
    required this.hospital,
    required this.telefono,
    required this.photoUrl,
    required this.estado,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data()!;
    return UserModel(
      uid:      doc.id,
      nombre:   j['nombre']   ?? j['displayName'] ?? 'Usuario',
      email:    j['email']    ?? '',
      rol:      j['rol']      ?? j['cargo']        ?? 'enfermera',
      cargo:    j['cargo']    ?? 'Enfermera',
      hospital: j['hospital'] ?? 'Q&Q Medical Ltda.',
      telefono: j['telefono'] ?? '',
      photoUrl: j['photoUrl'] ?? j['photo_url'] ?? '',
      estado:   j['estado']   ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre':   nombre,
        'email':    email,
        'rol':      rol,
        'cargo':    cargo,
        'hospital': hospital,
        'telefono': telefono,
        'photoUrl': photoUrl,
        'estado':   estado,
      };

  UserModel copyWith({
    String? nombre,
    String? cargo,
    String? hospital,
    String? telefono,
    String? photoUrl,
  }) =>
      UserModel(
        uid:      uid,
        nombre:   nombre    ?? this.nombre,
        email:    email,
        rol:      rol,
        cargo:    cargo     ?? this.cargo,
        hospital: hospital  ?? this.hospital,
        telefono: telefono  ?? this.telefono,
        photoUrl: photoUrl  ?? this.photoUrl,
        estado:   estado,
      );
}
