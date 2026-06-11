import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user_dashboard_screen.dart';
import 'user_registration_screen.dart';
import '../utils/responsive.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _controlController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _controlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Obtener y limpiar los valores
    final controlNumber = _controlController.text.trim();
    final password = _passwordController.text.trim();

    // Validaciones
    if (controlNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu número de control')),
      );
      return;
    }

    if (controlNumber.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número de control debe tener exactamente 14 dígitos')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu contraseña')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      final user = await db.getUserByControlNumber(controlNumber);

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Número de control no registrado')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Verificar contraseña
      if (user.password != password) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña incorrecta')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Login exitoso - Navegar pasando el usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bienvenido ${user.name}')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserDashboardScreen(user: user), // ✅ PASAMOS EL USUARIO
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: const Color(0xFFCDCDCD),
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
        title: Text(
          'Inicio de sesión usuario',
          style: TextStyle(
            fontSize: responsive.appBarTitleSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFAB0F0F),
            letterSpacing: -1.2,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: responsive.largeSpacing),
            TextField(
              controller: _controlController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              decoration: InputDecoration(
                labelText: 'Número de control',
                hintText: 'Ej: 20231234567890',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: responsive.largeSpacing),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAB0F0F),
                padding: EdgeInsets.symmetric(vertical: responsive.mediumSpacing),
              ),
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Ingresar',
                      style: TextStyle(
                        fontSize: responsive.bodySize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
            SizedBox(height: responsive.smallSpacing),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserRegistrationScreen(),
                  ),
                );
              },
              child: Text(
                '¿No tienes cuenta? Regístrate',
                style: TextStyle(
                  fontSize: responsive.bodySize,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}