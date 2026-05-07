import 'dart:io';

void main() async {
  final i18nDir = Directory('lib/i18n');
  final slangYaml = File('slang.yaml');

  if (!i18nDir.existsSync()) {
    i18nDir.createSync(recursive: true);
  }

  if (!slangYaml.existsSync()) {
    // --- 1. FIRST SETUP ---
    stdout.write('Enter BASE language code (e.g. en, uk, de): ');
    final lang = stdin.readLineSync()?.trim().toLowerCase();

    if (lang == null || lang.isEmpty) {
      print('Error: Language code cannot be empty.');
      return;
    }

    print('Setting up base language: $lang');

    slangYaml.writeAsStringSync('''
base_locale: $lang
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n
''');

    final baseFile = File('lib/i18n/strings.i18n.json');
    baseFile.writeAsStringSync('''
{
  "home": {
    "title": "Home"
  }
}
''');
  } else {
    // --- 2. MENU FOR EXISTING SETUP ---
    print('\nLocalization is already configured.');
    print('1. Add a new language');
    print('2. Change the base language');
    stdout.write('Choose an option (1 or 2): ');

    final choice = stdin.readLineSync()?.trim();

    if (choice == '1') {
      // Add new language
      stdout.write('Enter NEW language code (e.g. en, uk, de): ');
      final lang = stdin.readLineSync()?.trim().toLowerCase();

      if (lang == null || lang.isEmpty) return;

      final newFile = File('lib/i18n/strings_$lang.i18n.json');
      if (newFile.existsSync()) {
        print('Warning: Language file already exists.');
        return;
      }

      newFile.writeAsStringSync('''
{
  "home": {
    "title": "Home ($lang)"
  }
}
''');
      print('Added new language: $lang');

    } else if (choice == '2') {
      // Change base language
      stdout.write('Enter NEW base language code (e.g. en, uk): ');
      final newBase = stdin.readLineSync()?.trim().toLowerCase();

      if (newBase == null || newBase.isEmpty) return;

      final yamlContent = slangYaml.readAsStringSync();
      final baseLocaleMatch = RegExp(r'base_locale:\s*([a-z]+)').firstMatch(yamlContent);

      if (baseLocaleMatch == null) {
        print('Error: Could not find base_locale in slang.yaml');
        return;
      }

      final oldBase = baseLocaleMatch.group(1)!;

      if (oldBase == newBase) {
        print('The base language is already $newBase.');
        return;
      }

      // Rename current base file to its specific language name
      final currentBaseFile = File('lib/i18n/strings.i18n.json');
      if (currentBaseFile.existsSync()) {
        currentBaseFile.renameSync('lib/i18n/strings_$oldBase.i18n.json');
      }

      // Rename or create the new base file
      final targetNewBaseFile = File('lib/i18n/strings_$newBase.i18n.json');
      if (targetNewBaseFile.existsSync()) {
        targetNewBaseFile.renameSync('lib/i18n/strings.i18n.json');
      } else {
        File('lib/i18n/strings.i18n.json').writeAsStringSync('''
{
  "home": {
    "title": "Home ($newBase)"
  }
}
''');
      }

      // Update slang.yaml config
      final newYaml = yamlContent.replaceFirst('base_locale: $oldBase', 'base_locale: $newBase');
      slangYaml.writeAsStringSync(newYaml);

      print('Base language successfully changed from $oldBase to $newBase.');
    } else {
      print('Invalid choice. Exiting.');
      return;
    }
  }

  // --- 3. GENERATE DART CLASSES ---
  print('\nGenerating Dart classes...');
  final result = await Process.run('dart', ['run', 'slang']);

  if (result.stdout.toString().isNotEmpty) {
    print(result.stdout);
  }
  if (result.stderr.toString().isNotEmpty) {
    print('Errors:\n${result.stderr}');
  }

  print('✅ Done!');
}