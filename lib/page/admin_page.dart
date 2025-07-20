import 'package:app_facturacion/page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Admin'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bienvenido, administrador',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
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
            const SizedBox(height: 20),
            _buildOptionTile(
              icon: Icons.add_box,
              title: 'Gestionar inventario',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: Icons.group,
              title: 'Gestionar Vendedores',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: Icons.inventory_outlined,
              title: 'Facturacion',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: Icons.settings,
              title: 'Configuraciones',
              onTap: () {},
            ),
            _buildOptionTile(
              icon: Icons.analytics,
              title: 'Ver Reportes',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
