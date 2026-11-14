import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/nc_theme.dart';
import '../../shared/widgets/design/design.dart';
import 'shell_tab.dart';

/// Estructura de las pestañas principales: fondo carnaval y barra inferior.

class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static const _tabs = <ShellTab>[
    ShellTab(
      path: '/home',
      label: 'Inicio',
      iconOutlined: Icons.home_outlined,
      iconFilled: Icons.home,
    ),
    ShellTab(
      path: '/catalog',
      label: 'Catálogo',
      iconOutlined: Icons.grid_view_outlined,
      iconFilled: Icons.grid_view,
    ),
    ShellTab(
      path: '/marketplace',
      label: 'Tienda',
      iconOutlined: Icons.storefront_outlined,
      iconFilled: Icons.storefront,
    ),
    ShellTab(
      path: '/auctions',
      label: 'Subastas',
      iconOutlined: Icons.gavel_outlined,
      iconFilled: Icons.gavel,
    ),
    ShellTab(
      path: '/events',
      label: 'Eventos',
      iconOutlined: Icons.event_outlined,
      iconFilled: Icons.event,
    ),
    ShellTab(
      path: '/profile',
      label: 'Perfil',
      iconOutlined: Icons.person_outline,
      iconFilled: Icons.person,
    ),
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateIndex(widget.location);
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateIndex(widget.location);
  }

  void _updateIndex(String location) {
    final idx = MainShell._tabs.indexWhere((t) => location.startsWith(t.path));
    if (idx >= 0) setState(() => _selectedIndex = idx);
  }

  void _goTo(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    carnavalScrollOffset.value = 0;
    context.go(MainShell._tabs[index].path);
  }

  /// Mueve el fondo carnaval con el scroll vertical de la pestaña activa.
  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      carnavalScrollOffset.value = n.metrics.pixels.clamp(0, 4000).toDouble();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.nc.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: CarnavalBackground()),
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ],
      ),
      bottomNavigationBar: NcTabBar(
        currentIndex: _selectedIndex,
        onTap: _goTo,
        items: [
          for (final tab in MainShell._tabs)
            NcTabItem(
              label: tab.label,
              icon: tab.iconOutlined,
              activeIcon: tab.iconFilled,
            ),
        ],
      ),
    );
  }
}
