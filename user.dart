class User {
  final int? id;
  final String name;
  final String controlNumber;
  final String turno;
  final String? groupName;
  final String? career;
  final String password;

  User({
    this.id,
    required this.name,
    required this.controlNumber,
    required this.turno,
    this.groupName,
    this.career,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'controlNumber': controlNumber,
      'turno': turno,
      'groupName': groupName,
      'career': career,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      controlNumber: map['controlNumber'],
      turno: map['turno'],
      groupName: map['groupName'],
      career: map['career'],
      password: map['password'],
    );
  }
}