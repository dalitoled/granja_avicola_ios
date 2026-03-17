import 'package:flutter/material.dart';
import '../services/authorization_code_service.dart';

class AuthorizationCodesScreen extends StatefulWidget {
  const AuthorizationCodesScreen({super.key});

  @override
  State<AuthorizationCodesScreen> createState() =>
      _AuthorizationCodesScreenState();
}

class _AuthorizationCodesScreenState extends State<AuthorizationCodesScreen> {
  final AuthorizationCodeService _authCodeService = AuthorizationCodeService();
  List<Map<String, dynamic>> _codes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() {
      _isLoading = true;
    });

    final codes = await _authCodeService.getAllCodes();

    if (mounted) {
      setState(() {
        _codes = codes;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewCode() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar Nuevo Código'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del propietario',
                hintText: 'Ej: Juan Pérez',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                hintText: 'correo@ejemplo.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        String code;
        if (emailController.text.trim().isNotEmpty) {
          await _authCodeService.createCodeForUser(
            emailController.text.trim(),
            nameController.text.trim(),
          );
          code = 'Generado para ${emailController.text.trim()}';
        } else {
          code = await _authCodeService.generateCode();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Código generado: $code'),
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
        title: const Text('Códigos de Autorización'),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUsed ? Colors.red.shade100 : Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUsed ? Icons.close : Icons.check,
            color: isUsed ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          codeStr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUsed ? 'Usado por: ${code['usedBy'] ?? 'N/A'}' : 'Disponible',
              style: TextStyle(color: isUsed ? Colors.red : Colors.green),
            ),
            if (code['ownerName'] != null)
              Text(
                'Propietario: ${code['ownerName']}',
                style: const TextStyle(fontSize: 12),
              ),
            if (code['forEmail'] != null)
              Text(
                'Email: ${code['forEmail']}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: isUsed
            ? Chip(
                label: const Text('USADO'),
                backgroundColor: Colors.red.shade100,
              )
            : Chip(
                label: const Text('DISPONIBLE'),
                backgroundColor: Colors.green.shade100,
              ),
      ),
    );
  }
}
