import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _nameController = TextEditingController();
  final _controlController = TextEditingController();
  final _groupController = TextEditingController();
  String? _selectedCareer;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedShift;

  @override
  void dispose() {
    _nameController.dispose();
    _controlController.dispose();
    _groupController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          'VoluntApp',
          style: TextStyle(
            fontSize: responsive.appBarTitleSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFAB0F0F),
            letterSpacing: -1.2,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registro de Usuario',
              style: TextStyle(
                fontSize: responsive.screenTitleSize,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: responsive.largeSpacing),
            _buildTextField('Nombre:', _nameController, responsive),
            SizedBox(height: responsive.mediumSpacing),
            _buildTextField(
              'No.Control:',
              _controlController,
              responsive,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 14,
            ),
            SizedBox(height: responsive.mediumSpacing),
            _buildShiftField(responsive),
            SizedBox(height: responsive.mediumSpacing),
            _buildGroupField(responsive), // ← Campo de grado y grupo modificado
            SizedBox(height: responsive.mediumSpacing),
            _buildCareerField(responsive),
            SizedBox(height: responsive.mediumSpacing),
            _buildTextField(
              'Contraseña:',
              _passwordController,
              responsive,
              isPassword: true,
            ),
            SizedBox(height: responsive.mediumSpacing),
            _buildTextField(
              'Confirmar:',
              _confirmPasswordController,
              responsive,
              isPassword: true,
            ),
            SizedBox(height: responsive.largeSpacing),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAB0F0F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final control = _controlController.text.trim();
                  final group = _groupController.text.trim().toUpperCase();
                  final password = _passwordController.text;
                  final confirm = _confirmPasswordController.text;

                  if (name.isEmpty || control.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor completa los campos requeridos',
                        ),
                      ),
                    );
                    return;
                  }
                  if (_selectedShift == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor selecciona un turno'),
                      ),
                    );
                    return;
                  }
                  if (_selectedCareer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor selecciona una carrera'),
                      ),
                    );
                    return;
                  }
                  if (control.length != 14 || int.tryParse(control) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'El número de control debe tener exactamente 14 dígitos',
                        ),
                      ),
                    );
                    return;
                  }
                  
                  // Validación para grado y grupo
                  if (group.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa el grado y grupo (Ejemplo: 6A)'),
                      ),
                    );
                    return;
                  }
                  if (group.length != 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El grado y grupo debe tener exactamente 2 caracteres (Ejemplo: 6A)'),
                      ),
                    );
                    return;
                  }
                  if (!RegExp(r'^[0-9][A-Za-z]$').hasMatch(group)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Formato inválido. Ejemplo válido: 6A (un número y una letra)'),
                      ),
                    );
                    return;
                  }
                  
                  if (password != confirm) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Las contraseñas no coinciden'),
                      ),
                    );
                    return;
                  }

                  final db = DatabaseHelper();
                  final user = User(
                    name: name,
                    controlNumber: control,
                    turno: _selectedShift!,
                    groupName: group, // ← Ahora es obligatorio y tiene formato específico
                    career: _selectedCareer,
                    password: password,
                  );

                  try {
                    final id = await db.insertUser(user.toMap());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Usuario registrado (id: $id)')),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al registrar: $e')),
                      );
                    }
                  }
                },
                child: const Text(
                  'Registrarse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    ResponsiveSize responsive, {
    bool isPassword = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.bodySize,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: responsive.smallSpacing),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            hintText: label == 'Grado y Grupo:' ? 'Ejemplo: 6A' : null,
          ),
        ),
      ],
    );
  }

  // ==================== CAMPO GRADO Y GRUPO MODIFICADO ====================
  Widget _buildGroupField(ResponsiveSize responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grado y Grupo:',
          style: TextStyle(
            fontSize: responsive.bodySize,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: responsive.smallSpacing),
        TextField(
          controller: _groupController,
          keyboardType: TextInputType.text,
          inputFormatters: [
            LengthLimitingTextInputFormatter(2), // Limita a 2 caracteres
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')), // Solo letras y números
          ],
          textCapitalization: TextCapitalization.characters, // Convierte a mayúsculas automáticamente
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Ejemplo: 6A',
            helperText: 'Ingresa un número y una letra (ej: 6A, 6B, 5A, 5B)',
          ),
        ),
      ],
    );
  }

  Widget _buildShiftField(ResponsiveSize responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turno:',
          style: TextStyle(
            fontSize: responsive.bodySize,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: responsive.smallSpacing),
        DropdownButtonFormField<String>(
          value: _selectedShift,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Seleccionar turno'),
          items: const [
            DropdownMenuItem(value: 'matutino', child: Text('Matutino')),
            DropdownMenuItem(value: 'vespertino', child: Text('Vespertino')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedShift = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCareerField(ResponsiveSize responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carrera:',
          style: TextStyle(
            fontSize: responsive.bodySize,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: responsive.smallSpacing),
        DropdownButtonFormField<String>(
          value: _selectedCareer,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Seleccionar carrera'),
          items: const [
            DropdownMenuItem(value: 'Programación', child: Text('Programación')),
            DropdownMenuItem(value: 'Ventas', child: Text('Ventas')),
            DropdownMenuItem(value: 'Alimentos y Bebidas', child: Text('Alimentos y Bebidas')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCareer = value;
            });
          },
        ),
      ],
    );
  }
}