# legaltgbot

[![Lint](https://github.com/legaltgbot/legaltgbot/actions/workflows/lint.yml/badge.svg)](https://github.com/legaltgbot/legaltgbot/actions/workflows/lint.yml)
[![Test](https://github.com/legaltgbot/legaltgbot/actions/workflows/test.yml/badge.svg)](https://github.com/legaltgbot/legaltgbot/actions/workflows/test.yml)
[![Build](https://github.com/legaltgbot/legaltgbot/actions/workflows/build.yml/badge.svg)](https://github.com/legaltgbot/legaltgbot/actions/workflows/build.yml)
[![Smoke](https://github.com/legaltgbot/legaltgbot/actions/workflows/smoke.yml/badge.svg)](https://github.com/legaltgbot/legaltgbot/actions/workflows/smoke.yml)

## Запуск

### Python

```bash
pip install -r requirements.txt
uvicorn backend.app.main:app --reload
```

### Docker

```bash
docker build -t legaltgbot .
docker run -p 8000:8000 legaltgbot
```

После запуска сервис доступен на `http://localhost:8000/`, метрики Prometheus — на `http://localhost:8000/metrics`.
