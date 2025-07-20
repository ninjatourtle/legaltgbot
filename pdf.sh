#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для добавления генерации PDF-отчётов в боте
# ----------------------------------------------------------

# Проверяем, что мы в корне проекта
[ -f "main.py" ] || { echo "❌ main.py не найден. Запустите скрипт из корня проекта."; exit 1; }

# 1) Устанавливаем зависимости
echo "📦 Обновляем requirements.txt и устанавливаем reportlab"
grep -qxF "reportlab>=3.6.12" requirements.txt \
  || { echo "reportlab>=3.6.12" >> requirements.txt; }
pip install reportlab

# 2) Добавляем сервис для генерации PDF
echo "🔧 Создаём services/report_generator.py"
mkdir -p services
cat > services/report_generator.py << 'EOF'
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import cm
from datetime import datetime

def generate_report_pdf(doc, analysis: dict, output_path: str):
    """
    Генерирует PDF-отчёт по анализу договора.
    """
    c = canvas.Canvas(output_path, pagesize=A4)
    width, height = A4

    # Заголовок
    c.setFont("Helvetica-Bold", 18)
    c.drawString(2*cm, height - 2*cm, "Отчёт по анализу договора")

    # Метаданные
    c.setFont("Helvetica", 10)
    c.drawString(2*cm, height - 3*cm, f"ID документа: {doc.id}")
    dt = doc.analyzed_at or datetime.utcnow()
    c.drawString(2*cm, height - 3.7*cm, f"Дата анализа: {dt.strftime('%Y-%m-%d %H:%M:%S')}")

    # Контент
    textobject = c.beginText(2*cm, height - 5*cm)
    textobject.setFont("Helvetica", 12)
    summary = analysis.get("result", "")
    for line in summary.split("\n"):
        textobject.textLine(line)
        # если доходим до низа страницы
        if textobject.getY() < 2*cm:
            c.drawText(textobject)
            c.showPage()
            textobject = c.beginText(2*cm, height - 2*cm)
            textobject.setFont("Helvetica", 12)
    c.drawText(textobject)

    c.save()
EOF

# 3) Импортируем в main.py
echo "🔧 Вносим импорт generate_report_pdf в main.py"
grep -q "generate_report_pdf" main.py \
  || sed -i "1ifrom services.report_generator import generate_report_pdf" main.py

# 4) Заменяем отправку текстового файла на отправку PDF
echo "🔧 Правим handle_paid в main.py"
# Заменяем блок между комментариями
sed -i '/# Отправляем результат как файл/,/os.remove(file_path)/c\
    # Генерируем PDF-отчёт и отправляем его пользователю\n\
    pdf_path = f"report_{doc_id}.pdf"\n\
    generate_report_pdf(doc, doc.analysis, pdf_path)\n\
    await callback.message.answer_document(\n\
        FSInputFile(pdf_path, filename=f"report_{doc_id}.pdf"),\n\
        caption="📄 Полный отчёт по анализу в PDF"\n\
    )\n\
    os.remove(pdf_path)' main.py

# 5) Убедимся, что импорт FSInputFile есть
echo "🔧 Добавляем импорт FSInputFile, если нужно"
grep -q "FSInputFile" main.py \
  || sed -i 's/from aiogram.types import \(.*\)/from aiogram.types import \1, FSInputFile/' main.py

echo "✅ PDF-отчёты настроены. Перезапустите бота: python main.py"

