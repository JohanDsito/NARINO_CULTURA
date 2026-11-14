import 'package:flutter/material.dart';

import 'cart_header_action.dart';
import 'notifications_header_action.dart';
import 'theme_header_action.dart';

/// Acciones del header de Inicio: carrito, notificaciones y modo claro/oscuro.
const homeHeaderActions = <Widget>[
  CartHeaderAction(),
  NotificationsHeaderAction(),
  ThemeHeaderAction(),
];
