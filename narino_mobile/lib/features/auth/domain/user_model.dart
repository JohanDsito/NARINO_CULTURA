/// Modelo de dominio del usuario autenticado (perfil mínimo).
class UserModel {
  final int id;
  final String email;
  final String nombre;
  final String rol;

  const UserModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        nombre: json['nombre'] as String,
        rol: json['rol'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nombre': nombre,
        'rol': rol,
      };
}
