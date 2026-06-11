class ValidationRequest {
  int? id; // ← NUEVO: identificador único para la base de datos
  final String studentName;
  final String originalDate;
  final String originalEntryTime;
  final String originalExitTime;
  String? adminComments;
  String? correctedDate;
  String? correctedEntryTime;
  String? correctedExitTime;
  String? action; // 'validated', 'denied', 'edited', 'submitted'
  String? userControlNumber; // vincula la solicitud con un usuario (no obligatorio)
  String? groupName;
  String? career;
  String? turno;

  ValidationRequest({
    this.id, // ← ahora opcional
    required this.studentName,
    required this.originalDate,
    required this.originalEntryTime,
    required this.originalExitTime,
    this.adminComments,
    this.correctedDate,
    this.correctedEntryTime,
    this.correctedExitTime,
    this.action,
    this.userControlNumber,
    this.groupName,
    this.career,
    this.turno,
  });

  // Convierte el objeto en un Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'originalDate': originalDate,
      'originalEntryTime': originalEntryTime,
      'originalExitTime': originalExitTime,
      'adminComments': adminComments,
      'correctedDate': correctedDate,
      'correctedEntryTime': correctedEntryTime,
      'correctedExitTime': correctedExitTime,
      'action': action,
      'userControlNumber': userControlNumber,
      'groupName': groupName,
      'career': career,
      'turno': turno,
    };
  }

  // Crea un objeto desde un Map (resultado de una consulta SQLite)
  factory ValidationRequest.fromMap(Map<String, dynamic> map) {
    return ValidationRequest(
      id: map['id'],
      studentName: map['studentName'],
      originalDate: map['originalDate'],
      originalEntryTime: map['originalEntryTime'],
      originalExitTime: map['originalExitTime'],
      adminComments: map['adminComments'],
      correctedDate: map['correctedDate'],
      correctedEntryTime: map['correctedEntryTime'],
      correctedExitTime: map['correctedExitTime'],
      action: map['action'],
      userControlNumber: map['userControlNumber'],
      groupName: map['groupName'],
      career: map['career'],
      turno: map['turno'],
    );
  }

  // Tu método copyWith existente (sin cambios)
  ValidationRequest copyWith({
    int? id,
    String? studentName,
    String? originalDate,
    String? originalEntryTime,
    String? originalExitTime,
    String? adminComments,
    String? correctedDate,
    String? correctedEntryTime,
    String? correctedExitTime,
    String? action,
    String? userControlNumber,
    String? groupName,
    String? career,
    String? turno,
  }) {
    return ValidationRequest(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      originalDate: originalDate ?? this.originalDate,
      originalEntryTime: originalEntryTime ?? this.originalEntryTime,
      originalExitTime: originalExitTime ?? this.originalExitTime,
      adminComments: adminComments ?? this.adminComments,
      correctedDate: correctedDate ?? this.correctedDate,
      correctedEntryTime: correctedEntryTime ?? this.correctedEntryTime,
      correctedExitTime: correctedExitTime ?? this.correctedExitTime,
      action: action ?? this.action,
      userControlNumber: userControlNumber ?? this.userControlNumber,
      groupName: groupName ?? this.groupName,
      career: career ?? this.career,
      turno: turno ?? this.turno,
    );
  }
}