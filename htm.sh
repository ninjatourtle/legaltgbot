#!/usr/bin/env bash
set -e

# ----------------------------------------------------------
# Скрипт для интеграции Shards Dashboard Lite в HTML-шаблон отчёта
# ----------------------------------------------------------

# 1) Устанавливаем Python-зависимости (если ещё не установлены)
echo "→ Устанавливаем Jinja2 и WeasyPrint"
pip install jinja2 weasyprint

# 2) Создаём или перезаписываем HTML-шаблон с Shards Dashboard Lite
echo "→ Создаём services/report_template.html"
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
    href="https://cdnjs.cloudflare.com/ajax/libs/shards-ui/3.0.0/css/shards-extras.min.css"
    integrity="sha512-..." crossorigin="anonymous" />
  <!-- Dashboard Lite extra styles (если требуется) -->
  <link
    rel="stylesheet"
    href="https://unpkg.com/shards-dashboard-lite/dist/css/shards-dashboard-lite.min.css" />
  <!-- Chart.js для кольцевой диаграммы -->
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
      <span class="text-mute">Дата: {{ doc.analyzed_at.strftime('%Y-%m-%d %H:%M') }}</span>
    </div>

    <div class="row">
      <!-- Кольцевая диаграмма рисков -->
      <div class="col-lg-4 col-md-6 mb-4">
        <div class="card card-small">
          <div class="card-body text-center">
            <div class="chart-container">
              <canvas id="riskChart"></canvas>
            </div>
          </div>
        </div>
      </div>

      <!-- Аккордеон с деталями -->
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
    // Данные для диаграммы
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

echo "✅ Шаблон Shards Dashboard Lite установлен в services/report_template.html"
echo "▶️ Теперь обновите html_report_generator.py (если нужно) и перезапустите бота: python main.py"

