import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Imprimir usuarios al iniciar la app
  await _printUsers();
  
  runApp(const MyApp());
}

Future<void> _printUsers() async {
  final dbHelper = DatabaseHelper();
  
  try {
    final users = await dbHelper.getAllUsers();
    
    print('\n========== USUARIOS REGISTRADOS ==========');
    print('Total: ${users.length} usuarios\n');
    
    if (users.isEmpty) {
      print(' No hay usuarios registrados aún');
    } else {
      for (var user in users) {
        print(' ID: ${user.id}');
        print('   Nombre: ${user.name}');
        print('   Número de control: ${user.controlNumber}');
        print('   Turno: ${user.turno}');
        print('   Carrera: ${user.career ?? "No especificada"}');
        print('   Grupo: ${user.groupName ?? "No especificado"}');
        print('   Contraseña: ${user.password}');
        print('   ------------------------------------');
      }
    }
    print('==========================================\n');
    
  } catch (e) {
    print(' Error al leer usuarios: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoluntApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAB0F0F)),
      ),
      home: const HomeScreen(),
    );
  }
}