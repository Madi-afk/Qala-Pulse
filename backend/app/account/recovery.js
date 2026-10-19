import { el, field, input, actionForm } from "/console/ui.js";

const params = new URLSearchParams(location.hash.slice(1));
const token = params.get("token");
let language = params.get("lang") === "kk" ? "kk" : "ru";
// Keep the single-use secret out of the address bar, history and referrers.
history.replaceState(null, "", location.pathname);
const words = {
  ru: {
    title: "Восстановление пароля",
    password: "Новый пароль",
    repeat: "Повторите пароль",
    hint: "От 10 до 128 символов",
    send: "Отправить ссылку",
    save: "Сохранить пароль",
    sent: "Если активная учётная запись существует, письмо придёт на указанный адрес. Проверьте папку «Спам». Повторный запрос возможен через минуту.",
    saved:
      "Пароль изменён. Вернитесь в приложение или панель и войдите заново.",
    failed: "Не удалось выполнить запрос. Проверьте соединение и повторите.",
    invalid: "Ссылка истекла или уже использована. Запросите новую ссылку.",
    mismatch: "Пароли не совпадают",
    back: "Войти в панель",
    retry: "Запросить новую ссылку",
    limited: "Слишком много запросов. Подождите минуту.",
    unavailable: "Отправка писем временно недоступна. Повторите позже.",
  },
  kk: {
    title: "Құпиясөзді қалпына келтіру",
    password: "Жаңа құпиясөз",
    repeat: "Құпиясөзді қайталаңыз",
    hint: "10–128 таңба",
    send: "Сілтеме жіберу",
    save: "Құпиясөзді сақтау",
    sent: "Белсенді тіркелгі бар болса, көрсетілген мекенжайға хат келеді. «Спам» қалтасын тексеріңіз. Бір минуттан кейін қайталауға болады.",
    saved: "Құпиясөз өзгертілді. Қолданбаға немесе панельге қайта кіріңіз.",
    failed: "Сұрау орындалмады. Байланысты тексеріп, қайталаңыз.",
    invalid:
      "Сілтеменің мерзімі өткен немесе ол қолданылған. Жаңа сілтеме сұраңыз.",
    mismatch: "Құпиясөздер сәйкес емес",
    back: "Панельге кіру",
    retry: "Жаңа сілтеме сұрау",
    limited: "Сұрау тым көп. Бір минут күтіңіз.",
    unavailable: "Хат жіберу уақытша қолжетімсіз. Кейінірек қайталаңыз.",
  },
};
function render() {
  document.documentElement.lang = language;
  const w = words[language];
  const status = el("p", { role: "status" });
  const controls = token
    ? [
        field(
          w.password,
          input("password", "", {
            type: "password",
            required: true,
            minlength: 10,
            maxlength: 128,
            autocomplete: "new-password",
          }),
          w.hint,
        ),
        field(
          w.repeat,
          input("repeat", "", {
            type: "password",
            required: true,
            minlength: 10,
            maxlength: 128,
            autocomplete: "new-password",
          }),
        ),
      ]
    : [
        field(
          "Email",
          input("email", "", {
            type: "email",
            required: true,
            maxlength: 254,
            autocomplete: "email",
          }),
        ),
      ];
  const form = actionForm(
    w.title,
    controls,
    token ? w.save : w.send,
    async (data) => {
      status.textContent = "";
      if (token && data.get("password") !== data.get("repeat"))
        throw new Error(w.mismatch);
      let response;
      try {
        response = await fetch(
          `/api/v1/auth/${token ? "reset-password" : "forgot-password"}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(
              token
                ? { token, password: data.get("password") }
                : { email: data.get("email") },
            ),
          },
        );
      } catch {
        throw new Error(w.failed);
      }
      if (!response.ok)
        throw new Error(
          response.status === 429
            ? w.limited
            : response.status === 503
              ? w.unavailable
              : token
                ? w.invalid
                : w.failed,
        );
      form.hidden = true;
      status.textContent = token ? w.saved : w.sent;
    },
    { successMessage: "" },
  );
  const toggle = el(
    "select",
    {
      "aria-label": "Language / Тіл",
      onchange: (event) => {
        language = event.target.value;
        render();
      },
    },
    el("option", { value: "ru", selected: language === "ru" }, "Русский"),
    el("option", { value: "kk", selected: language === "kk" }, "Қазақша"),
  );
  document
    .querySelector("#app")
    .replaceChildren(
      el("h1", {}, "QalaPulse"),
      toggle,
      form,
      status,
      el("p", {}, el("a", { href: "/account/" }, w.retry)),
      el("a", { href: "/console/" }, w.back),
    );
}
render();
