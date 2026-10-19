# QalaPulse — Laboratory Works 5 & 6

English UI design and interactive prototype based on the existing QalaPulse Flutter application and Lab 4 wireframes.

## Статус и запуск в Figma

**Комплект подготовлен локально. В целевой Figma-файл он ещё не записан.** 13 октября 2026 года доступ к файлу `d7aQG04h2LnjJqXm6lqEnx` подтвердился, но Figma MCP остановил первую запись из-за лимита Starter. Локальные проверки и браузерный просмотр не заменяют проверку Figma.

1. Откройте ваш файл в **Figma Desktop**.
2. **Plugins → Development → Import plugin from manifest…**
3. Выберите `docs/lab5-6/figma-plugin-starter-v2/manifest.json`.
4. Запустите **QalaPulse Lab 5-6 — STARTER FIX v2 → Create UI & interactive prototype**.
5. Плагин добавит макеты **на текущую страницу, справа от существующих объектов**, и приблизит главный экран. Новая страница не создаётся — это совместимо с ограничением Starter в три страницы.
6. Выберите **home · QalaPulse → Present**, затем сценарий **01 · Report a city issue**.

Если Figma требует зарегистрированный plugin ID, создайте собственный development plugin и замените только `id` в manifest на выданный Figma. [Инструкция Figma](https://help.figma.com/hc/en-us/articles/360042786733-Create-a-plugin-for-development).

Существующие объекты и точки начала прототипов сохраняются. Повторный запуск проверяет и открывает готовый набор без дублирования. Если сборка прервётся, ошибка останется в окне плагина, а частичные макеты сохранятся для диагностики. Команда **Check existing prototype** проверяет созданный набор.

**Исправление ошибки Starter / createPage:** закройте окно ошибки и импортируйте `figma-plugin-starter-v2/manifest.json` через Plugins → Development → Import plugin from manifest. Запускайте именно **QalaPulse Lab 5-6 — STARTER FIX v2**. В старом плагине с названием «QalaPulse — Lab 5 & 6» может остаться ранее импортированная копия. Ошибки новой сборки обязательно содержат строку `Build: STARTER FIX v2`. Удалять страницы или менять тариф не требуется.

### Исправление flowStartingPoints — сборка 2.1

Если версия STARTER FIX v2 остановилась с `Found duplicate input nodeIds`, запустите тот же плагин после обновления `code.js`. Идентификатор плагина сохранён: это позволяет прочитать сохранённые данные незавершённой сборки. Новая сборка показывает **STARTER FIX v2.1** в окне ошибок; название пункта меню остаётся **STARTER FIX v2**.

Плагин восстановит готовые экраны: уберёт повторяющиеся точки старта, добавит недостающий стенд сценария, проверит связи и приблизит главный экран. Экранные ID, позиции, внесённые правки и старые пользовательские сценарии сохраняются. Если сборка прервалась раньше готовности экранов, восстановление остановится с диагностикой вместо создания копий.

Причина: [Figma может автоматически создавать точку старта при добавлении связи](https://help.figma.com/hc/en-us/articles/360039823894-Create-and-manage-prototype-flows). Теперь точки объединяются по уникальному ID экрана. Проверка воспроизводит старую ошибку и восстанавливает тот же набор, включая пользовательскую правку; реальное воспроизведение Present требует проверки в Figma.

## Part 1 — Color palette

| Role | Color | Usage |
|---|---|---|
| Primary | `#24634C` | Main actions, active navigation, brand mark |
| Secondary | `#E5EDE4` | Selected items, supporting surfaces |
| Background | `#F6F5F0` | Warm mobile canvas |
| Text | `#202D29` | Headings and body text |
| Accent | `#A34D19` | Attention and high priority, with a text label |
| Muted | `#5E6B64` | Secondary text |
| Surface | `#FFFFFF` | Cards, fields, dialogs |
| Outline | `#DFE3DB` | Borders and dividers |

Core values come from `mobile/lib/core/theme/app_theme.dart`; amber attention and error tokens are additions for the laboratory states. Colors are Figma semantic variables aliased to primitive variables, rather than unlinked per-screen hex values.

Calculated text contrast: primary/white **7.08:1**, text/background **13.10:1**, muted/background **5.11:1**, accent/warning surface **4.93:1**. Status is never conveyed by color alone. These are color-pair calculations, not a full accessibility certification.

## Part 2 — Typography

One family: **Noto Sans**, matching the app and supporting Latin, Russian and Kazakh characters.

| Style | Size / line height | Weight |
|---|---|---|
| Display | 32 / 38 | Bold |
| Heading | 28 / 34 | Bold |
| Subheading | 20 / 26 | Bold |
| Body | 14 / 21 | Regular |
| Button | 15 / 22 | SemiBold |
| Caption | 12 / 18 | Regular |

Named text styles are created in Figma. The browser preview embeds the repository's OFL-licensed Noto Sans font; the license is included as `FONT-LICENSE.txt`.

## Part 3 — UI component library

- Primary and secondary buttons: Default, Pressed, Disabled, Loading; editable Label property.
- Input fields: Default, Focus, Error; editable Label and Value properties.
- Five bottom-navigation states: Home, Map, Create, Updates, Profile.
- Incident card with status, title, location, priority and confirmation count.
- Search bar.
- 24px original outline icons.
- Dialog and menu main components; overlays use instances.
- Visible specimen boards for color, typography, components and dialogs.

Geometry: 390 × 844 screens, 20px horizontal gutters, 52px buttons, 80px fields, 14px card/button corners, 12px input corners, 24px dialog corners. Spacing uses named 4/8/12/16/20/24/32px variables. Main components remain outside the presentation boards. UI text and hierarchy remain editable, not flattened screenshots.

## Part 4 — Designed screens and states

| Screen | Purpose |
|---|---|
| home | Main entry point and nearby issue |
| map | Map, search and filters |
| search | Preset search results |
| filtered | Road-damage filter result |
| details | Existing issue and status history |
| confirmed | Existing issue after community confirmation |
| login | Preset sign-in flow |
| photo | Empty upload; Continue disabled |
| photoReady | Demo image added |
| location | Location confirmation / manual-point dialog |
| describe | Text, voice entry and draft |
| analyze | Loading state with automatic continuation |
| review | AI suggestion not yet reviewed |
| reviewReady | Human review checked; Continue enabled |
| duplicates | Existing issue or new report decision |
| success | Publication confirmation |
| created | Newly published report |
| draft | Saved locally, not published |
| events | In-app update |
| profile | Reports, confirmations, draft and settings |

The build contains **20 screen states, 20 overlay states, 61 main components and 123 prototype transitions** according to the local contract test. Counts must be confirmed after native import. Dialog states cover image source, location, filters, publication, offline recovery, confirmation, resolution feedback, reporting content, voice recording/transcript, field review and settings.

## Lab 6 — Interaction design

Main scenario:

**Home → Report an issue → Choose photo → Gallery → Continue → Confirm location → Analyse issue → Review details → Find similar issues → Create a new report → Publish report → View my report.**

Additional scenarios:

- Confirm an existing issue: duplicate choice → confirm → count increases from 3 to 4.
- Network error simulation: publication dialog → Preview network error → keep as draft / retry. The preview control is explicitly a classroom demonstration control, not a production app action.
- Map → filters → road damage → apply → filtered state.
- Record voice → stop → review preset transcript → use description / record again.
- Report resolution → feedback dialog; this does not automatically mark the report resolved.
- Cancel closes overlays; navigation and Back controls have destinations.

Transitions: **Dissolve 180ms** for navigation/dialogs; **Smart Animate 200ms** for review confirmation; **After delay 1.4s** for mock analysis. Figma presentation is required to verify actual animation behavior. The browser preview verifies destinations and content, not native Figma animation rendering.

## Tests and their limits

Run from the repository root:

```powershell
node docs/lab5-6/build.cjs
node docs/lab5-6/check-plugin.cjs
$env:LAB56_FORCE_ERROR='1'
node docs/lab5-6/check-plugin.cjs
Remove-Item Env:LAB56_FORCE_ERROR
```

Passed locally:

- Complete publication path, including the disabled human-review gate.
- Existing-issue confirmation and updated count.
- Offline save, resume and retry destinations.
- Filter selection and dialog cancellation.
- Repeat execution preserves node count; existing user content is untouched.
- String errors remain visible with a build stage instead of `undefined`.
- Browser walkthrough of the main scenario and publication cancellation.
- Browser geometry checks of 39 non-timed screens/dialogs: no detected footer overlap, clipped dialog or horizontal text overflow.

**Not yet verified:** native Figma execution, native layout, actual Figma Present interactions/animations, and testing with human participants. Use `DEMONSTRATION.md` for the final demonstration and test worksheet. Do not claim the lab is fully submitted until the native import and checks are complete.

## Local preview

Open `preview.html` directly, or serve it:

```powershell
python -m http.server 8766 --bind 127.0.0.1 --directory docs/lab5-6
```

The preview is generated from the same source using a lightweight Plugin API test double. It is an approximation of Figma layout, not an exported Figma screenshot. `preview.html` is supplementary; the assignment platform remains Figma.

## Honest prototype boundaries

- English is the submission language; the actual app remains RU/KK.
- Photos/maps are original editable illustrations, clearly marked as demo material; they are not photographs of actual reports.
- Fields use preset edit/review examples. Real keyboard entry, camera, GPS, audio capture, AI requests and publication are not executed by the prototype.
- Mock AI has no claimed image-recognition accuracy.
- Published means visible in QalaPulse, not registered by a government agency.
- The local page does not store actual user reports or contact a backend.

## Source files

`common.js` — reusable drawing primitives. `foundations.js` — variables, text styles and components. `screens.js` — screens, overlays and interactions. `runtime.js` — native startup, safe repeat execution and verification. `build.cjs` — plugin packager. `check-plugin.cjs` — contract checks and local preview generator.
