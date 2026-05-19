import 'dart:async';

class Supabase {
  Supabase._(this.client);

  static Supabase? _instance;

  final SupabaseClient client;

  static Supabase get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('Supabase is not initialized.');
    }
    return instance;
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    _instance = Supabase._(SupabaseClient(url: url, anonKey: anonKey));
  }
}

class SupabaseClient {
  SupabaseClient({
    required this.url,
    required this.anonKey,
  }) : auth = SupabaseAuthClient();

  final String url;
  final String anonKey;
  final SupabaseAuthClient auth;
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  TableQuery from(String table) {
    _tables.putIfAbsent(table, () => <Map<String, dynamic>>[]);
    return TableQuery._(table, _tables);
  }

  Future<Map<String, dynamic>> rpc(
    String function, {
    Map<String, dynamic> params = const {},
  }) async {
    if (function == 'create_booking_safe') {
      return <String, dynamic>{
        'ok': true,
        'params': params,
      };
    }
    return <String, dynamic>{
      'function': function,
      'params': params,
    };
  }
}

class SupabaseUser {
  SupabaseUser({
    required this.id,
    required this.email,
    this.role = 'authenticated',
  });

  final String id;
  final String email;
  final String role;
}

class SupabaseSession {
  SupabaseSession(this.user);

  final SupabaseUser user;
}

class AuthResponse {
  AuthResponse({this.session, this.user});

  final SupabaseSession? session;
  final SupabaseUser? user;
}

class AuthStateChange {
  AuthStateChange(this.session);

  final SupabaseSession? session;
}

class SupabaseAuthClient {
  SupabaseAuthClient();

  final StreamController<AuthStateChange> _controller =
      StreamController<AuthStateChange>.broadcast();
  SupabaseSession? _session;

  Stream<AuthStateChange> get onAuthStateChange => _controller.stream;

  SupabaseUser? get currentUser => _session?.user;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final user = SupabaseUser(
      id: 'mock-${email.hashCode.abs()}',
      email: email,
    );
    _session = SupabaseSession(user);
    _controller.add(AuthStateChange(_session));
    return AuthResponse(session: _session, user: user);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final user = SupabaseUser(
      id: 'mock-${email.hashCode.abs()}',
      email: email,
    );
    _session = SupabaseSession(user);
    _controller.add(AuthStateChange(_session));
    return AuthResponse(session: _session, user: user);
  }

  Future<void> signOut() async {
    _session = null;
    _controller.add(AuthStateChange(null));
  }

  Future<void> resetPasswordForEmail(String email) async {}
}

class TableQuery {
  TableQuery._(this.table, this._tables);

  final String table;
  final Map<String, List<Map<String, dynamic>>> _tables;
  final Map<String, dynamic> _filters = {};

  TableQuery eq(String column, dynamic value) {
    _filters[column] = value;
    return this;
  }

  Future<List<Map<String, dynamic>>> select([String columns = '*']) async {
    final rows = _tables[table] ?? const [];
    return rows
        .where(
          (row) => _filters.entries.every((filter) => row[filter.key] == filter.value),
        )
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> insert(List<Map<String, dynamic>> rows) async {
    final tableRows = _tables[table] ?? <Map<String, dynamic>>[];
    tableRows.addAll(rows.map((row) => Map<String, dynamic>.from(row)));
    _tables[table] = tableRows;
    return rows;
  }

  Future<List<Map<String, dynamic>>> update(Map<String, dynamic> values) async {
    final tableRows = _tables[table] ?? <Map<String, dynamic>>[];
    for (var index = 0; index < tableRows.length; index++) {
      if (_filters.entries.every((filter) => tableRows[index][filter.key] == filter.value)) {
        tableRows[index] = {
          ...tableRows[index],
          ...values,
        };
      }
    }
    _tables[table] = tableRows;
    return tableRows;
  }

  Future<List<Map<String, dynamic>>> delete() async {
    final tableRows = _tables[table] ?? <Map<String, dynamic>>[];
    final remaining = tableRows
        .where(
          (row) => !_filters.entries.every((filter) => row[filter.key] == filter.value),
        )
        .toList(growable: false);
    _tables[table] = remaining;
    return remaining;
  }
}

