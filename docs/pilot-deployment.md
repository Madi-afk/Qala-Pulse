# Пилот: сервер, HTTPS, резервные копии и восстановление

Это инструкция подготовки закрытого пилота. Наличие файлов конфигурации не означает, что публичный сервер уже работает. Домен, сервер, почтовая служба и ответственный модератор пока не выбраны. Не запускайте пилот с демонстрационными аккаунтами.

## Что входит

- Отдельный `docker-compose.pilot.yml`: наружу доступны только Caddy 80/443; PostgreSQL, Redis, MinIO и backend без опубликованных портов. Prometheus/Alertmanager доступны на loopback сервера через SSH-туннель.
- Caddy получает и продлевает сертификат, перенаправляет HTTP на HTTPS. `X-Forwarded-For` заменяется фактическим адресом клиента, поэтому rate limiting не доверяет присланному пользователем заголовку. Backend доверяет прокси только внутри закрытой Docker-сети; не публикуйте его порт.
- PostgreSQL и оба приватных MinIO bucket входят в зашифрованную restic-копию. Redis не архивируется: сессии хранятся в PostgreSQL, задания транскрибации после аварии доступны для повторного запуска.
- Ежедневный backup, еженедельное восстановление в отдельные контейнеры, ежечасная очистка фотографий. Запуски сериализованы через файловую блокировку.
- Проверка восстановления: полный `restic check --read-data`, SHA-256 дампа и каждого объекта, `pg_restore --exit-on-error`, количество строк всех таблиц, версия миграции, работа PostGIS и наличие всех файлов, на которые ссылается база.
- Предлагаемые цели: RPO до 24 часов (сколько данных можно потерять), RTO до 4 часов (срок возврата сервиса). Это цели пилота, не измеренный SLA.

## 1. Что подготовить

1. Linux-сервер с Docker Engine и Compose v2, Python 3.11+ и restic 0.18+. Начальная оценка для 20–50 участников: 2 vCPU, 4 GB RAM, 80 GB SSD. Проверить фактическую нагрузку и запас места для двух распакованных копий перед стартом.
2. Домен с A-записью на сервер; AAAA добавлять только при рабочем IPv6. Порты 80/443 доступны извне; SSH только по ключам и по возможности с ограничением адресов.
3. SMTP с STARTTLS на 587, отдельный адрес отправителя, настроенные SPF/DKIM. SMTP используется для сброса пароля и уведомлений оператору. Проверить доставку на реальные почтовые сервисы вручную.
4. Отдельное хранилище backup за пределами сервера: SFTP или S3 через HTTPS. Ключ шифрования restic хранить отдельно в менеджере паролей; потеря ключа делает копии бесполезными.
5. Назначить владельца инфраструктуры, модератора и заместителя. Заполнить [паспорт пилота](pilot-launch.md). Никто не назначается автоматически.

Инструкции поставщиков: [Docker на Ubuntu](https://docs.docker.com/engine/install/ubuntu/), [HTTPS Caddy](https://caddyserver.com/docs/quick-starts/https), [проверка restic](https://restic.readthedocs.io/en/stable/045_working_with_repos.html).

## 2. Конфигурация сервера

Разместить репозиторий в `/opt/qalapulse`. Команды ниже выполняются на Linux-сервере из этого каталога от пользователя с доступом к Docker; systemd-задачи работают от root. Доступ к Docker равносилен доступу администратора.

```bash
python3 scripts/prepare_pilot.py --init
chmod 600 .env.pilot
# Заполнить .env.pilot локальным редактором; не присылать секреты в чат.
python3 scripts/prepare_pilot.py
docker compose --env-file .env.pilot -f docker-compose.pilot.yml config --quiet
```

`--init` создаёт случайные секреты и отказывается перезаписывать существующий файл. Указать `PILOT_DOMAIN`, `PUBLIC_API_URL=https://ваш-домен`, `ACME_EMAIL`, SMTP, `ALERT_EMAIL`, параметры restic. `PILOT_REGISTRATION_EMAILS` — JSON-массив email приглашённых, `PILOT_REGISTRATION_CLOSED=true`. Обновление списка требует пересоздания backend/worker. Просмотр опубликованных обращений остаётся публичным: «закрытый пилот» ограничивает регистрацию, а не делает ленту конфиденциальной.

`prepare_pilot.py` создаёт `.pilot/monitoring` с конфигурацией Prometheus и Alertmanager. SMTP-пароль присутствует в защищённой конфигурации на сервере; `.env.pilot` и `.pilot/` исключены из Git. Не используйте `docker compose config` без `--quiet` в общедоступных логах — он может показать секреты.

Для SFTP restic настройте отдельный SSH-ключ root, заранее проверенный `known_hosts` и доступ без интерактивного пароля. Для S3 задайте `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` в защищённом `.env.pilot`. Генерация пароля backup:

```bash
sudo install -d -m 700 /root/.config/qalapulse
sudo sh -c 'umask 077; openssl rand -hex 32 > /root/.config/qalapulse/restic-password'
```

Указать этот абсолютный путь в `RESTIC_PASSWORD_FILE`. Скопировать пароль в защищённое независимое хранилище. Инициализация нового пустого репозитория (однократно):

```bash
sudo python3 -c 'import sys,subprocess; sys.path.insert(0,"scripts"); from pilot_ops import restic_env; subprocess.run(["restic","init"],env=restic_env(),check=True)'
```

Нельзя хранить единственную копию на диске того же VPS. Резервное копирование секретов и SSH-ключей — отдельно, с доступом владельца и заместителя; дамп приложения их намеренно не содержит.

## 3. Запуск и персональные аккаунты

```bash
docker compose --env-file .env.pilot -f docker-compose.pilot.yml up -d --build --wait
docker compose --env-file .env.pilot -f docker-compose.pilot.yml exec backend python -m app.pilot_admin --email YOUR_ADMIN_EMAIL --name "Имя администратора" --role admin
docker compose --env-file .env.pilot -f docker-compose.pilot.yml exec backend python -m app.pilot_admin --email YOUR_MODERATOR_EMAIL --name "Имя модератора" --role moderator
```

Пароль вводится скрыто в интерактивном терминале, минимум 14 символов. Команда создаёт только реальные staff-аккаунты и справочник категорий. `python -m app.seed` запрещён в production. Организацию подключать только после реальной договорённости; пока её нет, не обещать обработку городскими службами.

- Панель: `https://ваш-домен/console/`.
- Восстановление пароля: `https://ваш-домен/account/` и кнопка в Flutter «Забыли пароль?».
- Readiness: `https://ваш-домен/api/v1/ready`.
- Swagger и метрики закрыты на внешнем прокси. Для отладки использовать внутреннюю сеть или SSH; публичного Swagger пилоту не требуется.
- Flutter: `flutter build apk --release --dart-define=API_BASE_URL=https://ваш-домен/api/v1`. Настроить собственную подпись release до распространения.

После первого запуска проверить с телефона вне домашнего Wi-Fi: сертификат, регистрацию приглашённого, отклонение неприглашённого, публикацию, смену пароля и повторный вход.

## 4. Backup и обязательная проверка восстановления

```bash
sudo python3 scripts/pilot_ops.py backup
sudo python3 scripts/pilot_ops.py restore-drill
sudo python3 scripts/pilot_ops.py retention
```

Backup сначала проверяет доступ к репозиторию, затем останавливает backend и worker на время согласованного снимка PostgreSQL и файлов. В этот короткий период запросы получают ошибку прокси, черновики остаются на устройстве. Сервисы запускаются обратно до отправки архива во внешнее хранилище, включая обработку обычной ошибки export. При отключении питания/SIGKILL оператор проверяет запуск вручную. Не вносить изменения через SQL или MinIO во время снимка.

В staging временно есть незашифрованный дамп и фото, каталог доступен только оператору. После успеха или обычной ошибки он удаляется. Прерванный каталог `snapshot` не перезаписывается: сначала выяснить причину и безопасно разобрать его. SSD не гарантирует физическое стирание удалённых блоков; используйте шифрование диска сервера.

Restore-drill не меняет рабочую базу, не отправляет письма, не выполняет реальные действия пользователей. Создаёт случайное имя Compose-проекта, новые volumes, базу из `template0` (без конфликта схем PostGIS), импортирует данные и удаляет только собственные volumes. Успех фиксируется лишь после всех проверок. Сам по себе `restic check` не заменяет этот процесс.

Расписание после первого успешного ручного запуска:

```bash
sudo cp infrastructure/pilot/qalapulse-maintenance@.service /etc/systemd/system/
sudo cp infrastructure/pilot/qalapulse-*.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now qalapulse-backup.timer qalapulse-restore.timer qalapulse-retention.timer
systemctl list-timers 'qalapulse-*'
journalctl -u qalapulse-maintenance@backup.service --since today
```

Backup: ежедневно 02:30 UTC; проверка восстановления: воскресенье 03:30 UTC; очистка: каждый час. `Persistent=true` запускает пропущенную задачу после включения. Хранение backup — окно 30 дней относительно последнего снимка, затем prune; если задачи не работают, автоматическое удаление старых копий не гарантируется. Сбой очистки/backup отслеживается мониторингом.

## 5. Мониторинг и действия при ошибке

Prometheus хранит метрики 30 дней. Правила: недоступность API/HTTPS, истечение сертификата, ≥3 ответов 5xx за 10 минут, ошибка SMTP, отсутствие backup 26 часов, отсутствие restore-drill 8 дней, очистки 3 часа, недоступный worker, <15% свободного места. Метрики не содержат email, координаты, текст сообщений или токены. HTTP-логи используют шаблон маршрута и request ID, Docker ограничивает размер логов.

```bash
ssh -L 9090:127.0.0.1:9090 -L 9093:127.0.0.1:9093 USER@SERVER
```

Открыть локально `http://localhost:9090/alerts` и `http://localhost:9093`. Получатель — `ALERT_EMAIL`. Провести согласованный тест уведомления через локальный Alertmanager, убедиться в получении и в отправке resolved. Не считать почтовую доставку проверенной только по валидности конфигурации.

Мониторинг на одном VPS не сообщит о полном отключении этого VPS. Перед участниками нужен **внешний** HTTPS-проверяющий узел/сервис и отдельный канал оповещения владельца; провайдер пока не выбран. SMTP-отказ также требует независимого канала. Проверка диска относится к файловой системе `.pilot`; отдельный диск Docker нужно мониторить дополнительно.

При тревоге: зафиксировать время/request ID → проверить `/ready` и журналы → при утечке скрыть обращение, приостановить набор → уведомить владельца → восстановить сервис → записать причину и действие. Не копировать тела запросов, пароли или фото в общедоступные задачи.

## 6. Настоящее восстановление после потери сервера

Выполнять на **новом изолированном сервере**, не поверх живой базы. Не менять DNS, пока проверки не пройдены.

1. Вернуть репозиторий **той же версии, что создала backup**, `.env.pilot` и доступ к restic из независимого хранилища. Перегенерировать JWT/SMTP/MinIO секреты при подозрении на компрометацию.
2. `restic check --read-data`, выбрать ID снимка и выполнить `restic restore ID --target /защищённый-каталог` с теми же защищёнными переменными. Найти `manifest.json`; скопировать его каталог в `.pilot/transfer/snapshot`. Не выполнять demo seed.
3. Запустить только `postgres minio minio-init` через pilot Compose. В PostgreSQL создать новую базу `qalapulse_recovered` командой `createdb -U qalapulse -T template0 qalapulse_recovered` (заменить пользователя, если он изменён). Она должна отсутствовать до создания.
4. Импортировать: `docker compose --env-file .env.pilot -f docker-compose.pilot.yml exec -T postgres pg_restore -U qalapulse -d qalapulse_recovered --exit-on-error --no-owner --no-acl < .pilot/transfer/snapshot/database.dump`.
5. Изменить `POSTGRES_DB=qalapulse_recovered` в `.env.pilot`. Backend пока не запускать. Проверить контрольные суммы и восстановить файлы в пустые buckets:

```bash
docker compose --env-file .env.pilot -f docker-compose.pilot.yml run --rm --no-deps -e ENVIRONMENT=test -e RESTORE_DRILL=1 ops restore /backup/snapshot
docker compose --env-file .env.pilot -f docker-compose.pilot.yml run --rm --no-deps --entrypoint python ops -m app.recover
docker compose --env-file .env.pilot -f docker-compose.pilot.yml run --rm --no-deps --entrypoint python ops -m app.retention --apply
```

Первый вызов временно использует test-mode **только для утилиты импорта**, а не для web-сервиса; она откажется писать в непустые buckets. Второй отзывает восстановленные сессии/ссылки сброса, помечает прерванное аудио для повторной отправки. Третий удаляет фото, сроки которых истекли. При >500 ожидающих файлов повторять очистку до `uploads=0`.

6. Применить журнал досрочных удалений, хранящийся отдельно от старого снимка, через `app.retention --erase-upload UUID --apply`. Иначе старый backup может вернуть удалённое по просьбе жителя фото.
7. Запустить весь pilot Compose, проверить readiness, вход, чтение фото, публикацию синтетического обращения, права модератора и восстановление пароля. Только затем переключить DNS и пригласить пользователей войти заново. Задания аудио пользователи повторяют кнопкой retry; Redis из прежнего сервера не переносится.
8. Зафиксировать фактические RPO/RTO, сделать новую копию, удалить временный незашифрованный staging. Для проверки перед открытием сервиса локальный файл hosts оператора может указывать домен на новый адрес; выпуск публичного сертификата требует доступной DNS/ACME-проверки.

## 7. Проверки без домена и SMTP

```bash
python scripts/check_pilot_config.py
python scripts/check_pilot_restore.py
python scripts/run_integration.py
```

Тест восстановления использует только синтетические данные и временный локальный restic repository. Он проверяет шифрование/чтение/восстановление, но не доступность будущего удалённого хранилища, сертификат реального домена или доставку писем. Эти проверки обязательны на выбранном сервере до старта жителей.
