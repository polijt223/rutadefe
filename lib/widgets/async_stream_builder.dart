import 'dart:async';

import 'package:flutter/material.dart';

class AsyncStreamBuilder<T> extends StatefulWidget {
  final Stream<T> Function() streamFactory;
  final Widget Function(BuildContext context, T data) builder;
  final String loadingMessage;
  final WidgetBuilder? loadingBuilder;
  final bool Function(AsyncSnapshot<T> snapshot)? isDataReady;

  const AsyncStreamBuilder({
    super.key,
    required this.streamFactory,
    required this.builder,
    this.loadingMessage = 'Cargando información...',
    this.loadingBuilder,
    this.isDataReady,
  });

  @override
  State<AsyncStreamBuilder<T>> createState() => _AsyncStreamBuilderState<T>();
}

class _AsyncStreamBuilderState<T> extends State<AsyncStreamBuilder<T>> {
  int _attempt = 0;

  void _retry() => setState(() => _attempt++);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      key: ValueKey(_attempt),
      stream: widget.streamFactory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AsyncErrorView(onRetry: _retry);
        }
        final hasData = widget.isDataReady?.call(snapshot) ?? snapshot.hasData;
        if (!hasData) {
          if (widget.loadingBuilder != null) {
            return widget.loadingBuilder!(context);
          }
          return _AsyncLoadingPanel(
            key: ValueKey(_attempt),
            message: widget.loadingMessage,
            onRetry: _retry,
          );
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}

class AsyncFutureBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureFactory;
  final Widget Function(BuildContext context, T data) builder;
  final String loadingMessage;

  const AsyncFutureBuilder({
    super.key,
    required this.futureFactory,
    required this.builder,
    this.loadingMessage = 'Cargando información...',
  });

  @override
  State<AsyncFutureBuilder<T>> createState() => _AsyncFutureBuilderState<T>();
}

class _AsyncFutureBuilderState<T> extends State<AsyncFutureBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.futureFactory();
  }

  void _retry() => setState(() => _future = widget.futureFactory());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      key: ObjectKey(_future),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AsyncErrorView(onRetry: _retry);
        }
        if (!snapshot.hasData) {
          return _AsyncLoadingPanel(
            key: ObjectKey(_future),
            message: widget.loadingMessage,
            onRetry: _retry,
          );
        }
        return widget.builder(context, snapshot.data as T);
      },
    );
  }
}

class _AsyncLoadingPanel extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;

  const _AsyncLoadingPanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  State<_AsyncLoadingPanel> createState() => _AsyncLoadingPanelState();
}

class _AsyncLoadingPanelState extends State<_AsyncLoadingPanel> {
  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) return AsyncErrorView(onRetry: widget.onRetry);
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AsyncErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const AsyncErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            const Text(
              'No se pudo conectar con los datos',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Comprueba tu conexión a internet e inténtalo de nuevo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}