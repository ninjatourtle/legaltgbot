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
