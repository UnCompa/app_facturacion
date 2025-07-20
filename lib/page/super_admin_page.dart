import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class SuperAdminPage extends StatelessWidget {
  const SuperAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Panel SuperAdmin',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bienvenido, SuperAdministrador',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Amplify.Auth.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    "Cerrar sesión",
                    style: GoogleFonts.poppins(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Gestión de Compradores
            Text(
              'Gestión de Negocios',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.lightBlue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildOptionCard(
                  icon: Icons.location_city,
                  title: 'Negocios',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// Gestión de Usuarios
            Text(
              'Gestión de Usuarios',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.lightBlue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildOptionCard(
                  icon: Icons.people,
                  title: 'Usuarios',
                  onTap: () {
                    Navigator.pushNamed(context, "/superadmin/users");
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// Configuración del Sistema
            /* Text(
              'Configuración del Sistema',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.lightBlue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildOptionCard(
                  icon: Icons.settings,
                  title: 'Parámetros Generales',
                  onTap: () {},
                ),
                _buildOptionCard(
                  icon: Icons.receipt_long,
                  title: 'Facturación',
                  onTap: () {},
                ),
                _buildOptionCard(
                  icon: Icons.analytics,
                  title: 'Reportes',
                  onTap: () {},
                ),
              ],
            ), */
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        height: 120,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.lightBlue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
