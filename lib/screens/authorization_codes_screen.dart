import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/authorization_code_service.dart';
import '../services/farm_service.dart';
import '../providers/auth_provider.dart';

class AuthorizationCodesScreen extends StatefulWidget {
  const AuthorizationCodesScreen({super.key});

  @override
  State<AuthorizationCodesScreen> createState() =>
      _AuthorizationCodesScreenState();
}

class _AuthorizationCodesScreenState extends State<AuthorizationCodesScreen> {
  final AuthorizationCodeService _authCodeService = AuthorizationCodeService();
  final FarmService _farmService = FarmService();
  List<Map<String, dynamic>> _codes = [];
  bool _isLoading = true;
  String _farmId = '';
  String _farmName = '';

  @override
  void initState() {
    super.initState();
    _loadFarmInfo();
  }

  Future<void> _loadFarmInfo() async {
    final authProvider = context.read<AppAuthProvider>();
    _farmId = authProvider.currentFarmId;
    
    if (_farmId.isNotEmpty) {
      final farm = await _farmService.getFarmById(_farmId);
      if (farm != null) {
        _farmName = farm.nombre;
      }
    }
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> codes;
    if (_farmId.isNotEmpty) {
      codes = await _authCodeService.getCodesByFarm(_farmId);
    } else {
      codes = await _authCodeService.getAllCodes();
    }

    if (mounted) {
      setState(() {
        _codes = codes;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewCode() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.purple),
            SizedBox(width: 8),
            Text('Generar Código'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El código generado permitirá al usuario registrarse como Administrador.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente *',
                hintText: 'Ej: Juan Pérez',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                hintText: 'correo@ejemplo.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El nombre es obligatorio'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
              });
            },
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _authCodeService.createCodeForUser(
          email: result['email'] ?? '',
          ownerName: result['name']!,
          farmId: _farmId,
          farmName: _farmName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Código generado para ${result['name']}'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadCodes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Códigos - $_farmName'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCodes),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNewCode,
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('Generar Código'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _codes.isEmpty
          ? const Center(child: Text('No hay códigos generados'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _codes.length,
              itemBuilder: (context, index) {
                final code = _codes[index];
                return _buildCodeCard(code);
              },
            ),
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> code) {
    final isUsed = code['used'] == true;
    final codeStr = code['code'] ?? '';
    final ownerName = code['ownerName'] ?? '';
    final forEmail = code['forEmail'] ?? '';
    final farmName = code['farmName'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isUsed ? null : () => _copyCode(codeStr),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUsed ? Colors.red.shade100 : Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUsed ? Icons.person : Icons.key,
                      color: isUsed ? Colors.red : Colors.green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          codeStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                        if (!isUsed && ownerName.isNotEmpty)
                          Text(
                            'Para: $ownerName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUsed ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUsed ? 'USADO' : 'DISPONIBLE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUsed ? Colors.red.shade700 : Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (isUsed) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        farmName.isNotEmpty ? 'Granja: $farmName' : 'Granja: No especificada',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isUsed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.content_copy, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Toca para copiar el código',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Text('Código "$code" copiado'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
}
