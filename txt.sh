#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для правки main.py: отправка результата анализа как файл
# ----------------------------------------------------------
FILE="main.py"

if [[ ! -f "$FILE" ]]; then
  echo "⚠️ Ошибка: $FILE не найден в текущей директории."
  exit 1
fi

# 1) Добавляем import os, если он отсутствует
if ! grep -q "^import os" "$FILE"; then
  sed -i "2iimport os" "$FILE"
  echo "Добавлен импорт os"
fi

# 2) Заменяем строку отправки текста на логику отправки файла
sed -i '/await callback.message.answer(f"<b>Результат анализа:/c\
        # Сохраняем результат анализа во временный файл\n\
        file_path = f"analysis_{doc.id}.txt"\n\
        with open(file_path, "w", encoding="utf-8") as f:\n\
            f.write(result)\n\
        # Отправляем файл пользователю\n\
        await callback.message.answer_document(\n\
            types.InputFile(path_or_bytesio=file_path, filename="analysis.txt"),\n\
            caption="📄 Результат анализа в файле"\n\
        )\n\
        # Удаляем временный файл\n\
        os.remove(file_path)' "$FILE"

echo "✅ main.py обновлён: теперь результат анализа отправляется как файл."
echo "Не забудьте перезапустить бота: python main.py"

