#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Установка OCRmyPDF + Poppler + Tesseract и правка pdf_parser.py
# ----------------------------------------------------------
PROJECT_DIR="${1:-.}"
echo "→ Переходим в директорию проекта: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 1) Системные зависимости
echo "→ apt-get update && install poppler-utils, ocrmypdf, tesseract"
sudo apt update
sudo apt install -y poppler-utils ocrmypdf tesseract-ocr tesseract-ocr-rus tesseract-ocr-eng

# 2) Активируем виртуальное окружение
if [[ -f "venv/bin/activate" ]]; then
  echo "→ Активируем виртуальное окружение"
  source venv/bin/activate
else
  echo "⚠️ Окружение venv не найдено, убедитесь, что оно есть и запустите скрипт заново."
  exit 1
fi

# 3) Устанавливаем Python-библиотеки для OCRmyPDF
echo "→ pip install ocrmypdf"
pip install --upgrade pip
pip install ocrmypdf

# 4) Правим services/pdf_parser.py
echo "→ Обновляем services/pdf_parser.py"
mkdir -p services
cat > services/pdf_parser.py << 'EOF'
import os
import tempfile
from typing import Tuple
import ocrmypdf
import pdfplumber

async def parse_pdf(path: str) -> Tuple[str, int]:
    """
    1) Сначала пытаемся извлечь текст обычным способом через pdfplumber.
    2) Если текст пустой — создаём временный PDF с OCR (OCRmyPDF) и снова вытягиваем текст.
    Возвращаем (text, page_count).
    """
    # Попытка обычного извлечения
    with pdfplumber.open(path) as pdf:
        pages = pdf.pages
        raw = "\n".join(p.extract_text() or "" for p in pages)
        if raw.strip():
            return raw, len(pages)

    # OCRmyPDF fallback
    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
        ocr_path = tmp.name
    # Добавляем текстовый слой в ocr_path
    ocrmypdf.ocr(path, ocr_path, language="rus+eng", force_ocr=True, skip_text=True)

    # Повторный парсинг
    with pdfplumber.open(ocr_path) as pdf:
        pages = pdf.pages
        text = "\n".join(p.extract_text() or "" for p in pages)
        count = len(pages)

    # Удаляем временный файл
    try:
        os.remove(ocr_path)
    except OSError:
        pass

    return text, count
EOF

echo "✅ services/pdf_parser.py настроен для OCRmyPDF + pdfplumber."
echo "🎉 Перезапустите бота: python main.py"
