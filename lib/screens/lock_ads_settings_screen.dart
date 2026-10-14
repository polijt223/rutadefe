import 'package:flutter/material.dart';

import '../services/lock_ads_store.dart';
import '../services/lock_ads_sync_service.dart';
import '../services/lock_screen_channel.dart';

class LockAdsSettingsScreen extends StatefulWidget {
  const LockAdsSettingsScreen({super.key});

  @override
  State<LockAdsSettingsScreen> createState() => _LockAdsSettingsScreenState();
}

class _LockAdsSettingsScreenState extends State<LockAdsSettingsScreen> {
  final _sync = LockAdsSyncService();
  bool _enabled = false;
  bool _supported = false;
  bool _busy = false;
  String? _lastDay;
  int _cached = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _sync.isEnabled();
    final lastDay = await _sync.lastSyncDay();
    final supported = await LockScreenChannel().isSupported();
    var cached = 0;
    try {
      cached = (await LockAdsStore().all()).length;
    } catch (_) {
      cached = 0;
    }
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _lastDay = lastDay;
      _supported = supported;
      _cached = cached;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _busy = true;
      _enabled = value;
    });
    try {
      await _sync.setEnabled(value);
      await _load();
    } catch (error) {
      if (mounted) {
        setState(() => _enabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forceSync() async {
    setState(() => _busy = true);
    try {
      final count = await _sync.syncIfDue(force: true);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listos $count anuncios para la pantalla de bloqueo')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo sincronizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    try {
      await _sync.applyNext();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se aplicó el siguiente anuncio')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo aplicar: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla de bloqueo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: _busy ? null : _toggle,
            title: const Text('Mostrar reflexiones al desbloquear'),
            subtitle: Text(
              _supported
                  ? 'Cada desbloqueo muestra un consejo distinto, aunque no tengas internet.'
                  : 'En este dispositivo se guardan offline. El fondo de bloqueo automático está disponible en Android.',
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text('Guardados en el teléfono: $_cached'),
            subtitle: Text(_lastDay == null ? 'Todavía no se sincronizó' : 'Última consulta: $_lastDay'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: !_enabled || _busy ? null : _forceSync,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            label: const Text('Buscar anuncios nuevos'),
          ),
          if (_supported) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: !_enabled || _busy || _cached == 0 ? null : _next,
              icon: const Icon(Icons.skip_next_outlined),
              label: const Text('Mostrar el siguiente ahora'),
            ),
          ],
        ],
      ),
    );
  }
}
