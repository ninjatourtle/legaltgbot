#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для исправления вызова ocrmypdf в services/pdf_parser.py:
# убираем конфликтующие флаги --force-ocr и --skip-text
# ----------------------------------------------------------

FILE="services/pdf_parser.py"

if [[ ! -f "$FILE" ]]; then
  echo "⚠️ Ошибка: файл $FILE не найден. Запустите скрипт из корня проекта."
  exit 1
fi

# Заменяем строку с двумя флагами на один force_ocr=True
sed -i \
  's/ocrmypdf\.ocr(path, ocr_path, language="rus+eng", force_ocr=True, skip_text=True)/ocrmypdf.ocr(path, ocr_path, language="rus+eng", force_ocr=True)/' \
  "$FILE"

echo "✅ Вызов ocrmypdf.ocr обновлён: теперь используется только force_ocr=True."
echo "Перезапустите бота: python main.py"

