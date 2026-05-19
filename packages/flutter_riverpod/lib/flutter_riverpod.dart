library flutter_riverpod;

import 'package:flutter/material.dart';

abstract class ProviderBase<T> {
  const ProviderBase();

  T create(Ref ref);
}

class Provider<T> extends ProviderBase<T> {
  const Provider(this._create);

  final T Function(Ref ref) _create;

  @override
  T create(Ref ref) => _create(ref);
}

class ProviderContainer extends ChangeNotifier {
  ProviderContainer({Map<ProviderBase<Object?>, Object?>? overrides})
      : _overrides = overrides ?? const {};

  final Map<ProviderBase<Object?>, Object?> _overrides;
  final Map<ProviderBase<Object?>, Object?> _cache = {};
  final Map<ChangeNotifier, VoidCallback> _subscriptions = {};

  T read<T>(ProviderBase<T> provider) {
    final override = _overrides[provider as ProviderBase<Object?>];
    if (override != null) {
      return override as T;
    }

    final cached = _cache[provider as ProviderBase<Object?>];
    if (cached != null) {
      return cached as T;
    }

    final value = provider.create(Ref(this));
    _cache[provider as ProviderBase<Object?>] = value;

    if (value is ChangeNotifier && !_subscriptions.containsKey(value)) {
      void listener() => notifyListeners();
      value.addListener(listener);
      _subscriptions[value] = listener;
    }

    return value;
  }

  @override
  void dispose() {
    for (final entry in _subscriptions.entries) {
      entry.key.removeListener(entry.value);
    }
    for (final value in _cache.values) {
      if (value is ChangeNotifier) {
        value.dispose();
      }
    }
    _cache.clear();
    _subscriptions.clear();
    super.dispose();
  }
}

class Ref {
  Ref(this._container);

  final ProviderContainer _container;

  T read<T>(ProviderBase<T> provider) => _container.read(provider);
  T watch<T>(ProviderBase<T> provider) => _container.read(provider);
}

class WidgetRef extends Ref {
  WidgetRef(super._container);
}

class _ProviderScopeInherited extends InheritedNotifier<ProviderContainer> {
  const _ProviderScopeInherited({
    required ProviderContainer container,
    required super.child,
  }) : super(notifier: container);
}

class ProviderScope extends StatefulWidget {
  const ProviderScope({
    super.key,
    required this.child,
    this.container,
    this.overrides,
  });

  final Widget child;
  final ProviderContainer? container;
  final Map<ProviderBase<Object?>, Object?>? overrides;

  static ProviderContainer of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_ProviderScopeInherited>();
    assert(inherited != null, 'ProviderScope not found in widget tree.');
    return inherited!.notifier!;
  }

  @override
  State<ProviderScope> createState() => _ProviderScopeState();
}

class _ProviderScopeState extends State<ProviderScope> {
  late final ProviderContainer _container =
      widget.container ?? ProviderContainer(overrides: widget.overrides);

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ProviderScopeInherited(
      container: _container,
      child: widget.child,
    );
  }
}

abstract class ConsumerWidget extends StatelessWidget {
  const ConsumerWidget({super.key});

  Widget buildWithRef(BuildContext context, WidgetRef ref);

  @override
  Widget build(BuildContext context) {
    return buildWithRef(context, WidgetRef(ProviderScope.of(context)));
  }
}

abstract class ConsumerStatefulWidget extends StatefulWidget {
  const ConsumerStatefulWidget({super.key});

  @override
  ConsumerState createState();
}

abstract class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {
  Widget buildWithRef(BuildContext context, WidgetRef ref);

  @override
  Widget build(BuildContext context) {
    return buildWithRef(context, WidgetRef(ProviderScope.of(context)));
  }
}

class Consumer extends StatelessWidget {
  const Consumer({super.key, required this.builder});

  final Widget Function(BuildContext context, WidgetRef ref, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, WidgetRef(ProviderScope.of(context)), null);
  }
}
