up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

migrate:
	docker-compose run --rm backend alembic upgrade head

seed:
	docker-compose run --rm backend python -m backend.app.seed
