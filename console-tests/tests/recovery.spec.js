import { test, expect } from "@playwright/test";

test("recovery preserves email on network failure and shows generic success", async ({
  page,
}) => {
  await page.goto("/console/");
  await page.getByRole("link", { name: "Забыли пароль?" }).click();
  await page.getByLabel("Email", { exact: true }).fill("resident@example.com");
  await page.route("**/api/v1/auth/forgot-password", (route) => route.abort());
  await page.getByRole("button", { name: "Отправить ссылку" }).click();
  await expect(page.getByRole("alert")).toBeVisible();
  await expect(page.getByLabel("Email", { exact: true })).toHaveValue(
    "resident@example.com",
  );
  await page.route("**/api/v1/auth/forgot-password", (route) =>
    route.fulfill({ status: 202, json: { status: "accepted" } }),
  );
  await page.getByRole("button", { name: "Отправить ссылку" }).click();
  await expect(page.getByRole("status")).toContainText(
    "Если активная учётная запись существует",
  );
});

test("reset removes secret from URL, checks repeated password and supports Kazakh", async ({
  page,
}) => {
  const secret = "test-token-only-".repeat(4);
  await page.goto(`/account/#token=${secret}&lang=kk`);
  await expect(page).toHaveURL(/\/account\/$/);
  await expect(
    page.getByRole("heading", { name: "Құпиясөзді қалпына келтіру" }),
  ).toBeVisible();
  await page
    .getByLabel("Жаңа құпиясөз", { exact: true })
    .fill("New-password-2026!");
  await page
    .getByLabel("Құпиясөзді қайталаңыз", { exact: true })
    .fill("Different-password!");
  await page.getByRole("button", { name: "Құпиясөзді сақтау" }).click();
  await expect(page.getByRole("alert")).toContainText(
    "Құпиясөздер сәйкес емес",
  );
  await page
    .getByLabel("Құпиясөзді қайталаңыз", { exact: true })
    .fill("New-password-2026!");
  await page.route("**/api/v1/auth/reset-password", async (route) => {
    expect(route.request().postDataJSON()).toEqual({
      token: secret,
      password: "New-password-2026!",
    });
    await route.fulfill({ status: 200, json: { status: "password_changed" } });
  });
  await page.getByRole("button", { name: "Құпиясөзді сақтау" }).click();
  await expect(page.getByRole("status")).toContainText("Құпиясөз өзгертілді");
});
