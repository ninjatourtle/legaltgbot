import os
from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML
from pathlib import Path

env = Environment(
    loader=FileSystemLoader(Path(__file__).parent),
    autoescape=True
)

def generate_report_pdf(doc, analysis: dict, output_path: str):
    # Prepare data for chart and accordion
    risks = {
        "legal": analysis.get("legal_risk_pct", 0),
        "financial": analysis.get("financial_risk_pct", 0),
        "operational": analysis.get("operational_risk_pct", 0),
    }
    sections = [
        {
            "title": "Юридические риски",
            "score": risks["legal"],
            "summary": analysis.get("legal_summary", ""),
            "details": analysis.get("legal_details", ""),
        },
        {
            "title": "Финансовые риски",
            "score": risks["financial"],
            "summary": analysis.get("financial_summary", ""),
            "details": analysis.get("financial_details", ""),
        },
        {
            "title": "Операционные риски",
            "score": risks["operational"],
            "summary": analysis.get("operational_summary", ""),
            "details": analysis.get("operational_details", ""),
        },
    ]
    template = env.get_template("report_template.html")
    html_str = template.render(doc=doc, risks=risks, sections=sections)
    HTML(string=html_str).write_pdf(output_path)
