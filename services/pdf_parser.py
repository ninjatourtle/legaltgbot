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
    ocrmypdf.ocr(path, ocr_path, language="rus+eng", force_ocr=True)

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
