#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Script to integrate Shards Dashboard Lite into HTML→PDF report
# ----------------------------------------------------------

# 1) Install Python dependencies
echo "→ Installing Jinja2 and WeasyPrint…"
pip install --upgrade pip
pip install jinja2 weasyprint

# 2) Create HTML template for Shards Dashboard Lite
echo "→ Writing services/report_template.html…"
mkdir -p services
cat > services/report_template.html << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Отчёт по анализу договора</title>
  <!-- Shards UI / Dashboard Lite CSS -->
  <link
    rel="stylesheet"
    href="https://unpkg.com/shards-ui@3.0.0/dist/css/shards.min.css" />
  <link
    rel="stylesheet"
    href="https://unpkg.com/shards-dashboard-lite/dist/css/shards-dashboard-lite.min.css" />
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif; }
    .page-header { margin-bottom: 2rem; }
    .chart-container { width: 200px; margin: auto; }
    .card-small { padding: 1rem; }
  </style>
</head>
<body class="shards-dashboard--lite">
  <div class="container-fluid p-4">
    <div class="page-header">
      <h1 class="page-title">Отчёт по анализу договора №{{ doc.id }}</h1>
      <span class="text-muted">Дата: {{ doc.analyzed_at.strftime('%Y-%m-%d %H:%M') }}</span>
    </div>
    <div class="row">
      <div class="col-lg-4 col-md-6 mb-4">
        <div class="card card-small">
          <div class="card-body text-center">
            <div class="chart-container">
              <canvas id="riskChart"></canvas>
            </div>
          </div>
        </div>
      </div>
      <div class="col-lg-8 col-md-6 mb-4">
        <div class="accordion" id="analysisAccordion">
          {% for sec in sections %}
          <div class="card mb-2">
            <div class="card-header p-2" id="heading{{ loop.index }}">
              <button
                class="btn btn-link btn-block text-left"
                type="button"
                data-toggle="collapse"
                data-target="#collapse{{ loop.index }}"
                aria-expanded="false"
                aria-controls="collapse{{ loop.index }}">
                {{ sec.title }} — <strong>{{ sec.score }}%</strong>
              </button>
            </div>
            <div
              id="collapse{{ loop.index }}"
              class="collapse"
              aria-labelledby="heading{{ loop.index }}"
              data-parent="#analysisAccordion">
              <div class="card-body">
                <p><strong>Кратко:</strong> {{ sec.summary }}</p>
                <p><strong>Подробно:</strong> {{ sec.details }}</p>
              </div>
            </div>
          </div>
          {% endfor %}
        </div>
      </div>
    </div>
  </div>
  <script>
    const data = {
      labels: ['Юридические','Финансовые','Операционные'],
      datasets: [{
        data: [{{ risks.legal }}, {{ risks.financial }}, {{ risks.operational }}],
        backgroundColor: ['#4CAF50','#FFC107','#2196F3']
      }]
    };
    const config = { type: 'doughnut', data: data, options: { cutout: '70%' } };
    window.addEventListener('load', () => {
      const ctx = document.getElementById('riskChart').getContext('2d');
      new Chart(ctx, config);
    });
  </script>
</body>
</html>
EOF

# 3) Create the HTML→PDF generator
echo "→ Writing services/html_report_generator.py…"
cat > services/html_report_generator.py << 'EOF'
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
EOF

# 4) Patch main.py: add import and adjust handle_paid
MAIN="main.py"
echo "→ Patching $MAIN…"

# a) import generate_report_pdf
grep -q "from services.html_report_generator import generate_report_pdf" $MAIN \
  || sed -i "1ifrom services.html_report_generator import generate_report_pdf" $MAIN

# b) ensure FSInputFile import
grep -q "FSInputFile" $MAIN \
  || sed -i "s/from aiogram.types import \(.*\)/from aiogram.types import \1, FSInputFile/" $MAIN

# c) replace PDF sending block in handle_paid
sed -i '/generate_report_pdf/,/os.remove/ c\
    pdf_path = f"report_{doc_id}.pdf"\n\
    generate_report_pdf(doc, doc.analysis, pdf_path)\n\
    await callback.message.answer_document(\n\
        FSInputFile(pdf_path, filename=f"report_{doc_id}.pdf"),\n\
        caption="📄 Полный отчёт по анализу"\n\
    )\n\
    os.remove(pdf_path)' $MAIN

echo "✅ Shards Dashboard Lite integration complete. Restart the bot: python main.py"

