#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для исправления main.py: использование FSInputFile вместо InputFile
# ----------------------------------------------------------
MAIN="main.py"

if [[ ! -f "$MAIN" ]]; then
  echo "❌ Файл $MAIN не найден. Запустите скрипт из корня проекта."
  exit 1
fi

# 1) Добавляем импорт FSInputFile рядом с InlineKeyboardButton
if ! grep -q "FSInputFile" "$MAIN"; then
  sed -i \
    's|from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton|from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton, FSInputFile|' \
    "$MAIN"
  echo "ℹ️ Добавлен импорт FSInputFile"
fi

# 2) Заменяем types.InputFile(...) на FSInputFile(...)
sed -i \
  's|types\.InputFile(path_or_bytesio=\([^,)]*\), filename="\([^"]*\)")|FSInputFile(\1, filename="\2")|' \
  "$MAIN"

echo "✅ main.py обновлён: теперь результат анализа отправляется с помощью FSInputFile."
echo "▶️ Перезапустите бота: python main.py"

