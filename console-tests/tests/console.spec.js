import { test, expect } from "@playwright/test";
import path from "node:path";

test("refresh network failure preserves the operator's form", async ({
  page,
}) => {
  await login(page);
  await openRoad(page);
  await page.getByRole("button", { name: "Действия", exact: true }).click();
  await page
    .getByLabel("Публичное пояснение")
    .fill("Сохранить при сбое refresh");
  await page.route("**/api/v1/moderation/incidents/*", (route) =>
    route.fulfill({
      status: 401,
      json: { error: { code: "invalid_token", message: "Expired" } },
    }),
  );
  await page.route("**/api/v1/auth/refresh", (route) => route.abort("failed"));
  await page.getByRole("button", { name: "Сохранить изменения" }).click();
  await expect(page.getByRole("alert")).toContainText("Нет ответа сервера");
  await expect(page.getByLabel("Публичное пояснение")).toHaveValue(
    "Сохранить при сбое refresh",
  );
  await expect(
    page.getByRole("button", { name: "Войти", exact: true }),
  ).toHaveCount(0);
});

let ids;
test.beforeEach(async ({ request, page }) => {
  ids = await (await request.post("/__test__/reset")).json();
  await page.goto("/console/");
});
async function login(page, role = "moderator") {
  await page
    .getByLabel("Email", { exact: true })
    .fill(`${role}@qalapulse.example.com`);
  await page.getByLabel("Пароль", { exact: true }).fill("QalaPulse-Demo-2026!");
  await page.getByRole("button", { name: "Войти", exact: true }).click();
  await expect(
    page.getByRole("heading", {
      name: role === "organization" ? "Мои назначения" : "Очередь обращений",
    }),
  ).toBeVisible();
  await expect(page.locator(".incident-card").first()).toBeVisible();
}
async function openRoad(page) {
  await page.getByLabel("Поиск", { exact: true }).fill("Яма у школы");
  await page.getByRole("button", { name: "Применить", exact: true }).click();
  await page
    .locator(".incident-card")
    .filter({
      has: page.getByRole("heading", { name: "Яма у школы № 12", exact: true }),
    })
    .click();
  await expect(page.locator(".detail-title")).toHaveText("Яма у школы № 12");
}
test("login role guard, XSS-safe details, image preview and category review", async ({
  page,
}) => {
  await page.getByLabel("Email").fill("citizen@qalapulse.example.com");
  await page.getByLabel("Пароль").fill("QalaPulse-Demo-2026!");
  await page.getByRole("button", { name: "Войти", exact: true }).click();
  await expect(page.getByRole("alert")).toContainText("Панель доступна");
  await login(page);
  await openRoad(page);
  await expect(page.locator(".description")).toContainText("<img src=x");
  await expect(page.locator(".description img")).toHaveCount(0);
  await expect(
    page.getByRole("img", { name: "Фото проблемы", exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Действия", exact: true }).click();
  await page
    .getByLabel("Категория обращения", { exact: true })
    .selectOption("sidewalk_damage");
  await page
    .getByLabel("Статус обращения", { exact: true })
    .selectOption("under_review");
  await page
    .getByLabel("Публичное пояснение")
    .fill("Проверили: повреждён тротуар.");
  await page.getByRole("button", { name: "Сохранить изменения" }).click();
  await expect(page.locator(".facts")).toContainText("тротуар");
  await expect(page.locator(".detail>.actions")).toContainText("На проверке");
  expect(
    await page.evaluate(() => ({
      local: localStorage.length,
      session: sessionStorage.length,
    })),
  ).toEqual({ local: 0, session: 0 });
});

test("moderator assigns, organization completes work, replies and publishes reviewed photo", async ({
  page,
}) => {
  await login(page);
  await openRoad(page);
  await page.getByRole("button", { name: "Действия", exact: true }).click();
  await page
    .getByLabel("Организация", { exact: true })
    .selectOption({ index: 1 });
  await page.getByLabel("Исполнитель", { exact: true }).fill("Бригада 12");
  await page.getByRole("button", { name: "Назначить", exact: true }).click();
  await expect(page.locator(".detail")).toContainText("Бригада 12");
  await page.getByRole("button", { name: "Выйти", exact: true }).click();
  await login(page, "organization");
  await openRoad(page);
  await expect(
    page.getByRole("button", { name: "Жалобы на контент", exact: true }),
  ).toHaveCount(0);
  for (const status of [
    "accepted",
    "in_progress",
    "resolved_pending_confirmation",
  ]) {
    await page.getByRole("button", { name: "Действия", exact: true }).click();
    await page
      .getByLabel("Статус обращения", { exact: true })
      .selectOption(status);
    await page.getByRole("button", { name: "Сохранить изменения" }).click();
    await expect(
      page.getByRole("button", { name: "Сохранить изменения" }),
    ).toHaveCount(0);
  }
  await expect(page.locator(".detail>.actions")).toContainText(
    "Ожидает подтверждения",
  );
  await page.getByRole("button", { name: "Действия", exact: true }).click();
  await page
    .getByLabel("Текст ответа")
    .fill("Ремонт завершён. Просим жителей проверить результат.");
  await page.getByRole("button", { name: "Опубликовать ответ" }).click();
  await page.getByRole("button", { name: "История и ответы" }).click();
  await expect(page.locator(".activity-list").last()).toContainText(
    "Ремонт завершён",
  );
  await page.getByRole("button", { name: "Действия", exact: true }).click();
  await page
    .getByLabel("Фото после выполнения")
    .setInputFiles(
      path.resolve("../backend/tests/fixtures/privacy/astronaut.png"),
    );
  await page.getByRole("button", { name: "Обработать и показать" }).click();
  await expect(
    page.getByRole("img", { name: "Предпросмотр фото результата" }),
  ).toBeVisible();
  await page.getByRole("checkbox", { name: /Проверено/ }).check();
  await page
    .getByRole("button", { name: "Опубликовать фото", exact: true })
    .click();
  await expect(
    page.getByRole("img", { name: "Фото результата", exact: true }),
  ).toBeVisible();
});

test("duplicates require dialog confirmation, cancel preserves source", async ({
  page,
}) => {
  await login(page);
  await openRoad(page);
  await page.getByRole("button", { name: "Дубликаты", exact: true }).click();
  const candidate = page
    .locator(".duplicate-card")
    .filter({ hasText: "Яма у школы № 12 — повтор" });
  await candidate.getByRole("button", { name: "Объединить с этим" }).click();
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Отмена" })
    .click();
  await expect(page.locator(".detail-title")).toHaveText("Яма у школы № 12");
  await candidate.getByRole("button", { name: "Объединить с этим" }).click();
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Объединить", exact: true })
    .click();
  await expect(page.locator(".detail-title")).toHaveText(
    "Яма у школы № 12 — повтор",
  );
  await page.getByRole("button", { name: "Закрыть карточку" }).click();
  await page.getByLabel("Видимость").selectOption("hidden");
  await page.getByRole("button", { name: "Применить" }).click();
  await expect(page.locator(".incident-card")).toHaveCount(1);
});

test("reports hide content only after confirmation and refresh pending queue", async ({
  page,
}) => {
  await login(page);
  await page
    .getByRole("button", { name: "Жалобы на контент", exact: true })
    .click();
  await expect(page.locator(".report-card")).toHaveCount(3);
  await page
    .getByRole("button", { name: "Скрыть содержимое", exact: true })
    .first()
    .click();
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Подтвердить" })
    .click();
  await expect(page.locator(".report-card")).toHaveCount(2);
  await page.getByLabel("Состояние жалобы").selectOption("actioned");
  await page.getByRole("button", { name: "Применить" }).click();
  await expect(page.locator(".report-card")).toHaveCount(1);
  await expect(page.locator(".report-card")).toContainText("Приняты меры");
});

test("network errors preserve form, refresh rotates tokens once for concurrent requests", async ({
  page,
}) => {
  await login(page);
  await openRoad(page);
  await page.getByRole("button", { name: "Действия", exact: true }).click();
  await page
    .getByLabel("Публичное пояснение")
    .fill("Не потерять это пояснение");
  await page.route("**/api/v1/moderation/incidents/*", (route) =>
    route.abort("failed"),
  );
  await page.getByRole("button", { name: "Сохранить изменения" }).click();
  await expect(page.getByRole("alert")).toContainText("Нет ответа сервера");
  await expect(page.getByLabel("Публичное пояснение")).toHaveValue(
    "Не потерять это пояснение",
  );
  await page.unroute("**/api/v1/moderation/incidents/*");
  const seen = new Set();
  let refreshes = 0;
  await page.route("**/api/v1/auth/refresh", async (route) => {
    refreshes++;
    await new Promise((resolve) => setTimeout(resolve, 200));
    await route.continue();
  });
  await page.route(
    "**/api/v1/operations/incidents/*/activity?*",
    async (route) => {
      const url = route.request().url();
      if (!seen.has(url)) {
        seen.add(url);
        await route.fulfill({
          status: 401,
          json: { error: { code: "invalid_token", message: "Expired" } },
        });
      } else await route.continue();
    },
  );
  await page.getByRole("button", { name: "История и ответы" }).click();
  await expect(page.locator(".activity-list").last()).toContainText(
    "Демонстрационный комментарий",
  );
  expect(refreshes).toBe(1);
  await page.reload();
  await expect(
    page.getByRole("button", { name: "Войти", exact: true }),
  ).toBeVisible();
});

test("mobile layout is usable and queue errors retry", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await login(page);
  await page.route("**/api/v1/operations/incidents?*", (route) =>
    route.fulfill({
      status: 503,
      json: {
        error: { code: "service_unavailable", message: "Временно недоступно" },
      },
    }),
  );
  await page.getByRole("button", { name: "Обновить очередь" }).click();
  await expect(page.getByRole("alert")).toContainText("Временно недоступно");
  await page.unroute("**/api/v1/operations/incidents?*");
  await page.getByRole("button", { name: "Повторить загрузку" }).click();
  await expect(page.locator(".incident-card").first()).toBeVisible();
  await page.locator(".incident-card").first().click();
  await expect(page.locator(".detail-title")).toBeVisible();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBeTruthy();
  await page.getByRole("button", { name: "Закрыть карточку" }).click();
  await expect(page.locator(".incident-card").first()).toBeVisible();
});
