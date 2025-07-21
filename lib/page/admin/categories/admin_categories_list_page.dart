import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:app_facturacion/page/admin/categories/admin_categories_form_page.dart';
import 'package:flutter/material.dart';

import '../../../models/Categoria.dart'; // Importa tu modelo real

class AdminCategoriesListPage extends StatefulWidget {
  const AdminCategoriesListPage({super.key});

  @override
  State<AdminCategoriesListPage> createState() =>
      _AdminCategoriesListPageState();
}

class _AdminCategoriesListPageState extends State<AdminCategoriesListPage> {
  List<Categoria> categorias = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      isLoading = true;
    });

    try {
      final request = ModelQueries.list(Categoria.classType);
      final response = await Amplify.API.query(request: request).response;
      final categories = response.data?.items;
      if (categories == null) {
        safePrint('errors: ${response.errors}');
      }
      setState(() {
        categorias =
            response.data?.items
                    .where((item) => item != null)
                    .cast<Categoria>()
                    .toList()
                as List<Categoria>;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar categorías: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Categoria> get filteredCategorias {
    if (searchQuery.isEmpty) return categorias;
    return categorias
        .where(
          (cat) => cat.nombre.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategorias,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar categorías...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Lista de categorías
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCategorias.isEmpty
                ? const Center(
                    child: Text(
                      'No hay categorías disponibles',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCategorias,
                    child: ListView.builder(
                      itemCount: filteredCategorias.length,
                      itemBuilder: (context, index) {
                        return _buildCategoriaItem(filteredCategorias[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoriaItem(Categoria categoria) {
    // Obtener subcategorías si tu modelo las maneja de manera diferente
    final subCategorias = _getSubcategorias(categoria);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.category),
        title: Text(
          categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subCategorias.isNotEmpty
            ? Text('${subCategorias.length} subcategorías')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _navigateToForm(categoria: categoria),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(categoria),
            ),
          ],
        ),
        children: subCategorias
            .map((subCat) => _buildSubCategoriaItem(subCat))
            .toList(),
      ),
    );
  }

  List<Categoria> _getSubcategorias(Categoria categoria) {
    // Ajusta esta lógica según cómo tu modelo maneja las subcategorías
    // Si tienes una propiedad subCategorias en tu modelo:
    // return categoria.subCategorias ?? [];

    // Si necesitas buscar en la lista principal por parentCategoriaID:
    return categorias
        .where((cat) => cat.parentCategoriaID == categoria.id)
        .toList();
  }

  Widget _buildSubCategoriaItem(Categoria subCategoria) {
    return ListTile(
      leading: const SizedBox(width: 20),
      title: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 16),
          const SizedBox(width: 8),
          Text(subCategoria.nombre),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
            onPressed: () => _navigateToForm(categoria: subCategoria),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () => _showDeleteDialog(subCategoria),
          ),
        ],
      ),
    );
  }

  void _navigateToForm({Categoria? categoria}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCategoriesFormPage(
          categoria: categoria,
          categoriasDisponibles: categorias,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadCategorias(); // Recargar la lista si hubo cambios
      }
    });
  }

  void _showDeleteDialog(Categoria categoria) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${categoria.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategoria(categoria);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategoria(Categoria categoria) async {
    try {
      // Aquí harías la llamada a GraphQL para eliminar
      await Future.delayed(const Duration(milliseconds: 500));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría eliminada correctamente')),
      );

      _loadCategorias();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }
}
