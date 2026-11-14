import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/nc_theme.dart';
import 'funciones_proximas.dart';
import 'profile_option_group.dart';
import 'profile_option_tile.dart';
import 'profile_section_title.dart';
import 'theme_mode_option.dart';

/// "Configuración": avisos, tema, privacidad y seguridad de la cuenta.
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final nc = context.nc;
    ProfileOptionTile proxima({
      required String clave,
      required IconData icon,
      required String title,
      required String subtitle,
      required String aviso,
      required String ruta,
    }) {
      final pronto = kFuncionesProximas.contains(clave);
      return ProfileOptionTile(
        icon: icon,
        accent: nc.azulA,
        title: title,
        subtitle: subtitle,
        proximamente: pronto,
        onTap: () =>
            pronto ? avisarProximamente(context, aviso) : context.push(ruta),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle('Configuración'),
        ProfileOptionGroup(children: [
          ProfileOptionTile(
            icon: Icons.notifications_none_rounded,
            accent: nc.eventos,
            title: 'Avisos de eventos',
            subtitle: 'Elige qué eventos te interesan',
            onTap: () => context.push('/events/notification-preferences'),
          ),
          const ThemeModeOption(),
          ProfileOptionTile(
            icon: Icons.shield_outlined,
            accent: nc.successA,
            title: 'Privacidad',
            subtitle: 'Cómo cuidamos tus datos',
            onTap: () => context.push('/profile/privacy'),
          ),
          ProfileOptionTile(
            icon: Icons.key_rounded,
            accent: nc.oroA,
            title: 'Cambiar contraseña',
            subtitle: 'Usa una clave nueva y segura',
            onTap: () => context.push('/profile/password'),
          ),
          proxima(
            clave: 'correo',
            icon: Icons.alternate_email_rounded,
            title: 'Cambiar correo',
            subtitle: 'Actualiza tu correo electrónico',
            aviso: 'Cambiar el correo',
            ruta: '/profile/change-email',
          ),
          proxima(
            clave: 'sesiones',
            icon: Icons.devices_outlined,
            title: 'Sesiones activas',
            subtitle: 'Dispositivos con tu cuenta abierta',
            aviso: 'Ver las sesiones activas',
            ruta: '/profile/sessions',
          ),
          ProfileOptionTile(
            icon: Icons.delete_outline_rounded,
            accent: nc.tomateA,
            title: 'Eliminar cuenta',
            subtitle: 'Borra tu cuenta de forma permanente',
            danger: true,
            onTap: () => context.push('/profile/delete-account'),
          ),
        ]),
      ],
    );
  }
}
