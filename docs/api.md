# API v1

Базовый URL: `http://localhost:8000/api/v1`. Swagger: `http://localhost:8000/docs`.
JSON в UTF-8. Категории и AI содержат локализованные RU/KK поля; пользовательский текст не переводится автоматически. `Accept-Language` разрешён, но ответы стабильны и возвращают оба локализованных поля. Коды ошибок одинаковы для всех языков; Flutter локализует их.

## Авторизация

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"resident@example.com","password":"Local-test-password!","display_name":"Житель","preferred_language":"ru"}'
```

Ответ содержит `access_token`, `refresh_token`, `token_type`, `user`. Передавайте access как `Authorization: Bearer <access_token>`. Refresh/logout принимают JSON `{"refresh_token":"..."}`. После refresh атомарно замените оба токена. Не выводите их в логи.

## Основные маршруты

| Метод | Путь | Назначение |
|---|---|---|
| POST | /auth/register, /auth/login, /auth/refresh, /auth/logout | Сессии |
| GET, PATCH | /users/me | Профиль |
| GET | /users/me/confirmations, /users/me/notifications | Личная активность |
| GET | /categories | Справочник из БД |
| POST | /uploads/images | multipart `file`, необязательный `full_frame=true`, до 10 МБ |
| POST | /uploads/audio | multipart `file`, `language=ru|kk`, `cloud_consent`, до 15 МБ |
| GET | /uploads/{id} | Состояние/транскрипт владельцу |
| POST | /uploads/{id}/retry | Повтор задания |
| GET | /uploads/{id}/preview | Обработанное фото владельцу |
| POST | /incidents/analyze | upload_id, description, language, cloud_consent |
| POST | /incidents/duplicates/search | Координаты, category_id, title, description |
| POST | /incidents | Публикация или серверный черновик |
| POST | /incidents/publications/{key}/cancel | Безопасная отмена попытки или восстановление созданного Incident |
| GET | /incidents | page, page_size≤100, sort, category_id, status, author_id |
| GET | /incidents/nearby | latitude, longitude, radius≤20000, limit≤200, category_id |
| GET, PATCH | /incidents/{id} | Детали; изменение только своего черновика |
| GET | /incidents/{id}/timeline | История, page, page_size≤100 |
| GET, POST | /incidents/{id}/confirmations | still_exists, resolved, partially_resolved |
| GET, POST | /incidents/{id}/comments | Комментарии |
| POST | /content-reports | Ровно один incident_id или comment_id, reason |
| GET | /health, /ready | Процесс и зависимости |

Сортировка: `newest`, `priority`, `confirmations`. Списки имеют верхний лимит. Категории — фиксированный небольшой справочник. Координаты WGS84, радиус в метрах. Лента не возвращает скрытые записи и черновики. Жители могут подтвердить решение после `resolved_pending_confirmation`; оспаривание возвращает его в `under_review`.

`nearby` возвращает `items`, `has_more`, `radius_meters`. `has_more=true` означает, что в радиусе больше записей, чем в ответе; клиент предлагает приблизить карту или выбрать категорию. Это ограниченная выборка в круге, не полный набор всех обращений видимой прямоугольной области.

POST подтверждения разрешён **только citizen**. `organization`, `moderator`, `admin` получают 403. Ответ и список подтверждений содержат `resolution_cycle`. Каждый новый переход в `resolved_pending_confirmation` увеличивает цикл; повтор того же статуса не увеличивает его. Уникальность — `(incident_id, user_id, status, resolution_cycle)`, повтор — 409. `confirmation_count` считает уникальных жителей, когда-либо отправивших `still_exists`: повторная проверка ремонта счётчик не увеличивает.

## Загрузка и публикация

```bash
curl -X POST http://localhost:8000/api/v1/uploads/images \
  -H 'Authorization: Bearer <access_token>' \
  -F 'file=@sample_data/images/demo.jpg;type=image/jpeg'
```

Ответ и `GET /uploads/{id}` содержат `privacy_method` и `privacy_review_required=true` для изображений. Возможные методы: `local_opencv_regions_v1` (найдены области), `local_opencv_no_regions_v1` (области не найдены; не гарантия приватности), `whole_frame_detector_fallback` (сбой детектора), `whole_frame_mock_mosaic` (явное полное размытие, историческое имя метода).

Загрузите `GET /uploads/{id}/preview` с авторизацией владельца и проверьте результат. Чтобы скрыть весь кадр, повторно загрузите файл с `-F 'full_frame=true'`; новый upload ID заменяет прежний в ещё не отправленном черновике. После начала публикации с idempotency key её payload нельзя менять до завершения или безопасной отмены. Оригинал через этот endpoint недоступен. Публичная фотография после публикации содержит те же байты, что предпросмотр.

Используйте проверенный upload ID:

```http
POST /api/v1/incidents
Authorization: Bearer <access_token>
Idempotency-Key: 049cd179-ec40-4b22-a383-b40b1f22affc
Content-Type: application/json

{
  "category_id": "road_damage",
  "title": "Повреждение дорожного покрытия",
  "description": "Выбоина рядом с перекрёстком",
  "latitude": 43.2389,
  "longitude": 76.8897,
  "address": "Уточнённый пользователем ориентир",
  "severity": 7,
  "upload_ids": ["<upload_uuid>"],
  "reviewed_by_user": true,
  "publish": true,
  "cloud_consent": false
}
```

Повторите **тот же JSON и ключ** при потере ответа. Ответ 201 содержит тот же Incident. Смена JSON с прежним ключом — 409 `idempotency_conflict`. Идентификатор источника не принимается: только citizen. Поля ai_confidence и priority_score вычисляются сервером.

### Восстановление публикации

- Окончательные бизнес-ошибки 422 (`invalid_category`, `review_required`, `duplicate_upload`, `redaction_required`) возникают до создания Incident. Сервер сохраняет запрет на старый ключ перед ответом, поэтому поздний повтор уже не сможет создать запись. Исправленное содержимое отправляйте с новым ключом.
- Таймаут, разрыв соединения, 5xx и общий `validation_error` не разрешают автоматически менять ключ. Сохраните исходный payload и повторите либо используйте отмену ниже.
- `409 idempotency_conflict` и `upload_already_used` показывайте отдельно; автоматически создавать новую попытку нельзя. `publication_cancelled` означает, что ключ закрыт, но клиент всё равно может использовать endpoint восстановления для безопасного выхода из сохранённого состояния.

`POST /incidents/publications/{key}/cancel` требует сессию исходного владельца. Ответ `{"status":"published","incident":{...}}` возвращает уже созданный результат: клиент очищает черновик и открывает его, не удаляя публикацию. `{"status":"cancelled"}` гарантирует, что прежний запрос с этим ключом не создаст Incident; можно исправить данные с новым ключом или удалить локальный черновик. Повтор отмены безопасен. Если ответа нет, черновик и ключ остаются заблокированными до следующего восстановления. Публикация и отмена используют одну блокировку строки пользователя, поэтому гонка между ними не даёт два результата.

## Модерация и организации

- GET `/moderation/incidents`, `/moderation/reports` — очередь для moderator/admin.
- PATCH `/moderation/incidents/{id}` — `status`, `note`, `category_id`, `is_hidden`.
- POST `/moderation/incidents/{id}/assignments` — organization_id, executor_name, due_at. Организация может назначить исполнителя только уже закреплённого за ней обращения.
- POST `/moderation/incidents/{id}/after-photo/{upload_id}?reviewed_by_user=true` — обработанное фото результата от назначенной организации/admin после проверки предпросмотра. Без подтверждения — 422 `review_required`. Повтор того же вложения в то же обращение возвращает его прежний ID.
- POST `/moderation/incidents/{id}/merge` — target_incident_id, явное объединение модератором.
- POST `/moderation/reports/{id}/resolve?hide=true|false` — обработка жалобы.
- PATCH `/admin/categories/{code}` — имена, описание, опасность, icon, color, активность.
- PATCH `/admin/users/{id}/role` — роль и organization_id.
- GET `/admin/audit` — аудит. GET `/metrics` — Prometheus, только admin.

Организации и модераторы используют [веб-панель `/console/`](operations-console.md) или API/Swagger. Новые организации пока создаются оператором БД; API администрирования организаций — задача следующего выпуска.

### Служебная веб-панель

Все маршруты требуют Bearer access token и актуальную роль из БД. Организация видит только свои назначенные, опубликованные и нескрытые обращения; модератор/admin также могут просматривать скрытые. Черновики не выдаются. Ответы содержат `Cache-Control: private, no-store`.

| Метод | Путь | Назначение |
|---|---|---|
| GET | `/operations/incidents` | Очередь: `q`, `status`, `category_id`, `visibility=visible|hidden|all`, `unassigned`, `sort=priority|newest|oldest`, `page`, `page_size≤50`. Ответ `items`, `total`, `page`, `has_more` |
| GET | `/operations/organizations` | Справочник: `q`, `page`, до 50 записей и `has_more`; организации доступна только своя запись |
| GET | `/operations/incidents/{id}` | Карточка с назначением, допустимыми переходами `allowed_statuses` и защищёнными ссылками на медиа |
| GET | `/operations/incidents/{id}/media/{media_id}` | Только обработанное фото, авторизация и повторная проверка доступа |
| GET | `/operations/incidents/{id}/activity` | `kind=timeline|comments`, `page`, по 20 записей; скрытые комментарии только модератору/admin |
| GET | `/operations/incidents/{id}/duplicates` | Кандидаты без самого обращения, без автоматического объединения; moderator/admin |
| POST | `/operations/incidents/{id}/responses` | JSON `{"text":"Ответ жителям"}`, до 2000 символов; назначенная организация/admin. Создаёт публичный комментарий, событие истории и аудит |
| GET | `/operations/reports` | `status=pending|actioned|dismissed`, `page`, по 20 жалоб с текстом и связью с обращением; moderator/admin |

Действия изменения категории, статуса, назначения, объединения и разбора жалобы используют существующие `/moderation/*` endpoints. Повтор решения уже закрытой жалобы возвращает 409 `report_already_resolved`. Поле исполнителя — имя/бригада, а не новая учётная запись.

Панель передаёт `expected_updated_at` из загруженной карточки в PATCH статуса/категории/видимости. Если другой оператор уже изменил обращение, сервер возвращает 409 `incident_changed`; обновите карточку перед повторным сохранением. Параметр необязателен для совместимости существующих API-клиентов.

## Ошибки

```json
{"error":{"code":"review_required","message":"Проверьте результат перед публикацией","request_id":"..."}}
```

401 — нужна сессия; 403 — нет прав; 404 — объект отсутствует или скрыт; 409 — конфликт, повтор подтверждения или запрещённый переход; 413 — лимит; 415 — неподдерживаемый файл; 422 — валидация; 429 — лимит запросов; 500/503 — временный сбой. Request ID также в `X-Request-ID`. В ответах валидации отсутствуют исходные секреты и содержимое файла.
