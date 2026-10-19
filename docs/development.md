# Руководство разработчика QalaPulse

[Обзор проекта](../README.md) · Запуск, настройки, проверки и ограничения.

## Быстрый запуск backend

Нужны Git, Python для setup-скрипта и Docker Desktop/Engine с Linux containers. Для всего backend используется образ **Python 3.13**; локальная разработка также на 3.13. Проверенная среда: Flutter **3.44.1**, Dart **3.12.1**, Docker Engine **29.5.3**.

Из корня проекта:

```bash
python scripts/setup_env.py
docker compose up --build -d
docker compose exec backend python -m app.seed
```

В Windows можно использовать `py scripts/setup_env.py`. Скрипт генерирует случайные локальные пароли в `.env` и сохраняет существующий файл. Не копируйте пустые секреты из `.env.example` в production. Compose автоматически применяет миграции до запуска API. `seed` повторяемый: существующие данные сохраняются; при `ENVIRONMENT=production` он запрещён.

Адреса:

| Сервис | Адрес |
|---|---|
| Swagger | [localhost:8000/docs](http://localhost:8000/docs) |
| Панель модератора и организации | [localhost:8000/console/](http://localhost:8000/console/) |
| OpenAPI JSON | [localhost:8000/openapi.json](http://localhost:8000/openapi.json) |
| Health | [localhost:8000/api/v1/health](http://localhost:8000/api/v1/health) |
| Readiness PostgreSQL/Redis/MinIO | [localhost:8000/api/v1/ready](http://localhost:8000/api/v1/ready) |
| MinIO console, только локально | [localhost:59001](http://localhost:59001) |
| PostgreSQL | localhost:55432 |
| Redis | localhost:16379 (REDIS_BIND_PORT) |

Служебные порты опубликованы только на loopback. Backend:8000 доступен телефону в доверенной локальной сети; для пилота ограничьте сетевой доступ и используйте HTTPS. `docker compose down` сохраняет данные в volumes.

Если Windows сообщает `ports are not available` / `forbidden by its access permissions`, проверьте `netsh interface ipv4 show excludedportrange protocol=tcp`: свободный порт может быть зарезервирован системой. Для Redis задайте другой `REDIS_BIND_PORT` и повторите `docker compose up -d`. Старый порт 56379 заменён на 16379. Backend/worker в Compose всегда используют внутренний `redis:6379`; при запуске Python вне Docker обновите `REDIS_URL` в существующем `.env` на соответствующий localhost-порт.

### Тестовые учётные записи

Общий **исключительно тестовый** пароль: `QalaPulse-Demo-2026!`.

| Роль | Email |
|---|---|
| Житель | citizen@qalapulse.example.com |
| Модератор | moderator@qalapulse.example.com |
| Организация | organization@qalapulse.example.com |
| Администратор | admin@qalapulse.example.com |

Seed создаёт 7 категорий, 28 синтетических обращений по Алматы, группы дубликатов, комментарии и подтверждения. Демо-служба не является госорганом. Изображения созданы кодом проекта, без внешних фотографий и неясных лицензий. Не включайте demo-аккаунты в реальный пилотный контур.

## Запуск Flutter

```bash
cd mobile
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` — адрес host из Android Emulator. Для физического Android используйте локальный IP компьютера, например `--dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1`. Для iOS Simulator используйте localhost или HTTPS endpoint. В production обязателен HTTPS. Android разрешает HTTP только в debug manifest; release не подписывается тестовым сертификатом автоматически.

Web-demo:

```bash
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Сборки:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
flutter build web --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk`. iOS собирается на macOS с Xcode; на Windows он не проверен. Для release нужен собственный signing configuration вне Git. Версия `permission_handler=12.0.1` закреплена для совместимости с проверенным Android SDK; автоматическое обновление плагина может потребовать более нового SDK.

Фото для галереи находятся в `sample_data/images/`. На Android можно перенести `demo.jpg` в эмулятор. После выбора фото и точки напишите «открытый люк» либо «яма на дороге», запустите AI, проверьте результат и дубликаты, подтвердите публикацию. На финальном шаге доступен просмотр публичной мозаичной версии фото.

## Локальная разработка Python

Если Python 3.13 отсутствует, установите [Python](https://www.python.org/downloads/) либо [uv](https://docs.astral.sh/uv/getting-started/installation/), затем:

```bash
uv venv --python 3.13 .venv
uv pip install --python .venv/Scripts/python.exe -r backend/requirements.lock -e "./backend[dev]"
```

В Linux/macOS путь интерпретатора `.venv/bin/python`. Активируйте окружение перед следующими командами:

```bash
docker compose up -d postgres redis minio minio-init
cd backend
alembic upgrade head
uvicorn app.main:app --reload --no-access-log
```

Не запускайте второй API на том же порту вместе с Compose backend. Настройки читаются из `../.env` и `.env`, переменные среды имеют приоритет. Для Windows worker рекомендуем Compose: Celery не имеет полноценной поддержки Windows worker pool.

Flutter: [установка SDK](https://docs.flutter.dev/install). Docker: [установка](https://docs.docker.com/engine/install/). Git: [установка](https://git-scm.com/downloads). Не обновляйте SDK/lock-файлы без повторного прогона тестов и сборки.

## AI: mock и cloud

По умолчанию `AI_MODE=mock`: ключей и внешних AI-сервисов не нужно. Mock vision классифицирует **текст**, не фотографию; `confidence=0` и явное предупреждение. Mock speech возвращает предсказуемую тестовую RU/KK фразу, отмеченную в UI. Это демонстрация сценария, не измеренная точность AI.

Для совместимого провайдера заполните `.env`:

```env
AI_MODE=cloud
AI_BASE_URL=https://your-provider.example/v1
AI_API_KEY=<secret>
AI_VISION_MODEL=<vision-model>
AI_TEXT_MODEL=<text-model>
AI_TRANSCRIPTION_MODEL=<transcription-model>
AI_EMBEDDING_MODEL=<optional-embedding-model>
```

`AI_BASE_URL` включает префикс `/v1`, если он нужен провайдеру. Используются `/chat/completions` с image_url/json_schema, `/audio/transcriptions` и опционально `/embeddings`. `AI_TEXT_MODEL` зарезервирован в конфигурации; отдельный текстовый LLM-запрос для прозрачного приоритета не нужен.

```bash
docker compose up -d --force-recreate backend worker
```

Кроме серверной конфигурации, пользователь должен разрешить внешнюю обработку в форме. При ошибке cloud API сохраняется ручной flow, возвращается явно обозначенный mock. Модель всегда даёт только предложение. Никаких автоматических объединений и отправок госорганам.

### Основные настройки

| Переменная | Значение/смысл |
|---|---|
| ENVIRONMENT | development/test/production |
| JWT_SECRET | Случайный секрет, минимум 32 символа |
| DATABASE_URL, REDIS_URL | Соединения; Compose задаёт внутренние адреса |
| MINIO_ENDPOINT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY | Закрытое объектное хранилище |
| PUBLIC_API_URL | Внешний адрес API для выдаваемых медиа-ссылок |
| CORS_ORIGINS | JSON-массив разрешённых web origins |
| AI_TIMEOUT_SECONDS, AI_RETRIES | По умолчанию 25 секунд и 2 повтора |
| DUPLICATE_RADIUS_METERS, DUPLICATE_DAYS, DUPLICATE_THRESHOLD | 250 м, 30 дней, 0.66 |
| RATE_LIMIT_ENABLED, RATE_LIMIT_PER_MINUTE | true, 120; auth отдельно 20/мин по IP |
| STORAGE_MODE | minio; local используется только в изолированных тестах |

Production-конфигурация отклоняет известные dev-секреты, local storage и отключённый rate limit. Этого недостаточно для промышленной защиты: см. infrastructure и government-readiness.

## Проверки

```bash
cd backend
ruff check .
ruff format --check .
mypy app
pytest -q -m "not integration"
```

Реальная интеграция в отдельном одноразовом контуре (из корня, с активным Python-окружением):

```bash
python scripts/run_integration.py
```

Скрипт создаёт отдельный Compose project, случайные порты, временные секреты и новые volumes; существующий `.env` не читает. Применяет миграции, загружает seed, запускает 4 теста PostgreSQL/PostGIS/MinIO/Celery, затем удаляет только созданный тестовый контур. Включены сохранение истории при `0001 → 0002`, конкурентные подтверждения, идемпотентность и гонка отмены публикации. Обычные unit/API tests используют SQLite и не заменяют эти проверки. Требуется Docker Compose с поддержкой `!override` (2.24.4+).

```bash
cd mobile
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

Результаты актуального этапа, команды и фактические ссылки CI — [исправления перед Android-пилотом](android-pilot-fixes.md). Предыдущий [отчёт реализации](implementation-status.md) сохранён как история. CI использует mock и не требует AI-ключей. MinIO и `mc` собираются из закреплённых официальных исходников, базовые образы закреплены по digest: [подробности и ограничения](../infrastructure/README.md).

## Ограничения MVP

1. Mock AI не распознаёт фото/речь, cloud transport проверен тестами без реального ключа. Качество русского/казахского распознавания выбранного cloud-провайдера надо измерить на пилотной выборке.
2. `PRIVACY_MODE=local` закрывает найденные лица и номера, сохраняя остальные детали. Контрольные снимки проверены, полевая точность ещё не измерена: обязательны предпросмотр и ручная проверка, доступно полное размытие. При ошибке детектора весь кадр мозаицируется автоматически. Старые фото не перерабатываются. [Методика и ограничения](photo-privacy.md). Автоматической защиты личных данных в тексте пока нет.
3. Чувствительные зоны синтетические. Priority пересчитывается при изменениях, временная составляющая между ними может устаревать.
4. Голос ограничен 90 сек в приложении. Физические камера, GPS, микрофон и iOS требуют отдельного приёмочного прогона на устройствах. Web — демонстрация; доступ к устройствам зависит от browser permissions/HTTPS, хранилище ограничено браузером.
5. Один активный локальный черновик на пользователя. Повтор отправки явный, из приложения; фоновой отправки закрытого приложения и офлайн-карты нет. Есть серверные черновики через API, но мобильный flow хранит их локально до публикации.
6. Уведомления — список событий и pull-to-refresh; FCM выделен интерфейсом, не настроен. Панель модератора/организации доступна на `/console/`: [запуск, права, тесты и ограничения](operations-console.md).
7. Нет email verification, восстановления пароля, MFA, автоматического удаления/retention и очистки сиротских файлов. Требуются операционные процедуры для закрытого пилота.
8. История показывает проверяемые действия QalaPulse. Нет официальных интеграций, камерных источников и подтверждения государственной регистрации.
9. MinIO/Redis/PostgreSQL в Compose — один экземпляр; HA, TLS termination, least-privilege service accounts, backup/restore, мониторинг диска и pentest подготавливает оператор.

## Безопасность

Не публикуйте `.env`, токены и реальные материалы пилота. Не используйте demo-аккаунты с реальными персональными данными. Запускайте пилот после проверки HTTPS, прав операторов, приватности снимков и восстановления резервных копий. Фото-оригиналы не возвращаются публичным API; оба MinIO-бакета закрыты. После logout access остаётся действительным до истечения 15 минут; refresh-семейство отзывается при доступном сервере.

## Документы и ближайшие задачи

- [Архитектура](architecture.md), [API и примеры](api.md).
- [Приватность и удаление данных](privacy.md), [пилот и метрики](pilot.md).
- [Готовность к взаимодействию с организациями](government-readiness.md), [эксплуатация](../infrastructure/README.md).

Приоритет следующего выпуска: расширенная проверка локальной детекции лиц/номеров с оценкой пропусков; пользовательская приёмка web-панели, казахская локализация и контроль сроков; восстановление пароля/MFA; retention и очистка загрузок; периодический пересчёт приоритета; FCM после передачи конфигурации; тесты на физических Android/iOS и нагрузочный прогон. Источники инспекторов/камер и государственные адаптеры добавляются только после отдельного проектирования и соглашений.

Лицензия кода и собственных синтетических материалов: MIT. OpenStreetMap и зависимости сохраняют свои лицензии и требования атрибуции.
