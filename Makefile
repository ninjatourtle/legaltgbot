# Запустить сервисы
up:
        docker-compose up -d

# Остановить сервисы
down:
        docker-compose down

# Просматривать логи
logs:
        docker-compose logs -f

# Применить миграции БД
migrate:
        docker-compose run --rm backend alembic upgrade head

# Выполнить скрипт заполнения
seed:
        docker-compose run --rm backend python -m backend.app.seed
