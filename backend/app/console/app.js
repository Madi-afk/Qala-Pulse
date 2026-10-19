import { Api } from "./client.js";
import {
  el,
  button,
  field,
  input,
  select,
  badge,
  statuses,
  roles,
  date,
  errorBox,
  announce,
  dialog,
  actionForm,
} from "./ui.js";

const api = new Api();
const root = document.querySelector("#app");
let categories = [],
  organizations = [];
let view = "incidents",
  page = 1,
  filters = {},
  sequence = 0,
  detailSequence = 0;
let workspace, queueNode, detailNode, heading;
let urls = [];
const moderator = () => api.user?.role !== "organization";
const categoryName = (id) => categories.find((c) => c.id === id)?.name_ru || id;
const apiAction = (path, body, method = "POST") =>
  api.request(path, { method, body });
const clearImages = () => {
  urls.forEach(URL.revokeObjectURL);
  urls = [];
};

api.onExpired = () => login("Сессия истекла. Войдите повторно.");

function login(message = "") {
  ++sequence;
  ++detailSequence;
  clearImages();
  document.querySelectorAll("dialog").forEach((d) => d.close());
  const form = actionForm(
    "Вход в рабочую панель",
    [
      field(
        "Email",
        input("email", "", {
          type: "email",
          required: true,
          autocomplete: "username",
        }),
      ),
      field(
        "Пароль",
        input("password", "", {
          type: "password",
          required: true,
          autocomplete: "current-password",
          maxlength: 128,
        }),
      ),
    ],
    "Войти",
    async (data) => {
      await api.login(data.get("email"), data.get("password"));
      try {
        [categories, { items: organizations }] = await Promise.all([
          api.request("/categories"),
          api.request("/operations/organizations"),
        ]);
        view = "incidents";
        page = 1;
        filters = {};
        shell();
        await loadQueue();
      } catch (error) {
        await api.logout().catch(() => {});
        throw error;
      }
    },
  );
  root.replaceChildren(
    el(
      "main",
      { class: "login-layout", id: "content" },
      el(
        "section",
        { class: "login-story" },
        brand(),
        el("p", { class: "eyebrow" }, "РАБОЧЕЕ ПРОСТРАНСТВО"),
        el("h1", {}, "От обращения —", el("br"), "к результату."),
        el(
          "p",
          {},
          "Проверяйте городские проблемы, координируйте работу и отвечайте жителям в одном месте.",
        ),
        el(
          "div",
          { class: "login-steps" },
          [
            "01 / Проверка обращения",
            "02 / Назначение ответственного",
            "03 / Подтверждение результата",
          ].map((t) => el("div", {}, t)),
        ),
        el("small", {}, "QalaPulse — независимая гражданская платформа."),
      ),
      el(
        "section",
        { class: "login-form" },
        message ? el("p", { class: "notice", role: "status" }, message) : null,
        form,
        el(
          "p",
          { class: "muted" },
          "Для модераторов и подключённых организаций. Учётную запись выдаёт администратор.",
        ),
        el(
          "small",
          {},
          "Сессия действует в этой вкладке. После перезагрузки потребуется повторный вход.",
        ),
        el("a", { href: "/account/" }, "Забыли пароль?"),
      ),
    ),
  );
}

function brand() {
  return el(
    "div",
    { class: "brand" },
    el("span", { class: "brand-mark", "aria-hidden": "true" }, "Q"),
    el("strong", {}, "QalaPulse"),
  );
}

function shell() {
  queueNode = el("section", { class: "queue", "aria-label": "Очередь" });
  detailNode = el("section", {
    class: "detail",
    "aria-label": "Карточка обращения",
    hidden: "",
  });
  workspace = el("div", { class: "workspace" }, queueNode, detailNode);
  heading = el("div", { class: "page-heading" });
  const nav = el("nav", { "aria-label": "Разделы панели" });
  for (const [key, label] of [
    ["incidents", moderator() ? "Обращения" : "Мои назначения"],
    ...(moderator() ? [["reports", "Жалобы на контент"]] : []),
  ]) {
    const tab = button(
      label,
      () => {
        view = key;
        page = 1;
        filters = {};
        shell();
        loadQueue();
      },
      `nav-item ${view === key ? "active" : ""}`,
    );
    if (view === key) tab.setAttribute("aria-current", "page");
    nav.append(tab);
  }
  root.replaceChildren(
    el(
      "div",
      { class: "app-shell" },
      el(
        "aside",
        { class: "sidebar" },
        brand(),
        el("span", { class: "workspace-label" }, "Рабочая панель"),
        nav,
        el(
          "div",
          { class: "sidebar-bottom" },
          el(
            "div",
            { class: "avatar", "aria-hidden": "true" },
            api.user.display_name.slice(0, 1),
          ),
          el("strong", {}, api.user.display_name),
          el("small", {}, roles[api.user.role]),
          button(
            "Выйти",
            async () => {
              const promise = api.logout();
              login();
              try {
                await promise;
              } catch {
                login(
                  "Вы вышли на этом устройстве. Сервер не подтвердил отзыв сессии.",
                );
              }
            },
            "quiet",
          ),
        ),
      ),
      el(
        "main",
        { id: "content" },
        el(
          "header",
          { class: "topbar" },
          el("span", {}, "Городские обращения"),
          el(
            "span",
            { class: "muted" },
            "Публикация в QalaPulse ≠ регистрация в госоргане",
          ),
        ),
        heading,
        filterBar(),
        workspace,
      ),
    ),
  );
}

function filterBar() {
  const form = el("form", {
    class: "filters",
    "aria-label": "Фильтры очереди",
  });
  if (view === "reports")
    form.append(
      field(
        "Состояние жалобы",
        select(
          "status",
          [
            ["pending", "Ожидают проверки"],
            ["actioned", "Приняты меры"],
            ["dismissed", "Отклонены"],
          ],
          filters.status || "pending",
        ),
      ),
    );
  else {
    form.append(
      field(
        "Поиск",
        input("q", filters.q || "", {
          type: "search",
          placeholder: "Проблема или адрес",
          maxlength: 160,
        }),
      ),
      field(
        "Статус",
        select(
          "status",
          Object.entries(statuses),
          filters.status,
          "Все статусы",
        ),
      ),
      field(
        "Категория",
        select(
          "category_id",
          categories.map((c) => [c.id, c.name_ru]),
          filters.category_id,
          "Все категории",
        ),
      ),
      field(
        "Порядок",
        select(
          "sort",
          [
            ["priority", "Сначала важные"],
            ["newest", "Сначала новые"],
            ["oldest", "Сначала старые"],
          ],
          filters.sort || "priority",
        ),
      ),
    );
    if (moderator())
      form.append(
        field(
          "Видимость",
          select(
            "visibility",
            [
              ["visible", "Опубликованные"],
              ["hidden", "Скрытые"],
              ["all", "Все"],
            ],
            filters.visibility || "visible",
          ),
        ),
        el(
          "label",
          { class: "check" },
          input("unassigned", "true", {
            type: "checkbox",
            checked: filters.unassigned === "true",
          }),
          "Без назначения",
        ),
      );
  }
  form.append(
    el("button", { type: "submit", class: "primary" }, "Применить"),
    button(
      "Сбросить",
      () => {
        filters = {};
        page = 1;
        shell();
        loadQueue();
      },
      "quiet",
    ),
  );
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    filters = Object.fromEntries(
      [...new FormData(form)].filter(([, v]) => v !== ""),
    );
    page = 1;
    loadQueue();
  });
  return form;
}

function closeDetail() {
  ++detailSequence;
  clearImages();
  detailNode.replaceChildren();
  detailNode.hidden = true;
  workspace.classList.remove("split");
}

async function loadQueue({ keepDetail = false } = {}) {
  const run = ++sequence;
  if (!keepDetail) closeDetail();
  heading.replaceChildren(
    el(
      "div",
      {},
      el("p", { class: "eyebrow" }, moderator() ? "МОДЕРАЦИЯ" : "ИСПОЛНЕНИЕ"),
      el(
        "h1",
        {},
        view === "reports"
          ? "Жалобы на контент"
          : moderator()
            ? "Очередь обращений"
            : "Мои назначения",
      ),
    ),
    button("Обновить очередь", () => loadQueue(), "secondary"),
  );
  queueNode.replaceChildren(
    el("p", { class: "empty", role: "status" }, "Загружаем очередь…"),
  );
  try {
    const query = new URLSearchParams({ ...filters, page });
    const result = await api.request(`/operations/${view}?${query}`);
    if (run !== sequence || !api.user) return;
    const summary = el(
      "div",
      { class: "queue-summary" },
      el(
        "strong",
        {},
        `${result.total} ${view === "reports" ? "жалоб" : "обращений"}`,
      ),
      el("span", {}, `Страница ${page}`),
    );
    queueNode.replaceChildren(summary);
    if (!result.items.length)
      queueNode.append(
        el(
          "div",
          { class: "empty" },
          el("h2", {}, "Здесь пока пусто"),
          el(
            "p",
            {},
            "Нет записей по выбранным условиям. Измените фильтры или обновите очередь.",
          ),
        ),
      );
    else
      queueNode.append(
        el(
          "div",
          { class: "queue-list" },
          result.items.map(view === "reports" ? reportCard : incidentCard),
        ),
      );
    const prev = button("Назад", () => {
      page--;
      loadQueue();
    });
    prev.disabled = page === 1;
    const next = button("Следующая", () => {
      page++;
      loadQueue();
    });
    next.disabled = !result.has_more;
    queueNode.append(
      el(
        "div",
        { class: "pagination" },
        prev,
        el("span", {}, `Страница ${page}`),
        next,
      ),
    );
  } catch (error) {
    if (run === sequence && api.user)
      queueNode.replaceChildren(
        errorBox(error),
        button("Повторить загрузку", () => loadQueue()),
      );
  }
}

function incidentCard(item) {
  return el(
    "button",
    {
      type: "button",
      class: "incident-card",
      onclick: () => openIncident(item.id),
    },
    el(
      "div",
      { class: "card-meta" },
      el("span", {}, categoryName(item.category_id)),
      el(
        "span",
        { class: "priority" },
        `Приоритет ${Math.round(item.priority_score)}`,
      ),
    ),
    el("h2", {}, item.title),
    el(
      "p",
      { class: "address" },
      item.address ||
        `${item.latitude.toFixed(5)}, ${item.longitude.toFixed(5)}`,
    ),
    el(
      "div",
      { class: "card-meta" },
      badge(item.status),
      item.is_hidden ? el("span", { class: "badge" }, "Скрыто") : null,
    ),
    el(
      "div",
      { class: "card-footer" },
      el(
        "span",
        {},
        item.assignment?.executor_name ||
          item.assignment?.organization_name ||
          "Не назначено",
      ),
      el("time", {}, date(item.created_at)),
    ),
  );
}

function reportCard(report) {
  return el(
    "article",
    { class: "report-card" },
    el(
      "div",
      { class: "card-meta" },
      el(
        "span",
        {},
        report.comment_id ? "Жалоба на комментарий" : "Жалоба на обращение",
      ),
      el("time", {}, date(report.created_at)),
    ),
    el("h2", {}, report.title),
    el("p", { class: "report-reason" }, report.reason),
    el("blockquote", {}, report.text),
    el(
      "div",
      { class: "actions" },
      report.incident_id
        ? button("Открыть обращение", () => openIncident(report.incident_id))
        : null,
      report.status === "pending"
        ? [
            button(
              "Скрыть содержимое",
              () => resolveReport(report, true),
              "danger",
            ),
            button("Отклонить жалобу", () => resolveReport(report, false)),
          ]
        : el(
            "span",
            { class: "badge" },
            report.status === "actioned" ? "Приняты меры" : "Жалоба отклонена",
          ),
    ),
  );
}

function resolveReport(report, hide) {
  dialog(
    hide ? "Скрыть содержимое?" : "Отклонить жалобу?",
    el(
      "p",
      {},
      hide
        ? `Будет скрыт ${report.comment_id ? "указанный комментарий" : "весь материал обращения"}. Действие попадёт в журнал.`
        : "Жалоба будет закрыта без скрытия содержимого.",
    ),
    "Подтвердить",
    async () => {
      await apiAction(`/moderation/reports/${report.id}/resolve?hide=${hide}`);
      await loadQueue();
    },
  );
}

async function openIncident(id) {
  const run = ++detailSequence;
  clearImages();
  detailNode.hidden = false;
  workspace.classList.add("split");
  detailNode.replaceChildren(
    el("p", { class: "empty", role: "status" }, "Загружаем обращение…"),
  );
  try {
    const item = await api.request(`/operations/incidents/${id}`);
    if (run !== detailSequence || !api.user) return;
    detailNode.replaceChildren(
      el(
        "div",
        { class: "detail-toolbar" },
        el("span", {}, `Обращение ${id.slice(0, 8)}`),
        button("Закрыть карточку", closeDetail, "quiet"),
      ),
      el("h2", { class: "detail-title", tabindex: "-1" }, item.title),
      el(
        "div",
        { class: "actions" },
        badge(item.status),
        item.is_hidden
          ? el("span", { class: "badge" }, "Скрыто от жителей")
          : null,
      ),
    );
    const body = el("div", { class: "detail-body" });
    const tabs = el("nav", { class: "detail-tabs", "aria-label": "Карточка" });
    const panes = [
      ["overview", "Обзор"],
      ["actions", "Действия"],
      ...(moderator() ? [["duplicates", "Дубликаты"]] : []),
      ["activity", "История и ответы"],
    ];
    const show = (key) => {
      for (const b of tabs.children) {
        b.classList.toggle("active", b.dataset.tab === key);
        b.setAttribute("aria-pressed", String(b.dataset.tab === key));
      }
      body.replaceChildren();
      if (key === "overview") overview(body, item, run);
      if (key === "actions") actions(body, item);
      if (key === "duplicates") duplicates(body, item);
      if (key === "activity") activity(body, item);
    };
    for (const [key, title] of panes) {
      const b = button(title, () => show(key), "tab");
      b.dataset.tab = key;
      tabs.append(b);
    }
    detailNode.append(tabs, body);
    show("overview");
    detailNode.querySelector(".detail-title").focus({ preventScroll: true });
  } catch (error) {
    if (run === detailSequence && api.user)
      detailNode.replaceChildren(
        errorBox(error),
        button("Повторить", () => openIncident(id)),
        button("Закрыть карточку", closeDetail),
      );
  }
}

function overview(body, item, run) {
  const gallery = el("div", { class: "gallery" });
  body.append(
    gallery,
    el(
      "div",
      { class: "facts" },
      fact("Категория", categoryName(item.category_id)),
      fact("Приоритет", Math.round(item.priority_score)),
      fact("Подтверждения", item.confirmation_count),
      fact("Опасность", `${item.severity} / 10`),
    ),
    el(
      "p",
      { class: "description" },
      item.description || "Описание не добавлено.",
    ),
    el("h3", {}, "Место проблемы"),
    el("p", {}, item.address || "Адрес не указан"),
    el(
      "p",
      { class: "muted" },
      `${item.latitude.toFixed(6)}, ${item.longitude.toFixed(6)}`,
    ),
    el("h3", {}, "Приоритет"),
    el(
      "p",
      {},
      item.priority_explanation?.ru || "Расчёт приоритета недоступен",
    ),
    el("h3", {}, "Ответственный"),
    el(
      "p",
      {},
      item.assignment
        ? `${item.assignment.organization_name} · ${item.assignment.executor_name || "Исполнитель не указан"}`
        : "Организация пока не назначена",
    ),
    item.assignment
      ? el("p", { class: "muted" }, `Срок: ${date(item.assignment.due_at)}`)
      : null,
    el("small", {}, `Опубликовано ${date(item.created_at)}`),
  );
  if (!item.media.length)
    gallery.append(el("p", { class: "notice" }, "Фотографии отсутствуют."));
  for (const media of item.media) {
    const figure = el(
      "figure",
      {},
      el("p", { role: "status" }, "Загрузка фото…"),
    );
    gallery.append(figure);
    const load = async () => {
      try {
        const blob = await api.request(media.url.replace("/api/v1", ""), {
          blob: true,
        });
        if (run !== detailSequence || !figure.isConnected) return;
        const url = URL.createObjectURL(blob);
        urls.push(url);
        const photo = el("img", {
          src: url,
          alt:
            media.media_type === "after_image"
              ? "Фото результата"
              : "Фото проблемы",
        });
        const zoom = button(
          "",
          () => {
            const box = dialog(
              photo.alt,
              el("img", { src: url, alt: photo.alt, class: "zoom-photo" }),
              "Закрыть",
              async () => {},
            );
            box.classList.add("photo-dialog");
          },
          "photo-button",
        );
        zoom.append(photo);
        zoom.setAttribute("aria-label", `Увеличить: ${photo.alt}`);
        figure.replaceChildren(
          zoom,
          el("figcaption", {}, `${photo.alt} · публичная обработанная версия`),
        );
      } catch (error) {
        if (figure.isConnected)
          figure.replaceChildren(
            errorBox(error),
            button("Повторить фото", load),
          );
      }
    };
    load();
  }
}
const fact = (name, value) =>
  el("div", {}, el("small", {}, name), el("strong", {}, value));

function actions(body, item) {
  const changed = async () => {
    if (!body.isConnected) return;
    await openIncident(item.id);
    await loadQueue({ keepDetail: true });
  };
  const statusesToShow = [
    [item.status, `${statuses[item.status]} (сейчас)`],
    ...item.allowed_statuses.map((s) => [s, statuses[s]]),
  ];
  const controls = [
    field("Статус обращения", select("status", statusesToShow, item.status)),
    ...(moderator()
      ? [
          field(
            "Категория обращения",
            select(
              "category_id",
              categories.map((c) => [c.id, c.name_ru]),
              item.category_id,
            ),
          ),
        ]
      : []),
    field(
      "Публичное пояснение",
      el("textarea", {
        name: "note",
        rows: 3,
        maxlength: 1000,
        placeholder: "Что проверили или выполнили",
      }),
      "Появится в истории обращения.",
    ),
  ];
  body.append(
    actionForm(
      "Проверка и статус",
      controls,
      "Сохранить изменения",
      async (data) => {
        await apiAction(
          `/moderation/incidents/${item.id}`,
          { ...Object.fromEntries(data), expected_updated_at: item.updated_at },
          "PATCH",
        );
        await changed();
      },
      {
        description:
          "Решение подтверждают жители. Организация может только отметить выполнение.",
      },
    ),
  );
  const orgSelect = select(
    "organization_id",
    organizations.map((o) => [o.id, o.name_ru]),
    item.assignment?.organization_id || "",
    "Выберите организацию",
  );
  orgSelect.required = true;
  const orgSearch = input("orgSearch", "", {
    type: "search",
    placeholder: "Название организации",
    maxlength: 100,
  });
  const searchFeedback = el("div");
  let orgPage = 1,
    orgTerm = "";
  const more = button("Ещё организации", () => searchOrgs(false));
  more.hidden = true;
  const searchOrgs = async (reset) => {
    if (reset) {
      orgPage = 1;
      orgTerm = orgSearch.value;
    }
    more.disabled = true;
    try {
      const result = await api.request(
        `/operations/organizations?q=${encodeURIComponent(orgTerm)}&page=${orgPage}`,
      );
      if (!orgSelect.isConnected) return;
      if (reset)
        orgSelect.replaceChildren(
          el("option", { value: "" }, "Выберите организацию"),
        );
      for (const o of result.items)
        orgSelect.append(el("option", { value: o.id }, o.name_ru));
      more.hidden = !result.has_more;
      orgPage++;
      searchFeedback.replaceChildren();
    } catch (error) {
      searchFeedback.replaceChildren(errorBox(error));
    } finally {
      more.disabled = false;
    }
  };
  body.append(
    actionForm(
      "Назначение ответственного",
      [
        ...(moderator()
          ? [
              field("Поиск организации", orgSearch),
              el(
                "div",
                { class: "actions" },
                button("Найти организацию", () => searchOrgs(true)),
                more,
              ),
              searchFeedback,
            ]
          : []),
        field("Организация", orgSelect),
        field(
          "Исполнитель",
          input("executor_name", item.assignment?.executor_name || "", {
            maxlength: 100,
            placeholder: "Имя или название бригады",
          }),
        ),
        field(
          "Срок выполнения",
          input("due_at", localDate(item.assignment?.due_at), {
            type: "datetime-local",
          }),
          "Время в часовом поясе вашего устройства.",
        ),
      ],
      "Назначить",
      async (data) => {
        await apiAction(`/moderation/incidents/${item.id}/assignments`, {
          organization_id: data.get("organization_id"),
          executor_name: data.get("executor_name") || null,
          due_at: data.get("due_at")
            ? new Date(data.get("due_at")).toISOString()
            : null,
        });
        await changed();
      },
    ),
  );
  if (api.user.role !== "moderator" && !item.is_hidden) {
    body.append(
      actionForm(
        "Ответ жителям",
        [
          field(
            "Текст ответа",
            el("textarea", {
              name: "text",
              rows: 4,
              required: true,
              maxlength: 2000,
            }),
          ),
        ],
        "Опубликовать ответ",
        async (data) => {
          await apiAction(`/operations/incidents/${item.id}/responses`, {
            text: data.get("text"),
          });
          await changed();
        },
        {
          description:
            "Ответ будет виден жителям в комментариях и истории. Не указывайте личные данные.",
        },
      ),
    );
    body.append(photoForm(item, changed));
  }
  if (moderator())
    body.append(
      el(
        "div",
        { class: "action-form" },
        el("h3", {}, "Видимость обращения"),
        el(
          "p",
          { class: "muted" },
          "Скрытое обращение исчезнет из публичной ленты и карты.",
        ),
        button(
          item.is_hidden ? "Вернуть в ленту" : "Скрыть обращение",
          () => {
            dialog(
              item.is_hidden ? "Вернуть обращение?" : "Скрыть обращение?",
              el("p", {}, item.title),
              "Подтвердить",
              async () => {
                await apiAction(
                  `/moderation/incidents/${item.id}`,
                  {
                    status: item.status,
                    is_hidden: !item.is_hidden,
                    expected_updated_at: item.updated_at,
                  },
                  "PATCH",
                );
                await changed();
              },
            );
          },
          item.is_hidden ? "secondary" : "danger",
        ),
      ),
    );
}

function localDate(value) {
  if (!value) return "";
  const d = new Date(value);
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
}

function photoForm(item, changed) {
  let uploadId = null;
  const file = input("photo", "", {
    type: "file",
    accept: "image/jpeg,image/png,image/webp",
  });
  const preview = el("div", { class: "upload-preview" });
  const reviewed = input("reviewed", "true", {
    type: "checkbox",
    required: true,
    disabled: true,
  });
  const load = async (fullFrame) => {
    uploadId = null;
    reviewed.checked = false;
    reviewed.disabled = true;
    preview.replaceChildren(el("p", { role: "status" }, "Обрабатываем фото…"));
    upload.disabled = blur.disabled = file.disabled = true;
    try {
      const selected = file.files[0];
      if (
        !selected ||
        !["image/jpeg", "image/png", "image/webp"].includes(selected.type) ||
        selected.size > 10 * 1024 * 1024
      )
        throw new Error("Выберите JPEG, PNG или WebP размером до 10 МБ.");
      const data = new FormData();
      data.append("file", selected);
      data.append("full_frame", String(fullFrame));
      const result = await apiAction("/uploads/images", data);
      const bytes = await api.request(`/uploads/${result.id}/preview`, {
        blob: true,
      });
      if (!preview.isConnected) return;
      const url = URL.createObjectURL(bytes);
      urls.push(url);
      preview.replaceChildren(
        el("img", { src: url, alt: "Предпросмотр фото результата" }),
        el(
          "p",
          { class: "notice" },
          result.privacy_method.startsWith("whole_frame")
            ? "Применено полное размытие. Проверьте изображение."
            : "Автопоиск может пропустить лица и номера. Проверьте фото; при необходимости размойте целиком.",
        ),
      );
      uploadId = result.id;
      reviewed.disabled = false;
    } catch (error) {
      if (preview.isConnected) preview.replaceChildren(errorBox(error));
    } finally {
      upload.disabled = blur.disabled = file.disabled = false;
    }
  };
  const upload = button("Обработать и показать", () => load(false));
  const blur = button("Размыть целиком", () => load(true));
  file.addEventListener("change", () => {
    uploadId = null;
    reviewed.checked = false;
    reviewed.disabled = true;
    preview.replaceChildren();
  });
  return actionForm(
    "Фотография результата",
    [
      field("Фото после выполнения", file, "JPEG, PNG, WebP · до 10 МБ"),
      el("div", { class: "actions" }, upload, blur),
      preview,
      el(
        "label",
        { class: "check" },
        reviewed,
        "Проверено: видимых лиц, читаемых номеров и личных данных нет.",
      ),
    ],
    "Опубликовать фото",
    async () => {
      if (!uploadId || !reviewed.checked)
        throw new Error(
          "Сначала обработайте фотографию и подтвердите проверку.",
        );
      await apiAction(
        `/moderation/incidents/${item.id}/after-photo/${uploadId}?reviewed_by_user=true`,
      );
      await changed();
    },
  );
}

async function duplicates(body, item) {
  const panel = el(
    "div",
    {},
    el("p", { role: "status" }, "Ищем похожие обращения…"),
  );
  body.append(panel);
  try {
    const result = await api.request(
      `/operations/incidents/${item.id}/duplicates`,
    );
    if (!panel.isConnected) return;
    panel.replaceChildren(
      el(
        "p",
        { class: "notice" },
        "Похожие обращения — подсказка. Объединение выполняется только после вашего подтверждения. Комментарии и подтверждения остаются у исходного обращения.",
      ),
    );
    if (!result.items.length)
      panel.append(
        el(
          "p",
          { class: "empty" },
          "Вероятные дубликаты поблизости не найдены.",
        ),
      );
    for (const candidate of result.items)
      panel.append(
        el(
          "article",
          { class: "duplicate-card" },
          el("h3", {}, candidate.incident.title),
          el("p", {}, candidate.incident.description),
          badge(candidate.incident.status),
          el(
            "p",
            { class: "muted" },
            `${Math.round(candidate.distance_meters)} м · сходство ${Math.round(candidate.similarity_score * 100)}%`,
          ),
          el(
            "div",
            { class: "actions" },
            button("Посмотреть кандидат", () =>
              openIncident(candidate.incident.id),
            ),
            button(
              "Объединить с этим",
              () => {
                dialog(
                  "Подтвердить дубликат",
                  el(
                    "div",
                    {},
                    el(
                      "p",
                      {},
                      `Скрыть «${item.title}» как дубликат «${candidate.incident.title}»?`,
                    ),
                    el(
                      "p",
                      { class: "muted" },
                      "Основным останется выбранное обращение. Автоматического переноса комментариев и подтверждений нет.",
                    ),
                  ),
                  "Объединить",
                  async () => {
                    await apiAction(`/moderation/incidents/${item.id}/merge`, {
                      target_incident_id: candidate.incident.id,
                    });
                    await openIncident(candidate.incident.id);
                    await loadQueue({ keepDetail: true });
                  },
                );
              },
              "primary",
            ),
          ),
        ),
      );
  } catch (error) {
    if (panel.isConnected)
      panel.replaceChildren(
        errorBox(error),
        button("Повторить поиск", () => {
          body.replaceChildren();
          duplicates(body, item);
        }),
      );
  }
}

function activity(body, item) {
  for (const kind of ["timeline", "comments"]) {
    let current = 1;
    const list = el("div", { class: "activity-list" });
    const feedback = el("div");
    const more = button("Загрузить ещё", () => load());
    body.append(
      el(
        "section",
        { class: "activity-section" },
        el(
          "h3",
          {},
          kind === "timeline" ? "История обращения" : "Комментарии и ответы",
        ),
        list,
        feedback,
        more,
      ),
    );
    const load = async () => {
      more.disabled = true;
      feedback.replaceChildren();
      try {
        const result = await api.request(
          `/operations/incidents/${item.id}/activity?kind=${kind}&page=${current}`,
        );
        if (!list.isConnected) return;
        if (current === 1 && !result.items.length)
          list.append(el("p", { class: "muted" }, "Записей пока нет."));
        result.items.forEach((row) =>
          list.append(
            el(
              "article",
              { class: "activity-item" },
              el(
                "div",
                { class: "card-meta" },
                kind === "timeline"
                  ? badge(row.status)
                  : el("strong", {}, row.author_name),
                el("time", {}, date(row.created_at)),
              ),
              el("p", {}, row.note || row.text || ""),
              row.is_hidden ? el("small", {}, "Скрыто") : null,
            ),
          ),
        );
        more.hidden = !result.has_more;
        current++;
      } catch (error) {
        if (feedback.isConnected) feedback.replaceChildren(errorBox(error));
      } finally {
        more.disabled = false;
      }
    };
    load();
  }
}

login();
