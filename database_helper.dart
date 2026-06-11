import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../validation_request.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'voluntapp.db');
    return openDatabase(
      path,
      version: 7, // Incrementa la versión porque añadimos metadata de usuario a validation_requests
      onCreate: _createTables,
      onUpgrade: _onUpgrade, // Para migrar datos antiguos (opcional)
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE validation_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentName TEXT NOT NULL,
        originalDate TEXT NOT NULL,
        originalEntryTime TEXT NOT NULL,
        originalExitTime TEXT NOT NULL,
        adminComments TEXT,
        correctedDate TEXT,
        correctedEntryTime TEXT,
        correctedExitTime TEXT,
        action TEXT,
        userControlNumber TEXT,
        groupName TEXT,
        career TEXT,
        turno TEXT
      )
    ''');
    // Nota: la columna userControlNumber se añadió en una versión posterior (upgrade)
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        controlNumber TEXT NOT NULL UNIQUE,
        turno TEXT NOT NULL,
        groupName TEXT,
        career TEXT,
        password TEXT NOT NULL
      )
    ''');
  }

  // Si ya tenías una base de datos con la versión 1, aquí puedes migrar
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Si la versión es menor a 2, recrea todo (borra datos antiguos)
  if (oldVersion < 2) {
    await db.execute('DROP TABLE IF EXISTS validation_requests');
    await db.execute('DROP TABLE IF EXISTS users');
    await _createTables(db, newVersion);
    return;
  }

  // Migraciones progresivas sin duplicados
  if (oldVersion < 3) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        controlNumber TEXT NOT NULL UNIQUE,
        groupName TEXT,
        career TEXT,
        password TEXT NOT NULL
      )
    ''');
  }

  if (oldVersion < 4) {
    await _addColumnIfNotExists(db, 'validation_requests', 'userControlNumber', 'TEXT');
  }

  if (oldVersion < 5) {
    await _addColumnIfNotExists(db, 'users', 'turno', "TEXT NOT NULL DEFAULT 'matutino'");
  }

  if (oldVersion < 6) {
    // Estas columnas ya se crean en _createTables para versiones nuevas,
    // pero para bases antiguas las añadimos solo si no existen.
    await _addColumnIfNotExists(db, 'validation_requests', 'userControlNumber', 'TEXT');
    await _addColumnIfNotExists(db, 'validation_requests', 'groupName', 'TEXT');
    await _addColumnIfNotExists(db, 'validation_requests', 'career', 'TEXT');
    await _addColumnIfNotExists(db, 'validation_requests', 'turno', 'TEXT');
  }

  // Nueva migración a versión 7 (no hace nada, solo para evitar futuros problemas)
  if (oldVersion < 7) {
    // Aquí podrías agregar nuevas columnas en el futuro
  }
}

// Método auxiliar para evitar errores "duplicate column"
Future<void> _addColumnIfNotExists(Database db, String table, String columnName, String columnType) async {
  try {
    await db.execute("ALTER TABLE $table ADD COLUMN $columnName $columnType");
  } catch (e) {
    // Si la columna ya existe, ignoramos el error
    print('Info: Columna $columnName ya existe en $table');
  }
}

  // ==================== CRUD ====================

  Future<int> insertRequest(ValidationRequest request) async {
    final db = await database;
    return await db.insert('validation_requests', request.toMap());
  }

  Future<List<ValidationRequest>> getAllRequests() async {
    final db = await database;
    final maps = await db.query('validation_requests', orderBy: 'id DESC');
    return maps.map((map) => ValidationRequest.fromMap(map)).toList();
  }

  Future<List<ValidationRequest>> getRequestsByAction(String? action) async {
    final db = await database;
    final maps = await db.query(
      'validation_requests',
      where: action == null ? null : 'action = ?',
      whereArgs: action == null ? null : [action],
    );
    return maps.map((map) => ValidationRequest.fromMap(map)).toList();
  }

  Future<List<ValidationRequest>> getRequestsByUser(
    String controlNumber,
  ) async {
    final db = await database;
    // Primero intenta buscar por userControlNumber
    var maps = await db.query(
      'validation_requests',
      where: 'userControlNumber = ?',
      whereArgs: [controlNumber],
      orderBy: 'id DESC',
    );
    
    // Si no hay registros, devuelve todos los registros (para compatibilidad)
    if (maps.isEmpty) {
      maps = await db.query(
        'validation_requests',
        orderBy: 'id DESC',
      );
    }
    
    return maps.map((map) => ValidationRequest.fromMap(map)).toList();
  }

  Future<ValidationRequest?> getRequestById(int id) async {
    final db = await database;
    final maps = await db.query(
      'validation_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? ValidationRequest.fromMap(maps.first) : null;
  }

  Future<int> updateRequest(ValidationRequest request) async {
    final db = await database;
    // Asegúrate de que el request tenga id
    if (request.id == null) {
      throw Exception('No se puede actualizar un registro sin id');
    }
    return await db.update(
      'validation_requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  Future<int> deleteRequest(int id) async {
    final db = await database;
    return await db.delete(
      'validation_requests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== ESTADÍSTICAS ====================

  Future<int> getTotalValidatedHours() async {
    final requests = await getRequestsByAction('validated');
    int totalMinutes = 0;
    for (final req in requests) {
      final entry = req.correctedEntryTime ?? req.originalEntryTime;
      final exit = req.correctedExitTime ?? req.originalExitTime;
      totalMinutes += _timeToMinutes(exit) - _timeToMinutes(entry);
    }
    return (totalMinutes / 60).round();
  }

  Future<int> getTotalValidatedHoursForUser(String controlNumber) async {
    final requests = await getRequestsByUser(controlNumber);
    int totalMinutes = 0;
    for (final req in requests) {
      if (req.action == 'validated') {
        final entry = req.correctedEntryTime ?? req.originalEntryTime;
        final exit = req.correctedExitTime ?? req.originalExitTime;
        totalMinutes += _timeToMinutes(exit) - _timeToMinutes(entry);
      }
    }
    return (totalMinutes / 60).round();
  }

  Future<int> getValidatedRequestCount() async {
    return (await getRequestsByAction('validated')).length;
  }

  Future<int> getPendingRequestCount() async {
    return (await getRequestsByAction(null)).length;
  }

  Future<int> getDeniedRequestCount() async {
    return (await getRequestsByAction('denied')).length;
  }

  // ==================== UTILIDADES ====================

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }

  Future<void> clearAllRequests() async {
    final db = await database;
    await db.delete('validation_requests');
  }

  // ==================== USUARIOS ====================

  Future<int> insertUser(Map<String, dynamic> userMap) async {
    final db = await database;
    return await db.insert('users', userMap);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByControlNumber(String controlNumber) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'controlNumber = ?',
      whereArgs: [controlNumber],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'id DESC');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<int> updateUser(Map<String, dynamic> userMap, int id) async {
    final db = await database;
    return await db.update('users', userMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
  // Obtener todas las solicitudes con filtros dinámicos
Future<List<ValidationRequest>> getFilteredRequests({
  String? searchQuery,
  String? career,
  String? group,
  String? turn,
}) async {
  final db = await database;
  List<String> conditions = [];
  List<Object?> parameters = [];

  if (searchQuery != null && searchQuery.isNotEmpty) {
    conditions.add(
      '(student_name LIKE ? OR control_number LIKE ? OR career LIKE ? OR group_name LIKE ? OR turn LIKE ?)'
    );
    final likePattern = '%$searchQuery%';
    parameters.addAll([likePattern, likePattern, likePattern, likePattern, likePattern]);
  }
  if (career != null && career.isNotEmpty) {
    conditions.add('career = ?');
    parameters.add(career);
  }
  if (group != null && group.isNotEmpty) {
    conditions.add('group_name = ?');
    parameters.add(group);
  }
  if (turn != null && turn.isNotEmpty) {
    conditions.add('turn = ?');
    parameters.add(turn);
  }

  String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
  final List<Map<String, dynamic>> maps = await db.query(
    'requests', // nombre de tu tabla
    where: whereClause.isEmpty ? null : whereClause,
    whereArgs: whereClause.isEmpty ? null : parameters,
    orderBy: 'id DESC',
  );

  return maps.map((map) => ValidationRequest.fromMap(map)).toList();
}

// Obtener valores únicos para los filtros (carreras, grupos, turnos)
Future<List<String>> getDistinctCareers() async {
  final db = await database;
  final result = await db.rawQuery('SELECT DISTINCT career FROM requests WHERE career IS NOT NULL AND career != ""');
  return result.map((row) => row['career'] as String).toList();
}

Future<List<String>> getDistinctGroups() async {
  final db = await database;
  final result = await db.rawQuery('SELECT DISTINCT group_name FROM requests WHERE group_name IS NOT NULL AND group_name != ""');
  return result.map((row) => row['group_name'] as String).toList();
}

Future<List<String>> getDistinctTurns() async {
  final db = await database;
  final result = await db.rawQuery('SELECT DISTINCT turn FROM requests WHERE turn IS NOT NULL AND turn != ""');
  return result.map((row) => row['turn'] as String).toList();
}

}