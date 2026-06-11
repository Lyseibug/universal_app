/// Version Management Configuration
/// 
/// This file centralizes all version management settings.
/// Change these values to test different scenarios and environments.

class VersionConfig {
  VersionConfig._(); // Private constructor to prevent instantiation

  /// Version check mode
  /// 
  /// Supported values:
  /// - 'mock'       → Use local JSON files from assets/mock/
  /// - 'localhost'  → Use local Node.js server (http://localhost:3000)
  /// - 'production' → Use production ERP API endpoint
  static const String mode = 'mock';

  /// Mock scenario for testing
  /// Only used when mode = 'mock' or mode = 'localhost'
  /// 
  /// Supported values:
  /// - 'up_to_date'       → App is latest version
  /// - 'update_available' → Optional update available
  /// - 'force_update'     → Critical update required
  static const String mockScenario = 'up_to_date';

  /// Localhost configuration
  static const String localhostHost = 'localhost';
  static const int localhostPort = 3000;
  static const String localhostUrl = 'http://localhost:3000/api/version';

  /// For Android emulator, use special IP
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000/api/version';

  /// Production ERP API endpoint
  static const String productionEndpoint = '/api/method/app_version_check';

  /// Version check timeout (in seconds)
  static const int timeoutSeconds = 10;

  /// Auto-check version on app startup
  static const bool autoCheckOnStartup = true;

  /// Show version check dialogs
  static const bool showDialogs = true;

  /// Logging level for version management
  /// - 'verbose' → Log everything
  /// - 'debug'   → Log debug info
  /// - 'info'    → Log important info only
  /// - 'warning' → Log warnings and errors only
  /// - 'error'   → Log errors only
  static const String logLevel = 'debug';

  /// Display mock server URLs in UI (for debugging)
  static const bool showServerUrlInUI = true;

  // ============================================================================
  // QUICK SWITCH PRESETS
  // ============================================================================

  /// Preset: Development (Mock mode)
  static void setDevelopmentMode() {
    // Just change the values above to:
    // mode = 'mock'
    // mockScenario = 'up_to_date'
    // autoCheckOnStartup = true
    // showDialogs = true
  }

  /// Preset: Testing (Localhost)
  static void setTestingMode() {
    // Just change the values above to:
    // mode = 'localhost'
    // mockScenario = 'update_available'
    // autoCheckOnStartup = true
    // showDialogs = true
  }

  /// Preset: Production
  static void setProductionMode() {
    // Just change the values above to:
    // mode = 'production'
    // autoCheckOnStartup = true
    // showDialogs = true
    // logLevel = 'warning'
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get the full version check URL based on current configuration
  static String getVersionCheckUrl() {
    switch (mode) {
      case 'localhost':
        return localhostUrl;
      case 'mock':
        return 'assets/mock/version_$mockScenario.json'; // Local asset
      case 'production':
        return productionEndpoint;
      default:
        return localhostUrl;
    }
  }

  /// Get a human-readable description of current configuration
  static String getConfigDescription() {
    return '''
Version Management Configuration:
├── Mode: $mode
├── Mock Scenario: $mockScenario
├── Localhost: $localhostUrl
├── Auto-check on startup: $autoCheckOnStartup
├── Show dialogs: $showDialogs
└── Log level: $logLevel
''';
  }

  /// Validate configuration
  static List<String> validateConfig() {
    final errors = <String>[];

    if (!['mock', 'localhost', 'production'].contains(mode)) {
      errors.add('Invalid mode: $mode. Use "mock", "localhost", or "production"');
    }

    if (mode != 'production' &&
        !['up_to_date', 'update_available', 'force_update']
            .contains(mockScenario)) {
      errors.add(
          'Invalid mockScenario: $mockScenario. Use "up_to_date", "update_available", or "force_update"');
    }

    if (localhostPort <= 0 || localhostPort > 65535) {
      errors.add('Invalid localhost port: $localhostPort (1-65535)');
    }

    if (!['verbose', 'debug', 'info', 'warning', 'error']
        .contains(logLevel)) {
      errors.add(
          'Invalid logLevel: $logLevel. Use "verbose", "debug", "info", "warning", or "error"');
    }

    return errors;
  }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
// Example 1: Get current configuration
String url = VersionConfig.getVersionCheckUrl();
print(VersionConfig.getConfigDescription());

// Example 2: Validate configuration before running
List<String> errors = VersionConfig.validateConfig();
if (errors.isNotEmpty) {
  print('Configuration errors:');
  for (String error in errors) {
    print('  - $error');
  }
}

// Example 3: Check which mode is active
if (VersionConfig.mode == 'mock') {
  print('Using mock data');
} else if (VersionConfig.mode == 'localhost') {
  print('Using localhost server');
} else if (VersionConfig.mode == 'production') {
  print('Using production API');
}

// Example 4: Quick mode switching (edit values above instead)
// VersionConfig.setDevelopmentMode();  // Use mock
// VersionConfig.setTestingMode();      // Use localhost
// VersionConfig.setProductionMode();   // Use production ERP
*/
