import docx

async def parse_docx(path: str) -> tuple[str, int]:
    doc = docx.Document(path)
    paras = [p.text for p in doc.paragraphs]
    text = "\\n".join(paras)
    word_count = len(text.split())
    page_count = max(1, word_count // 300)
    return text, page_count
