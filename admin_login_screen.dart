import 'package:flutter/material.dart';
import 'admin_requests_list_screen.dart';
import '../utils/responsive.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Credenciales del administrador
  static const String _adminEmail = 'cbtis272@dgeti.edu';
  static const String _adminPassword = 'CBTIS 272';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validaciones
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el correo electrónico')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la contraseña')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simular una pequeña demora para mostrar el indicador de carga
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Verificar credenciales
      if (email == _adminEmail && password == _adminPassword) {
        // Login exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bienvenido Administrador')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminRequestsListScreen(),
          ),
        );
      } else {
        // Login fallido
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo o contraseña incorrectos'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveSize(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'VoluntApp',
          style: TextStyle(
            fontSize: responsive.appBarTitleSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFAB0F0F),
            letterSpacing: -1.2,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.06),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: EdgeInsets.all(responsive.largeSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Inicio de sesión administrador',
                    style: TextStyle(
                      fontSize: responsive.screenTitleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: responsive.smallSpacing),
                  Text(
                    'Accede al panel para revisar y validar las solicitudes de voluntariado.',
                    style: TextStyle(
                      fontSize: responsive.bodySize,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: responsive.largeSpacing),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'cbtis272@dgeti.edu',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4F6FA),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsive.mediumSpacing,
                        vertical: responsive.mediumSpacing,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.mediumSpacing),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'CBTIS 272',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4F6FA),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsive.mediumSpacing,
                        vertical: responsive.mediumSpacing,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.largeSpacing),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB0F0F),
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.mediumSpacing,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}