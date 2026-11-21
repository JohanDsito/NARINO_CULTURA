/// Modelo de dominio del usuario autenticado (perfil mínimo).
class UserModel {
  final String id;
  final String email;
  final String nombre;
  final String rol;
  final bool isVerified;

  const UserModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    this.isVerified = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email'] as String,
        nombre: json['nombre'] as String? ?? json['first_name'] as String? ?? '',
        rol: json['rol'] as String? ?? json['role'] as String? ?? '',
        isVerified: json['is_verified'] as bool? ??
            json['email_verificado'] as bool? ??
            json['email_verified'] as bool? ??
            true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nombre': nombre,
        'rol': rol,
        'is_verified': isVerified,
      };
}
