import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const String stubsPath = 'scripts/stubs';

void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args[0].toLowerCase();
  switch (command) {
    case 'feature':
      if (args.length < 2) {
        _printUsage();
        return;
      }
      final isPlain = args.contains('--plain');
      generateFeature(args[1], useFreezed: !isPlain);
      break;
    case 'service':
      if (args.length < 2) {
        _printUsage();
        return;
      }
      generateService(args[1]);
      break;
    default:
      print('❌ Unknown command: "$command"');
      _printUsage();
  }
}

void generateFeature(String featureName, {bool useFreezed = true}) {
  final name = featureName.trim().toLowerCase();
  final pascal = _toPascalCase(name);
  final package = _getProjectName();
  final basePath = p.join('lib', 'features', name);

  final replacements = {
    'name': name,
    'pascalCase': pascal,
    'package': package,
  };

  // 1. Создаем папки
  for (var dir in ['providers', 'repository', 'models', 'widgets']) {
    Directory(p.join(basePath, dir)).createSync(recursive: true);
  }

  // 2. Генерируем файлы
  _createFile(p.join(basePath, '${name}_screen.dart'), _loadStub('screen.stub', replacements));
  _createFile(p.join(basePath, 'providers', '${name}_pod.dart'), _loadStub('pod.stub', replacements));
  _createFile(p.join(basePath, 'repository', '${name}_repository.dart'), _loadStub('repository.stub', replacements));

  final modelStub = useFreezed ? 'model_freezed.stub' : 'model_plain.stub';
  _createFile(p.join(basePath, 'models', '${name}.dart'), _loadStub(modelStub, replacements));

  print('✅ Feature "$name" generated at $basePath');
  if (useFreezed) print('📦 Using Freezed model');
  print('‼️ Don`t forget run command to generate: dart run build_runner build -d');
}

void generateService(String serviceName) {
  final name = serviceName.trim().toLowerCase();
  final replacements = {
    'name': name,
    'pascalCase': _toPascalCase(name),
  };

  final dir = p.join('lib', 'core', 'services');
  Directory(dir).createSync(recursive: true);

  _createFile(p.join(dir, '${name}_service.dart'), _loadStub('service.stub', replacements));
  print('✅ Service "${_toPascalCase(name)}Service" generated!');
}

// --- Helpers ---

String _loadStub(String fileName, Map<String, String> replacements) {
  final file = File(p.join(stubsPath, fileName));
  if (!file.existsSync()) {
    print('❌ Error: Stub file missing at ${file.path}');
    exit(1);
  }

  String content = file.readAsStringSync();
  replacements.forEach((key, value) {
    content = content.replaceAll('{{$key}}', value);
  });
  return content;
}

void _createFile(String path, String content) {
  final file = File(path);
  if (file.existsSync()) {
    print('⚠️ Skipped: $path (exists)');
    return;
  }
  file.writeAsStringSync(content);
}

String _toPascalCase(String text) => text.split('_').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join('');

String _getProjectName() {
  try {
    final doc = loadYaml(File('pubspec.yaml').readAsStringSync());
    return doc['name'];
  } catch (_) {
    return 'my_project';
  }
}

void _printUsage() {
  print('\n🚀 Flutter Code Generator');
  print('Usage:');
  print('  dart run scripts/generate.dart feature <name> [--plain]');
  print('  dart run scripts/generate.dart service <name>');
}