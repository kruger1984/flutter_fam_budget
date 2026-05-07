#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Flutter Project Post-Setup"
echo "============================="

echo "1. flutter clean..."
flutter clean

echo "2. Installing dependencies..."
flutter pub get

echo "3. Generating translations (slang)..."
dart run slang

echo "4. Running build_runner..."
dart run build_runner build --delete-conflicting-outputs

echo "5. Generating launcher icons..."
if [[ -f "flutter_launcher_icons.yaml" ]]; then
    flutter pub run flutter_launcher_icons
else
    echo "   (flutter_launcher_icons.yaml not found - skipped)"
fi

echo
echo "✅ Все готово! Тепер можна запускати проект."
echo "   Команда: flutter run"