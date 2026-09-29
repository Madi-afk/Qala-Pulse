.PHONY: setup up seed test backend-test mobile-test format down
setup:
	python scripts/setup_env.py
up:
	docker compose up --build -d
seed:
	docker compose exec backend python -m app.seed
backend-test:
	cd backend && python -m ruff check . && python -m mypy app && python -m pytest -q
mobile-test:
	cd mobile && flutter analyze && flutter test && dart format --output=none --set-exit-if-changed lib test
test: backend-test mobile-test
format:
	cd backend && python -m ruff format .
	cd mobile && dart format lib test
down:
	docker compose down
