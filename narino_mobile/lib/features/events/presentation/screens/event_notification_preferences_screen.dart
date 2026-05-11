import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class EventNotificationPreferencesScreen extends ConsumerStatefulWidget {
  const EventNotificationPreferencesScreen({super.key});

  @override
  ConsumerState<EventNotificationPreferencesScreen> createState() =>
      _EventNotificationPreferencesScreenState();
}

class _EventNotificationPreferencesScreenState
    extends ConsumerState<EventNotificationPreferencesScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isSaving = false;

  // Preferencias
  bool _allEnabled = true;
  final Map<String, bool> _categoryPreferences = {
    'concierto': true,
    'exposicion': true,
    'taller': true,
    'feria': true,
    'convocatoria': true,
    'otro': true,
  };
  List<String> _favoriteArtists = [];

  final TextEditingController _artistController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      // Intentar cargar de local storage primero (caché)
      final localData =
          await _storage.read(key: 'event_notification_preferences');
      if (localData != null) {
        final json = jsonDecode(localData);
        _updateLocalState(json);
      }

      // Luego cargar de backend para estar al día
      final response = await ApiClient.instance.dio
          .get(ApiConstants.eventNotificationPreferences);
      if (response.statusCode == 200) {
        _updateLocalState(response.data);
        await _storage.write(
            key: 'event_notification_preferences',
            value: jsonEncode(response.data));
      }
    } catch (e) {
      debugPrint('Error cargando preferencias: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateLocalState(Map<String, dynamic> data) {
    setState(() {
      _allEnabled = data['all_enabled'] ?? true;
      final cats = data['categories'] as Map<String, dynamic>?;
      if (cats != null) {
        cats.forEach((key, value) {
          if (_categoryPreferences.containsKey(key)) {
            _categoryPreferences[key] = value as bool;
          }
        });
      }
      _favoriteArtists = List<String>.from(data['favorite_artists'] ?? []);
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final data = {
      'all_enabled': _allEnabled,
      'categories': _categoryPreferences,
      'favorite_artists': _favoriteArtists,
    };

    try {
      final response = await ApiClient.instance.dio.patch(
        ApiConstants.eventNotificationPreferences,
        data: data,
      );

      if (response.statusCode == 200) {
        await _storage.write(
            key: 'event_notification_preferences', value: jsonEncode(data));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferencias guardadas'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addArtist() {
    final name = _artistController.text.trim();
    if (name.isEmpty) return;
    if (_favoriteArtists.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El artista ya está en tu lista')),
      );
      return;
    }
    if (_favoriteArtists.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 10 artistas permitidos')),
      );
      return;
    }

    setState(() {
      _favoriteArtists.add(name);
      _artistController.clear();
    });
  }

  void _removeArtist(String name) {
    setState(() {
      _favoriteArtists.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textMuted = theme.brightness == Brightness.dark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        foregroundColor: AppColors.oroClaro,
        title: Text(
          'Notificaciones de Eventos',
          style: AppTypography.displaySemiBold(color: AppColors.oroClaro)
              .copyWith(fontSize: 20),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: cs.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección 1: Toggle general
                  _buildGeneralToggle(),
                  const SizedBox(height: 24),

                  // Contenido configurable (se bloquea si all_enabled es false)
                  AbsorbPointer(
                    absorbing: !_allEnabled,
                    child: Opacity(
                      opacity: _allEnabled ? 1.0 : 0.4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sección 2: Por tipo
                          Text(
                            'Por tipo de evento',
                            style: AppTypography.labelSemiBold(),
                          ),
                          const SizedBox(height: 12),
                          ..._categoryPreferences.keys
                              .map((cat) => _buildCategoryTile(cat)),
                          const SizedBox(height: 32),

                          // Sección 3: Por artista
                          Text(
                            'Por artista',
                            style: AppTypography.labelSemiBold(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Recibirás una notificación cuando estos artistas publiquen un nuevo evento',
                            style: AppTypography.caption(
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildArtistInput(),
                          const SizedBox(height: 16),
                          _buildArtistList(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón Guardar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                      child: _isSaving
                          ? CircularProgressIndicator(color: cs.onPrimary)
                          : Text(
                              'Guardar preferencias',
                              style: AppTypography.buttonText(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralToggle() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recibir notificaciones de eventos',
                  style: AppTypography.labelSemiBold(),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activa o desactiva todas las alertas de eventos',
                  style: AppTypography.caption(color: textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: _allEnabled,
            activeThumbColor: cs.primary,
            onChanged: (val) => setState(() => _allEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String category) {
    final cs = Theme.of(context).colorScheme;
    const labels = {
      'concierto': '🎵 Conciertos',
      'exposicion': '🎨 Exposiciones',
      'taller': '🖌️ Talleres',
      'feria': '🏪 Ferias',
      'convocatoria': '📢 Convocatorias',
      'otro': '📅 Otros',
    };

    return SwitchListTile(
      title: Text(
        labels[category] ?? category,
        style: AppTypography.bodyMedium(),
      ),
      value: _categoryPreferences[category] ?? false,
      activeThumbColor: cs.primary,
      onChanged: (val) => setState(() => _categoryPreferences[category] = val),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildArtistInput() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _artistController,
            decoration: InputDecoration(
              hintText: 'Nombre del artista...',
              hintStyle: AppTypography.bodySmall(
                color: textMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: _addArtist,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildArtistList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSubtle = isDark ? AppColors.bgSubtleDark : AppColors.bgSubtleLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    if (_favoriteArtists.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgSubtle,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No has agregado artistas favoritos',
            style: AppTypography.bodySmall(color: textMuted),
          ),
        ),
      );
    }

    return Column(
      children: _favoriteArtists.map((name) => _buildArtistTile(name)).toList(),
    );
  }

  Widget _buildArtistTile(String name) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgCard = theme.cardTheme.color ?? cs.surface;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 18,
            color: textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: AppTypography.bodyMedium())),
          IconButton(
            onPressed: () => _removeArtist(name),
            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
