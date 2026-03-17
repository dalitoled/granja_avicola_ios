import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm_profile_model.dart';
import '../services/farm_service.dart';
import '../services/activation_service.dart';
import 'register_farm_screen.dart';

class FarmProfileScreen extends StatefulWidget {
  const FarmProfileScreen({super.key});

  @override
  State<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends State<FarmProfileScreen> {
  final FarmService _farmService = FarmService();
  final ActivationService _activationService = ActivationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<FarmProfileModel> _farms = [];
  FarmProfileModel? _selectedFarm;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _capacidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('granjas')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<FarmProfileModel> farms = [];
      for (var doc in snapshot.docs) {
        farms.add(FarmProfileModel.fromMap(doc.data()));
      }

      if (mounted) {
        setState(() {
          _farms = farms;
          _selectedFarm = farms.isNotEmpty ? farms.first : null;
          _isLoading = false;
          if (_selectedFarm != null) {
            _nombreController.text = _selectedFarm!.nombre;
            _direccionController.text = _selectedFarm!.direccion;
            _telefonoController.text = _selectedFarm!.telefono;
            _capacidadController.text = _selectedFarm!.capacidad.toString();
          }
        });
      }
    } catch (e) {
      final querySnapshot = await _firestore.collection('granjas').get();
      final filtered = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['userId'] == user.uid;
      });

      List<FarmProfileModel> farms = [];
      for (var doc in filtered) {
        farms.add(FarmProfileModel.fromMap(doc.data()));
      }

      if (mounted) {
        setState(() {
          _farms = farms;
          _selectedFarm = farms.isNotEmpty ? farms.first : null;
          _isLoading = false;
          if (_selectedFarm != null) {
            _nombreController.text = _selectedFarm!.nombre;
            _direccionController.text = _selectedFarm!.direccion;
            _telefonoController.text = _selectedFarm!.telefono;
            _capacidadController.text = _selectedFarm!.capacidad.toString();
          }
        });
      }
    }
  }

  void _selectFarm(FarmProfileModel farm) {
    setState(() {
      _selectedFarm = farm;
      _isEditing = false;
      _nombreController.text = farm.nombre;
      _direccionController.text = farm.direccion;
      _telefonoController.text = farm.telefono;
      _capacidadController.text = farm.capacidad.toString();
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _selectedFarm == null) return;

    try {
      final updatedFarm = _selectedFarm!.copyWith(
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        capacidad:
            int.tryParse(_capacidadController.text.trim()) ??
            _selectedFarm!.capacidad,
        updatedAt: DateTime.now(),
      );

      await _farmService.updateFarm(updatedFarm);

      if (mounted) {
        setState(() {
          _selectedFarm = updatedFarm;
          final index = _farms.indexWhere((f) => f.id == updatedFarm.id);
          if (index != -1) {
            _farms[index] = updatedFarm;
          }
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Granja actualizada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    }
  }

  Future<void> _addNewFarm() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterFarmScreen()),
    ).then((_) => _loadFarms());
  }

  Future<void> _deactivateApp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar App'),
        content: const Text(
          '¿Está seguro que desea desactivar la app? Si tiene múltiples granjas, esto cerrará la sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _activationService.deactivateApp();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Granjas'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewFarm,
            tooltip: 'Agregar Granja',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _farms.isEmpty
          ? _buildEmptyState()
          : _buildFarmSelector(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.agriculture, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay granjas registradas',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewFarm,
            icon: const Icon(Icons.add),
            label: const Text('Registrar Granja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_farms.length > 1) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar Granja:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _farms.length,
                        itemBuilder: (context, index) {
                          final farm = _farms[index];
                          final isSelected = farm.id == _selectedFarm?.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(farm.nombre),
                              selected: isSelected,
                              selectedColor: const Color(0xFF2E7D32),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              onSelected: (_) => _selectFarm(farm),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _isEditing ? _buildEditForm() : _buildProfileView(),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    if (_selectedFarm == null) return const SizedBox();

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.agriculture, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFarm!.nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_farms.length} granj${_farms.length == 1 ? 'a' : 'as'} registrad${_farms.length == 1 ? 'a' : 'as'}',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text('Dirección'),
                subtitle: Text(_selectedFarm!.direccion),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF2E7D32)),
                title: const Text('Teléfono'),
                subtitle: Text(_selectedFarm!.telefono),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.egg, color: Color(0xFF2E7D32)),
                title: const Text('Capacidad'),
                subtitle: Text('${_selectedFarm!.capacidad} gallinas'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text('Fecha de Registro'),
                subtitle: Text(_formatDate(_selectedFarm!.createdAt)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addNewFarm,
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _deactivateApp,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text(
            'Cerrar Sesión',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.edit, size: 48, color: Color(0xFF2E7D32)),
                  const SizedBox(height: 8),
                  const Text(
                    'Editar Granja',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Granja',
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese el nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _direccionController,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese la dirección';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telefonoController,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese el teléfono';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacidadController,
            decoration: const InputDecoration(
              labelText: 'Capacidad (gallinas)',
              prefixIcon: Icon(Icons.egg),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese la capacidad';
              }
              final capacidad = int.tryParse(value.trim());
              if (capacidad == null || capacidad <= 0) {
                return 'Ingrese un número válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _toggleEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
