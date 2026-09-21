import 'package:flutter_test/flutter_test.dart';
import 'package:narino_cultura/features/auth/domain/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('mapea los campos básicos', () {
      final user = UserModel.fromJson({
        'id': 5,
        'email': 'ana@test.com',
        'nombre': 'Ana',
        'rol': 'artista',
        'is_verified': false,
      });

      expect(user.id, '5');
      expect(user.email, 'ana@test.com');
      expect(user.nombre, 'Ana');
      expect(user.rol, 'artista');
      expect(user.isVerified, isFalse);
    });

    test('convierte el id numérico a String', () {
      final user = UserModel.fromJson({
        'id': 42,
        'email': 'a@a.com',
        'nombre': 'A',
        'rol': 'comprador',
      });

      expect(user.id, '42');
    });

    test('usa cadena vacía cuando no viene id', () {
      final user = UserModel.fromJson({
        'email': 'a@a.com',
        'nombre': 'A',
        'rol': 'comprador',
      });

      expect(user.id, '');
    });

    test('usa first_name cuando no viene nombre', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'first_name': 'Juan',
        'rol': 'comprador',
      });

      expect(user.nombre, 'Juan');
    });

    test('usa cadena vacía cuando no viene ni nombre ni first_name', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'rol': 'comprador',
      });

      expect(user.nombre, '');
    });

    test('usa role cuando no viene rol', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'nombre': 'A',
        'role': 'artista',
      });

      expect(user.rol, 'artista');
    });

    test('usa cadena vacía cuando no viene ni rol ni role', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'nombre': 'A',
      });

      expect(user.rol, '');
    });

    test('prioriza is_verified sobre email_verificado y email_verified', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'nombre': 'A',
        'rol': 'comprador',
        'is_verified': false,
        'email_verificado': true,
        'email_verified': true,
      });

      expect(user.isVerified, isFalse);
    });

    test('usa email_verificado cuando no viene is_verified', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'nombre': 'A',
        'rol': 'comprador',
        'email_verificado': false,
      });

      expect(user.isVerified, isFalse);
    });

    test(
        'usa email_verified cuando no vienen is_verified ni email_verificado',
        () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'nombre': 'A',
        'rol': 'comprador',
        'email_verified': false,
      });

      expect(user.isVerified, isFalse);
    });

    test('isVerified es true por defecto cuando no viene ninguna clave', () {
      final user = UserModel.fromJson({
        'id': '1',
        'email': 'a@a.com',
        'nombre': 'A',
        'rol': 'comprador',
      });

      expect(user.isVerified, isTrue);
    });
  });

  group('UserModel.toJson', () {
    test('serializa todos los campos incluido is_verified', () {
      const user = UserModel(
        id: '1',
        email: 'a@a.com',
        nombre: 'Ana',
        rol: 'artista',
        isVerified: false,
      );

      expect(user.toJson(), {
        'id': '1',
        'email': 'a@a.com',
        'nombre': 'Ana',
        'rol': 'artista',
        'is_verified': false,
      });
    });

    test('is_verified serializa true cuando se usa el valor por defecto', () {
      const user = UserModel(
        id: '1',
        email: 'a@a.com',
        nombre: 'Ana',
        rol: 'artista',
      );

      expect(user.toJson()['is_verified'], isTrue);
    });
  });
}
