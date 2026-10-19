# Презентация QalaPulse

[Обзор проекта](../README.md)

- [One-pager в PDF](../output/pdf/qalapulse/QalaPulse_Investor_OnePager.pdf) — краткое описание продукта и предложения для пилота.
- [Редактируемый HTML](../output/pdf/qalapulse/QalaPulse_OnePager.html) — скачайте файл и откройте в браузере. Текст, размер, цвет и положение редактируются в боковой панели. Есть Undo/Redo и экспорт HTML.
- [Предпросмотр](../output/pdf/qalapulse/QalaPulse_Preview.png).
- [Основания утверждений и ограничения](../output/pdf/qalapulse/Evidence_and_design_notes.txt).

GitHub показывает исходный код HTML, а не запускает редактор. Для локального просмотра из корня репозитория:

```bash
python -m http.server 8765 --bind 127.0.0.1 --directory output/pdf/qalapulse
```

Откройте http://127.0.0.1:8765/QalaPulse_OnePager.html. Изменения редактора сохраняются в браузере; для отдельного файла нажмите **Download HTML**. Для PDF — **Print / Save PDF**, формат A4, без полей, с фоновой графикой. После изменения текста проверьте переносы и границы блоков.

Это презентационный материал, а не подтверждение пользователей, выручки или работающих государственных интеграций. Модель подписки для организаций — гипотеза. Изображение телефона — концептуальная иллюстрация; фактический интерфейс приложения показан в основном README. Контакт-заглушку нужно заменить перед использованием презентации вне команды.

## Исходники

Генератор: `scripts/build_qalapulse_onepager.py`. Редактор: `scripts/onepager_editor.py`, `.js` и `.css`. Шрифты Inter и OFL-лицензия находятся в `output/pdf/qalapulse/assets/`.

Для повторной генерации в отдельном Python-окружении:

```bash
python -m pip install reportlab pypdf
python scripts/build_qalapulse_onepager.py
```

Генератор перезаписывает PDF и HTML результатом из исходников. Ручные правки HTML сначала сохраните отдельной копией. PNG обновляется отдельно через Poppler `pdftoppm`; подробности — в файле оснований и ограничений.
