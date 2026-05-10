enum AppRole {
  superAdmin,
  admin,
  operador,
  supervisor,
}

class Permission {
  static const String manageUsers = 'manage_users';
  static const String generateCodes = 'generate_codes';
  static const String systemConfig = 'system_config';
  static const String manageEggProduction = 'manage_egg_production';
  static const String manageFeedConsumption = 'manage_feed_consumption';
  static const String viewHistory = 'view_history';
  static const String accessAlerts = 'access_alerts';
  static const String manageLots = 'manage_lots';
  static const String manageHealth = 'manage_health';
  static const String manageVaccination = 'manage_vaccination';
  static const String manageFeeding = 'manage_feeding';
  static const String manageInventory = 'manage_inventory';
  static const String manageEggSales = 'manage_egg_sales';
  static const String manageMortality = 'manage_mortality';
  static const String manageExpenses = 'manage_expenses';
  static const String monitoring = 'monitoring';
  static const String viewReports = 'view_reports';
}

class RolePermissions {
  static final Map<AppRole, Set<String>> rolePermissions = {
    AppRole.superAdmin: {
      Permission.manageUsers,
      Permission.generateCodes,
      Permission.systemConfig,
      Permission.manageEggProduction,
      Permission.manageFeedConsumption,
      Permission.viewHistory,
      Permission.accessAlerts,
      Permission.manageLots,
      Permission.manageHealth,
      Permission.manageVaccination,
      Permission.manageFeeding,
      Permission.manageInventory,
      Permission.manageEggSales,
      Permission.manageMortality,
      Permission.manageExpenses,
      Permission.monitoring,
      Permission.viewReports,
    },
    AppRole.admin: {
      Permission.manageUsers,
      Permission.systemConfig,
      Permission.manageEggProduction,
      Permission.manageFeedConsumption,
      Permission.viewHistory,
      Permission.accessAlerts,
      Permission.manageLots,
      Permission.manageHealth,
      Permission.manageVaccination,
      Permission.manageFeeding,
      Permission.manageInventory,
      Permission.manageEggSales,
      Permission.manageMortality,
      Permission.manageExpenses,
      Permission.monitoring,
      Permission.viewReports,
    },
    AppRole.supervisor: {
      Permission.manageLots,
      Permission.manageHealth,
      Permission.manageVaccination,
      Permission.manageFeeding,
      Permission.manageInventory,
      Permission.manageEggProduction,
      Permission.manageEggSales,
      Permission.manageMortality,
      Permission.manageExpenses,
      Permission.monitoring,
      Permission.viewHistory,
      Permission.accessAlerts,
      Permission.viewReports,
    },
    AppRole.operador: {
      Permission.manageEggProduction,
      Permission.manageFeedConsumption,
      Permission.viewHistory,
      Permission.accessAlerts,
    },
  };

  static Set<String> getPermissions(AppRole role) {
    return rolePermissions[role] ?? {};
  }

  static bool hasPermission(AppRole role, String permission) {
    return rolePermissions[role]?.contains(permission) ?? false;
  }

  static String getRoleName(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return 'Super Administrador';
      case AppRole.admin:
        return 'Administrador';
      case AppRole.supervisor:
        return 'Supervisor';
      case AppRole.operador:
        return 'Operador';
    }
  }

  static String getRoleDescription(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return 'Acceso total al sistema, gestión de usuarios y códigos de instalación';
      case AppRole.admin:
        return 'Acceso completo a todos los módulos excepto generación de códigos';
      case AppRole.supervisor:
        return 'Acceso a operaciones, lotes, salud, inventario y ventas';
      case AppRole.operador:
        return 'Acceso limitado a producción, consumo y alertas';
    }
  }

  static AppRole? roleFromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
        return AppRole.superAdmin;
      case 'admin':
        return AppRole.admin;
      case 'supervisor':
        return AppRole.supervisor;
      case 'operador':
      case 'operator':
        return AppRole.operador;
      default:
        return null;
    }
  }

  static String roleToString(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
        return 'superAdmin';
      case AppRole.admin:
        return 'admin';
      case AppRole.supervisor:
        return 'supervisor';
      case AppRole.operador:
        return 'operador';
    }
  }
}
