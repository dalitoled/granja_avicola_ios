import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../models/role_model.dart';
import '../providers/auth_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = context.read<AppAuthProvider>();
      final currentUserModel = authProvider.user;
      final currentUserRole = authProvider.currentRole;

      if (currentUserModel == null) {
        setState(() => _users = []);
        return;
      }

      final bool isAbsoluteMaster = currentUserModel.email.toLowerCase() == 'danielledezmad9@gmail.com';
      final bool isAdminOrSuper = currentUserRole == AppRole.admin || currentUserRole == AppRole.superAdmin;

      List<UserModel> users = [];

      if (isAbsoluteMaster) {
        // La dueña absoluta de la aplicación ve todos los usuarios del sistema
        final allUsersSnapshot = await authProvider.getAllUsers();
        
        final selfIncluded = allUsersSnapshot.any((u) => u.uid == currentUserModel.uid);
        if (!selfIncluded) {
          users = [currentUserModel, ...allUsersSnapshot];
        } else {
          final withoutSelf = allUsersSnapshot.where((u) => u.uid != currentUserModel.uid).toList();
          users = [currentUserModel, ...withoutSelf];
        }
      } 
      else if (isAdminOrSuper) {
        // SOLUCIÓN DEFINITIVA: 
        // Sin importar si es SuperAdmin o Admin, solo puede ver a los usuarios 
        // que él mismo haya creado directamente desde su cuenta.
        final strictlyMyUsers = await authProvider.getUsersByCreator(currentUserModel.uid, currentUserModel.farmId);
        
        final selfIncluded = strictlyMyUsers.any((u) => u.uid == currentUserModel.uid);
        if (!selfIncluded) {
          users = [currentUserModel, ...strictlyMyUsers];
        } else {
          final withoutSelf = strictlyMyUsers.where((u) => u.uid != currentUserModel.uid).toList();
          users = [currentUserModel, ...withoutSelf];
        }
      } 
      else {
        // Roles sin acceso a gestión: solo se ven a sí mismos
        users = [currentUserModel];
      }

      setState(() {
        _users = users;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar usuarios: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateUserDialog(onUserCreated: _loadUsers),
    );
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => _EditUserDialog(user: user, onUserUpdated: _loadUsers),
    );
  }

  Future<void> _claimOrphanUsers() async {
    setState(() => _isLoading = true);
    try {
      final claimedCount = await context.read<AppAuthProvider>().claimOrphanUsers();
      if (mounted) {
        if (claimedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$claimedCount usuarios heredados asignados a ti exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron usuarios heredados sin asignar en tu granja.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        await _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (context.read<AppAuthProvider>().currentRole == AppRole.superAdmin || 
              context.read<AppAuthProvider>().user?.email.toLowerCase() == 'danielledezmad9@gmail.com')
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Reclamar usuarios sin creador asignado',
              onPressed: _claimOrphanUsers,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _users.isEmpty
                  ? _buildEmptyState()
                  : _buildUserList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red.shade700),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final currentUser = context.read<AppAuthProvider>().user;
    final isCurrentUser = currentUser?.uid == user.uid;
    final isSuperAdmin = user.role == AppRole.superAdmin;
    final isAdmin = user.role == AppRole.admin;
    final currentUserRole = currentUser?.role;
    final canManage = context.read<AppAuthProvider>().canManageUsers;
    
    // Super Admin puede gestionar a todos
    // Admin puede gestionar solo a Supervisor y Operador (no a otros Admins ni Super Admins)
    bool canEditUser = false;
    if (canManage) {
      if (currentUserRole == AppRole.superAdmin) {
        canEditUser = true;
      } else if (currentUserRole == AppRole.admin) {
        // Admin no puede editar a otros admins ni super admins
        canEditUser = !isAdmin && !isSuperAdmin;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: user.isActive 
              ? const Color(0xFF2E7D32) 
              : Colors.grey,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tú',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleChip(user.role),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 10,
                      color: user.isActive ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: (canEditUser && !isCurrentUser)
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditUserDialog(user);
                      break;
                    case 'toggle':
                      _toggleUserStatus(user);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.block : Icons.check,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(user.isActive ? 'Desactivar' : 'Activar'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildRoleChip(AppRole role) {
    Color color;
    switch (role) {
      case AppRole.superAdmin:
        color = Colors.purple;
        break;
      case AppRole.admin:
        color = Colors.blue;
        break;
      case AppRole.supervisor:
        color = Colors.orange;
        break;
      case AppRole.operador:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        RolePermissions.getRoleName(role),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final currentUser = context.read<AppAuthProvider>().user;
    if (currentUser?.uid == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes desactivar tu propia cuenta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isActive ? 'Desactivar Usuario' : 'Activar Usuario'),
        content: Text(
          user.isActive
              ? '¿Desactivar al usuario ${user.name}?'
              : '¿Activar al usuario ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<AppAuthProvider>().toggleUserStatus(user.uid, !user.isActive);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(user.isActive ? 'Usuario desactivado' : 'Usuario activado'),
              backgroundColor: Colors.green,
            ),
          );
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
}

class _CreateUserDialog extends StatefulWidget {
  final VoidCallback onUserCreated;

  const _CreateUserDialog({required this.onUserCreated});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AppRole _selectedRole = AppRole.operador;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AppAuthProvider>();
      final farmId = authProvider.currentFarmId;
      
      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        farmId: farmId,
      );

      if (mounted) {
        if (success) {
          widget.onUserCreated();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = authProvider.error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Error'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AppAuthProvider>().user;
    final currentUserRole = currentUser?.role;

    // Super Admin puede crear cualquier rol
    // Admin solo puede crear Supervisor y Operador
    List<AppRole> availableRoles;
    if (currentUserRole == AppRole.superAdmin) {
      availableRoles = AppRole.values;
    } else {
      availableRoles = [AppRole.supervisor, AppRole.operador];
    }

    return AlertDialog(
      title: const Text('Crear Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.trim().isEmpty == true) return 'Requerido';
                  if (!v!.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Requerido';
                  if (v!.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (v) {
                  if (v != _passwordController.text) return 'No coincide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
DropdownButtonFormField<AppRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.badge),
              ),
              items: availableRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(RolePermissions.getRoleName(role)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  RolePermissions.getRoleDescription(_selectedRole),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crear'),
        ),
      ],
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  final VoidCallback onUserUpdated;

  const _EditUserDialog({required this.user, required this.onUserUpdated});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late AppRole _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
    // Si el rol actual no está en los roles disponibles, usar el primero disponible
    final currentUser = context.read<AppAuthProvider>().user;
    final currentUserRole = currentUser?.role;
    List<AppRole> availableRoles;
    if (currentUserRole == AppRole.superAdmin) {
      availableRoles = AppRole.values;
    } else {
      availableRoles = [AppRole.supervisor, AppRole.operador];
    }
    if (!availableRoles.contains(_selectedRole)) {
      _selectedRole = availableRoles.first;
    }
  }

  Future<void> _updateUser() async {
    setState(() => _isLoading = true);

    try {
      await context.read<AppAuthProvider>().updateUserRole(widget.user.uid, _selectedRole);
      widget.onUserUpdated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AppAuthProvider>().user;
    final isCurrentUser = currentUser?.uid == widget.user.uid;
    final currentUserRole = currentUser?.role;

    // Super Admin puede asignar cualquier rol
    // Admin solo puede asignar Supervisor y Operador
    List<AppRole> availableRoles;
    if (currentUserRole == AppRole.superAdmin) {
      availableRoles = AppRole.values;
    } else {
      availableRoles = [AppRole.supervisor, AppRole.operador];
    }

    return AlertDialog(
      title: Text('Editar: ${widget.user.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(widget.user.name),
              subtitle: Text(widget.user.email),
            ),
            const Divider(),
            const SizedBox(height: 8),
            DropdownButtonFormField<AppRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.badge),
              ),
              items: availableRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(RolePermissions.getRoleName(role)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                RolePermissions.getRoleDescription(_selectedRole),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No puedes cambiar tu propio rol',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (isCurrentUser || _isLoading) ? null : _updateUser,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
