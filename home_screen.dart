import 'package:flutter/material.dart';
import 'user_login_screen.dart';
import 'admin_login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    
    // Valores responsivos
    final logoFontSize = isMobile ? 28.0 : 59.0;
    final titleFontSize = isMobile ? 24.0 : 50.0;
    final buttonFontSize = isMobile ? 20.0 : 33.0;
    final horizontalPadding = isMobile ? screenWidth * 0.05 : 107.0;
    final titleHorizontalPadding = isMobile ? 20.0 : 185.0;
    final buttonHeight = isMobile ? screenHeight * 0.25 : 597.0;
    final secondButtonHeight = isMobile ? screenHeight * 0.24 : 586.0;

    return Scaffold(
      backgroundColor: const Color(0xFFCDCDCD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Bar
            Container(
              color: Colors.grey[300],
              height: isMobile ? 80 : 108,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isMobile ? 10 : 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // VoluntApp Logo
                    Text(
                      'VoluntApp',
                      style: TextStyle(
                        fontSize: logoFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFAB0F0F),
                        letterSpacing: -1.2,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.fromLTRB(
                titleHorizontalPadding,
                isMobile ? 30 : 50,
                titleHorizontalPadding,
                isMobile ? 40 : 80,
              ),
              child: Text(
                'Sistema de Control de horas del Servicio Social',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            // Usuario Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserLoginScreen(),
                    ),
                  );
                },
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFACDDFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'USUARIO',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        letterSpacing: 0.71,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 30 : 60),
            // Administrador Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLoginScreen(),
                    ),
                  );
                },
                child: Container(
                  height: secondButtonHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC38A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'ADMINISTRADOR',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        letterSpacing: 0.71,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 40 : 80),
          ],
        ),
      ),
    );
  }
}
