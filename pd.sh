#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт, чтобы handle_paid в main.py отправлял PDF-отчёт, а не TXT
# ----------------------------------------------------------
MAIN="main.py"

if [[ ! -f "$MAIN" ]]; then
  echo "❌ $MAIN не найден. Запустите скрипт из корня проекта."
  exit 1
fi

# 1) Добавляем импорт генератора PDF, если нет
grep -q "generate_report_pdf" "$MAIN" \
  || sed -i "1ifrom services.report_generator import generate_report_pdf" "$MAIN"

# 2) Убедимся, что импорт FSInputFile есть
grep -q "FSInputFile" "$MAIN" \
  || sed -i "s/from aiogram.types import \(.*\)/from aiogram.types import \1, FSInputFile/" "$MAIN"

# 3) Патчим блок отправки результата
#    Ищем место, где отправляется TXT (оно между комментарием "# Отправляем результат" и os.remove)
#    и заменяем его на PDF-логику.
sed -i '/# Отправляем результат/,/os.remove(file_path)/c\
    # Генерируем PDF-отчёт и отправляем его пользователю\n\
    pdf_path = f"report_{doc_id}.pdf"\n\
    generate_report_pdf(doc, doc.analysis, pdf_path)\n\
    await callback.message.answer_document(\n\
        FSInputFile(pdf_path, filename=f"report_{doc_id}.pdf"),\n\
        caption="📄 Полный отчёт по анализу в PDF"\n\
    )\n\
    os.remove(pdf_path)' "$MAIN"

echo "✅ main.py обновлён: теперь отчёт отправляется в виде PDF."
echo "▶️ Перезапустите бота: python main.py"

