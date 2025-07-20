#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для установки OCR-зависимостей и правки pdf_parser.py
# ----------------------------------------------------------

# Параметры
PROJECT_DIR="${1:-.}"

echo "🚀 Переходим в директорию проекта: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 1) Устанавливаем системные зависимости для OCR
echo "📦 apt-get update && install poppler-utils, tesseract-ocr, rus"
sudo apt update
sudo apt install -y poppler-utils tesseract-ocr tesseract-ocr-rus libtesseract-dev

# 2) Активируем виртуальное окружение
if [[ -f "venv/bin/activate" ]]; then
  echo "🐍 Активируем virtualenv"
  # shellcheck disable=SC1091
  source venv/bin/activate
else
  echo "⚠️ Виртуальное окружение venv не найдено. Создайте и активируйте его перед запуском."
  exit 1
fi

# 3) Устанавливаем Python-зависимости для OCR
echo "📦 pip install pdf2image pytesseract pillow"
pip install --upgrade pip
pip install pdf2image pytesseract pillow

# 4) Перезаписываем services/pdf_parser.py с поддержкой OCR
echo "🔧 Обновляем services/pdf_parser.py"
mkdir -p services
cat > services/pdf_parser.py << 'EOF'
import os
from typing import Tuple

# pdf2image + pytesseract для OCR
from pdf2image import convert_from_path
import pytesseract

async def parse_pdf(path: str) -> Tuple[str, int]:
    """
    Сначала пробуем вытянуть «чистый» текст через pdfplumber.
    Если он пустой — используем OCR через Tesseract.
    Возвращаем кортеж (text, page_count).
    """
    raw = ""
    try:
        import pdfplumber
        with pdfplumber.open(path) as pdf:
            pages = pdf.pages
            raw = "\\n".join(p.extract_text() or "" for p in pages)
            if raw.strip():
                return raw, len(pages)
    except Exception:
        raw = ""

    # OCR fallback: конвертация страниц в изображения и распознавание
    images = convert_from_path(path, dpi=300)
    ocr_texts = []
    for img in images:
        text = pytesseract.image_to_string(img, lang="rus+eng")
        ocr_texts.append(text)
    full_text = "\\n".join(ocr_texts).strip()
    return full_text, len(images)
EOF

echo "✅ services/pdf_parser.py обновлён."

# 5) Завершаем
echo "🎉 Все зависимости установлены, и OCR-парсер готов к работе!"
echo "Не забудьте перезапустить бота: python main.py"

