export const statuses = {
  published: "Опубликовано",
  under_review: "На проверке",
  accepted: "Принято организацией",
  in_progress: "В работе",
  resolved_pending_confirmation: "Ожидает подтверждения жителей",
  resolved: "Решение подтверждено",
  rejected: "Отклонено",
};
export const roles = {
  moderator: "Модератор",
  organization: "Организация",
  admin: "Администратор",
};
export const date = (value) =>
  value
    ? new Intl.DateTimeFormat("ru", {
        dateStyle: "medium",
        timeStyle: "short",
      }).format(new Date(value))
    : "Не указан";
export function el(tag, attrs = {}, ...children) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(attrs)) {
    if (key.startsWith("on")) node.addEventListener(key.slice(2), value);
    else if (key === "class") node.className = value;
    else if (key === "checked" || key === "disabled" || key === "selected")
      node[key] = value;
    else if (value !== null && value !== undefined)
      node.setAttribute(key, String(value));
  }
  for (const child of children.flat(Infinity))
    if (child !== null && child !== undefined)
      node.append(
        child instanceof Node ? child : document.createTextNode(String(child)),
      );
  return node;
}
export const button = (text, action, cls = "secondary") =>
  el("button", { type: "button", class: cls, onclick: action }, text);
export const badge = (status) =>
  el("span", { class: `badge ${status}` }, statuses[status] || status);
let fieldSequence = 0;
export function field(label, control, hint = "") {
  const id = `field-${++fieldSequence}`;
  control.id = id;
  if (hint) control.setAttribute("aria-describedby", `${id}-hint`);
  return el(
    "div",
    { class: "field" },
    el("label", { for: id }, label),
    control,
    hint ? el("small", { id: `${id}-hint` }, hint) : null,
  );
}
export const input = (name, value = "", attrs = {}) =>
  el("input", { name, value, ...attrs });
export function select(name, entries, current = "", empty = null) {
  return el(
    "select",
    { name },
    empty === null ? null : el("option", { value: "" }, empty),
    entries.map(([value, label]) =>
      el("option", { value, selected: value === current }, label),
    ),
  );
}
export function errorBox(error) {
  return el(
    "div",
    { class: "notice error", role: "alert" },
    error.message,
    error.requestId ? el("small", {}, `Код запроса: ${error.requestId}`) : null,
  );
}
export function announce(message) {
  document.querySelector("#announcer").textContent = message;
}
export function dialog(title, content, confirmText, action) {
  const box = el("dialog", { "aria-labelledby": "dialog-title" });
  const feedback = el("div");
  const confirm = button(
    confirmText,
    async () => {
      confirm.disabled = cancel.disabled = true;
      feedback.replaceChildren();
      try {
        await action();
        box.close();
      } catch (error) {
        feedback.replaceChildren(errorBox(error));
      } finally {
        confirm.disabled = cancel.disabled = false;
      }
    },
    "primary",
  );
  const cancel = button("Отмена", () => box.close());
  box.append(
    el("h2", { id: "dialog-title" }, title),
    content,
    feedback,
    el("div", { class: "actions" }, cancel, confirm),
  );
  box.addEventListener("cancel", (event) => {
    if (confirm.disabled) event.preventDefault();
  });
  box.addEventListener("close", () => box.remove());
  document.body.append(box);
  box.showModal();
  cancel.focus();
  return box;
}

export function actionForm(
  title,
  controls,
  submitLabel,
  action,
  { description = "", successMessage = "Сохранено" } = {},
) {
  const feedback = el("div", { class: "feedback" });
  const submit = el(
    "button",
    { type: "submit", class: "primary" },
    submitLabel,
  );
  const form = el(
    "form",
    { class: "action-form" },
    el("h3", {}, title),
    description ? el("p", { class: "muted" }, description) : null,
    controls,
    feedback,
    submit,
  );
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const data = new FormData(form);
    const inputs = [...form.querySelectorAll("input,textarea,select,button")];
    const disabled = inputs.map((n) => n.disabled);
    inputs.forEach((n) => {
      n.disabled = true;
    });
    form.setAttribute("aria-busy", "true");
    feedback.replaceChildren();
    try {
      await action(data);
      if (form.isConnected && successMessage)
        feedback.replaceChildren(
          el("p", { role: "status", class: "success" }, successMessage),
        );
      if (successMessage) announce(successMessage);
    } catch (error) {
      if (form.isConnected) feedback.replaceChildren(errorBox(error));
    } finally {
      inputs.forEach((n, i) => {
        n.disabled = disabled[i];
      });
      form.removeAttribute("aria-busy");
    }
  });
  return form;
}
