library go_router;

import 'dart:async';

import 'package:flutter/material.dart';

typedef GoRouterRedirect = String? Function(BuildContext context, GoRouterState state);

class GoRouterState {
  GoRouterState({
    required this.uri,
    required this.pathParameters,
    this.extra,
    required this.matchedLocation,
    this.name,
  });

  final Uri uri;
  final Map<String, String> pathParameters;
  final Object? extra;
  final String matchedLocation;
  final String? name;
}

class GoRoute {
  const GoRoute({
    required this.path,
    required this.builder,
    this.name,
    this.routes = const [],
  });

  final String path;
  final String? name;
  final Widget Function(BuildContext context, GoRouterState state) builder;
  final List<GoRoute> routes;
}

class _ResolvedRoute {
  const _ResolvedRoute({
    required this.route,
    required this.state,
  });

  final GoRoute route;
  final GoRouterState state;
}

class _GoRouterScope extends InheritedWidget {
  const _GoRouterScope({
    required this.router,
    required super.child,
  });

  final GoRouter router;

  static GoRouter of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_GoRouterScope>();
    assert(scope != null, 'GoRouter scope not found.');
    return scope!.router;
  }

  @override
  bool updateShouldNotify(_GoRouterScope oldWidget) => router != oldWidget.router;
}

class GoRouter extends ChangeNotifier {
  GoRouter({
    required List<GoRoute> routes,
    this.initialLocation = '/',
    this.redirect,
    this.refreshListenable,
  }) : _routes = _flattenRoutes(routes) {
    _history.add(initialLocation);
    refreshListenable?.addListener(_handleRefresh);
    _delegate = _GoRouterDelegate(this);
    _parser = _GoRouteInformationParser(this);
    _applyRedirects();
  }

  final String initialLocation;
  final GoRouterRedirect? redirect;
  final Listenable? refreshListenable;
  final List<GoRoute> _routes;
  final List<String> _history = [];

  late final _GoRouterDelegate _delegate;
  late final _GoRouteInformationParser _parser;

  RouterDelegate<String> get routerDelegate => _delegate;
  RouteInformationParser<String> get routeInformationParser => _parser;
  String get location => _history.isEmpty ? initialLocation : _history.last;

  bool canPop() => _history.length > 1;

  void go(String location) {
    _history
      ..clear()
      ..add(location);
    _applyRedirects(notify: true);
  }

  void push(String location) {
    _history.add(location);
    _applyRedirects(notify: true);
  }

  void pop() {
    if (canPop()) {
      _history.removeLast();
      notifyListeners();
    }
  }

  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) {
    final route = _routes.firstWhere((item) => item.name == name);
    final path = _buildPath(route.path, pathParameters);
    final uri = Uri(path: path, queryParameters: queryParameters.isEmpty ? null : queryParameters);
    go(uri.toString());
  }

  _ResolvedRoute? resolve(String location) {
    final uri = Uri.parse(location);
    for (final route in _routes) {
      final match = _matchRoute(route, uri);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  void _handleRefresh() {
    _applyRedirects();
  }

  void _applyRedirects({bool notify = false}) {
    var changed = false;
    for (var i = 0; i < 8; i++) {
      final resolved = resolve(location);
      if (resolved == null) {
        break;
      }
      final context = _delegate.navigatorKey.currentContext ?? _delegate.currentContext;
      if (context == null) {
        break;
      }
      final next = redirect?.call(context, resolved.state);
      if (next == null || next == location) {
        break;
      }
      _history
        ..clear()
        ..add(next);
      changed = true;
    }
    if (notify || changed) {
      notifyListeners();
    }
  }

  static List<GoRoute> _flattenRoutes(List<GoRoute> routes, [String parent = '']) {
    final flattened = <GoRoute>[];
    for (final route in routes) {
      final fullPath = _joinPaths(parent, route.path);
      flattened.add(
        GoRoute(
          path: fullPath,
          name: route.name,
          builder: route.builder,
          routes: const [],
        ),
      );
      flattened.addAll(_flattenRoutes(route.routes, fullPath));
    }
    return flattened;
  }

  static String _joinPaths(String parent, String child) {
    if (child.startsWith('/')) {
      return child;
    }
    if (parent.isEmpty || parent == '/') {
      return '/$child'.replaceAll('//', '/');
    }
    return '${parent.endsWith('/') ? parent : '$parent/'}$child';
  }

  static String _buildPath(String pattern, Map<String, String> params) {
    var path = pattern;
    params.forEach((key, value) {
      path = path.replaceAll(':$key', Uri.encodeComponent(value));
    });
    return path;
  }

  static _ResolvedRoute? _matchRoute(GoRoute route, Uri uri) {
    final patternSegments = route.path.split('/').where((segment) => segment.isNotEmpty).toList();
    final uriSegments = uri.pathSegments;
    if (patternSegments.length != uriSegments.length) {
      return null;
    }

    final params = <String, String>{};
    for (var index = 0; index < patternSegments.length; index++) {
      final pattern = patternSegments[index];
      final value = Uri.decodeComponent(uriSegments[index]);
      if (pattern.startsWith(':')) {
        params[pattern.substring(1)] = value;
      } else if (pattern != value) {
        return null;
      }
    }

    return _ResolvedRoute(
      route: route,
      state: GoRouterState(
        uri: uri,
        pathParameters: params,
        matchedLocation: route.path,
        name: route.name,
      ),
    );
  }
}

class _GoRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  _GoRouterDelegate(this.router);

  final GoRouter router;
  BuildContext? currentContext;

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  String? get currentConfiguration => router.location;

  @override
  Future<void> setNewRoutePath(String configuration) async {
    router.go(configuration);
  }

  @override
  Widget build(BuildContext context) {
    currentContext = context;
    router._applyRedirects();
    final resolved = router.resolve(router.location);
    final page = resolved == null
        ? const Scaffold(body: Center(child: Text('Route not found')))
        : resolved.route.builder(context, resolved.state);

    return _GoRouterScope(
      router: router,
      child: Navigator(
        key: navigatorKey,
        pages: [
          MaterialPage(
            key: ValueKey(router.location),
            child: page,
          ),
        ],
        onDidRemovePage: (page) {
          router.pop();
        },
      ),
    );
  }
}

class _GoRouteInformationParser extends RouteInformationParser<String> {
  _GoRouteInformationParser(this.router);

  final GoRouter router;

  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri.toString();
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    return RouteInformation(uri: Uri.parse(configuration));
  }
}

extension GoRouterContextX on BuildContext {
  GoRouter get _router => _GoRouterScope.of(this);

  void go(String location) => _router.go(location);
  void push(String location) => _router.push(location);
  void pop() => _router.pop();
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
    Object? extra,
  }) {
    _router.goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }
}
