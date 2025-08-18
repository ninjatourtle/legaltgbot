# Архитектура

Диаграмма компонентов системы.

```mermaid
graph TD
    TG[Telegram Client] -->|HTTP| API[FastAPI Backend]
    API --> Services[Service Layer]
    Services --> DB[(PostgreSQL)]
    Services --> Redis[(Redis)]
```
