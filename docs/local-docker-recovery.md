# Восстановление локального Docker — 6 октября 2026

Docker Desktop 4.77.0 завершал запуск с ошибкой `The file cannot be accessed by the system` для `dockerInference`, затем для `docker-secrets-engine/engine.sock`. Похожие случаи описаны в [Docker desktop-feedback #527](https://github.com/docker/desktop-feedback/issues/527).

После проверки содержимого служебные папки `%LOCALAPPDATA%\Docker\run` и `%LOCALAPPDATA%\docker-secrets-engine` сохранены рядом под именами с суффиксом `.stale-20261006…`. Они содержали только runtime-сокеты. Переименование одного повреждённого сокета не удалось; удалось переименование родительской папки. Резервные папки оставлены на месте.

При повторном старте обнаружен зависший `wsl-bootstrap`. Остановлены процессы Docker Desktop и только служебная WSL-среда командой `wsl --terminate docker-desktop`, затем Docker Desktop запущен заново. Дистрибутивы не удалялись, factory reset не выполнялся; настройки, образы и volumes не удалялись.

Проверенный результат:

- Docker Engine отвечает, версия 29.5.3.
- `docker compose up -d --build --wait` завершился успешно.
- Backend и worker запущены; миграции применяются штатной командой старта backend.
- `GET http://127.0.0.1:8000/api/v1/ready` возвращает `status: ready`; PostgreSQL, Redis и MinIO — `true`.

Для обычного запуска достаточно открыть Docker Desktop, дождаться готовности движка и выполнить из корня репозитория `docker compose up -d --build --wait`. Описанное восстановление не является обязательным шагом запуска; оно применялось к конкретной диагностированной неисправности.
