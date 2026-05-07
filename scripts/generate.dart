import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args[0].toLowerCase();
  switch (command) {
    case 'feature':
      if (args.length != 2) {
        _printUsage();
        return;
      }
      generateFeature(args[1]);
      return;
    case 'service':
      if (args.length != 2) {
        _printUsage();
        return;
      }
      generateService(args[1]);
      return;
    case 'help':
    case '--help':
    case '-h':
      _printUsage();
      return;
    default:
      print('❌ Unknown command: "$command"');
      _printUsage();
      return;
  }
}

void _printUsage() {
  print('Usage:');
  print('  dart run scripts/generate.dart feature <feature_name>');
  print('  dart run scripts/generate.dart service <service_name>');
  print('');
  print('Examples:');
  print('  dart run scripts/generate.dart feature habits');
  print('  dart run scripts/generate.dart service auth');
}

String _normalizeName(String input) => input.trim().toLowerCase();

void generateFeature(String featureName) {
  final name = _normalizeName(featureName);
  if (name.isEmpty) {
    _printUsage();
    return;
  }

  final basePath = p.join('lib', 'features', name);

  // 1. Create directories
  Directory(p.join(basePath, 'providers')).createSync(recursive: true);
  Directory(p.join(basePath, 'repository')).createSync(recursive: true);
  Directory(p.join(basePath, 'models')).createSync(recursive: true);
  Directory(p.join(basePath, 'widgets')).createSync(recursive: true);

  // 2. Create files
  createFile(p.join(basePath, '${name}_screen.dart'), screenTemplate(name));
  createFile(p.join(basePath, 'providers', '${name}_provider.dart'), providerTemplate(name));
  createFile(
    p.join(basePath, 'repository', '${name}_repository.dart'),
    repositoryTemplate(name),
  );
  createFile(p.join(basePath, 'models', '${name}_model.dart'), modelTemplate(name));

  print('✅ Feature "$name" successfully generated at $basePath!');
  print('🚀 Don\'t forget to run build_runner: dart run build_runner build -d');
}

void createFile(String path, String content) {
  final file = File(path);
  if (file.existsSync()) {
    print('⚠️ Skipped (already exists): $path');
    return;
  }
  file.writeAsStringSync(content);
}

void generateService(String serviceName) {
  final name = _normalizeName(serviceName);
  if (name.isEmpty) {
    _printUsage();
    return;
  }

  final directoryPath = p.join('lib', 'core', 'services');
  final filePath = p.join(directoryPath, '${name}_service.dart');

  Directory(directoryPath).createSync(recursive: true);
  createFile(filePath, serviceTemplate(name));

  print('✅ Service "${_toPascalCase(name)}Service" generated at $filePath');
  print('🚀 Don\'t forget to run build_runner: dart run build_runner build -d');
}

// ==========================================
// TEMPLATES
// ==========================================

String screenTemplate(String name) {
  final pascalCase = _toPascalCase(name);
  return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/${name}_provider.dart';

class ${pascalCase}Screen extends ConsumerWidget {
  const ${pascalCase}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the state from the provider
    final state = ref.watch(${name}NotifierProvider);

    return SafeArea(
      child: state.when(
        data: (data) => _buildContent(context, ref, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: \$error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${pascalCase} Screen', style: Theme.of(context).textTheme.titleLarge),
        // Add your feature-specific widgets here
      ],
    );
  }
}
''';
}

String providerTemplate(String name) {
  final pascalCase = _toPascalCase(name);
  return '''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/${name}_repository.dart';

part '${name}_provider.g.dart';

@riverpod
class ${pascalCase}Notifier extends _\$${pascalCase}Notifier {
  @override
  FutureOr<dynamic> build() async {
    // Initial data loading
    return _fetchData();
  }

  Future<dynamic> _fetchData() async {
    final repository = ref.read(${name}RepositoryProvider);
    // TODO: Implement actual data fetching
    // return await repository.getData();
    return null; 
  }

  // Example of a state mutation method
  Future<void> performAction() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(${name}RepositoryProvider);
      // await repository.doSomething();
      
      // Refresh data after action
      state = AsyncData(await _fetchData());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
''';
}

String repositoryTemplate(String name) {
  final pascalCase = _toPascalCase(name);
  return '''
import 'package:feature_first_example/core/api/api_client.dart';
import 'package:feature_first_example/core/api/http_pod.dart';
import 'package:feature_first_example/core/utils/talker_pod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part '${name}_repository.g.dart';

class ${pascalCase}Repository {
  ${pascalCase}Repository(this._api, this._talker);

  final ApiClient _api;
  final Talker _talker;

  // TODO: add methods using _api; on failure log with _talker and rethrow / map errors
}

@Riverpod(keepAlive: true)
${pascalCase}Repository ${name}Repository(Ref ref) {
  return ${pascalCase}Repository(
    ref.watch(apiClientProvider),
    ref.watch(talkerProvider),
  );
}
''';
}

String modelTemplate(String name) {
  final pascalCase = _toPascalCase(name);
  return '''
/// Data model for [$name]. Add [fromJson] when the API shape is known
/// (or switch to `freezed` + `json_serializable` if you want codegen).
class ${pascalCase}Model {
  const ${pascalCase}Model({required this.id});

  final String id;
}
''';
}

String serviceTemplate(String name) {
  final className = _toPascalCase(name);
  return '''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';
import '../utils/talker_pod.dart';

part '${name}_service.g.dart';

class ${className}Service {
  ${className}Service(this._talker);

  final Talker _talker;

  void init() {
    _talker.info('${className}Service initialized');
  }
}

@Riverpod(keepAlive: true)
${className}Service ${name}Service(Ref ref) {
  return ${className}Service(
    ref.watch(talkerProvider),
  );
}
''';
}

// Helper function to convert snake_case to PascalCase
String _toPascalCase(String text) {
  if (text.isEmpty) return text;
  return text.split('_').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join('');
}