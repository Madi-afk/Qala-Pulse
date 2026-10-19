export class ApiError extends Error {
  constructor(message, code = "network_error", requestId = "") {
    super(message);
    this.code = code;
    this.requestId = requestId;
  }
}

// Tokens only live in this tab's memory. Reloading deliberately requires login.
export class Api {
  tokens = null;
  user = null;
  epoch = 0;
  refreshing = null;
  onExpired = () => {};

  async raw(path, options = {}) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 30000);
    try {
      return await fetch(`/api/v1${path}`, {
        ...options,
        signal: controller.signal,
        cache: "no-store",
        credentials: "omit",
      });
    } catch {
      throw new ApiError(
        "Нет ответа сервера. Данные формы сохранены. Проверьте соединение; перед повтором действия обновите карточку.",
      );
    } finally {
      clearTimeout(timer);
    }
  }

  async decode(response, blob = false) {
    if (response.status === 204) return null;
    if (response.ok) return blob ? response.blob() : response.json();
    const payload = await response.json().catch(() => ({}));
    throw new ApiError(
      payload.error?.message || `Ошибка сервера (${response.status})`,
      payload.error?.code || "http_error",
      payload.error?.request_id || "",
    );
  }

  async login(email, password) {
    const epoch = ++this.epoch;
    const data = await this.decode(
      await this.raw("/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      }),
    );
    if (epoch !== this.epoch)
      throw new ApiError("Сессия изменена", "session_changed");
    if (!["moderator", "organization", "admin"].includes(data.user.role)) {
      await this.raw("/auth/logout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh_token: data.refresh_token }),
      }).catch(() => {});
      throw new ApiError(
        "Панель доступна модераторам и организациям. Для жителей используйте приложение.",
        "forbidden",
      );
    }
    this.tokens = data;
    this.user = data.user;
    return data.user;
  }

  async refresh(epoch) {
    if (!this.refreshing) {
      const token = this.tokens?.refresh_token;
      this.refreshing = (async () => {
        try {
          const data = await this.decode(
            await this.raw("/auth/refresh", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ refresh_token: token }),
            }),
          );
          if (epoch !== this.epoch)
            throw new ApiError("Сессия изменена", "session_changed");
          this.tokens = data;
        } catch (error) {
          if (
            epoch === this.epoch &&
            [
              "invalid_refresh",
              "refresh_reused",
              "invalid_token",
              "authentication_required",
            ].includes(error.code)
          ) {
            this.clear();
            this.onExpired();
          }
          throw error;
        }
      })().finally(() => {
        this.refreshing = null;
      });
    }
    return this.refreshing;
  }

  async request(path, { method = "GET", body, blob = false } = {}) {
    const epoch = this.epoch;
    const send = () =>
      this.raw(path, {
        method,
        headers: {
          Authorization: `Bearer ${this.tokens?.access_token}`,
          ...(body && !(body instanceof FormData)
            ? { "Content-Type": "application/json" }
            : {}),
        },
        body:
          body instanceof FormData
            ? body
            : body
              ? JSON.stringify(body)
              : undefined,
      });
    let response = await send();
    if (response.status === 401 && this.tokens && epoch === this.epoch) {
      await this.refresh(epoch);
      response = await send();
    }
    if (epoch !== this.epoch)
      throw new ApiError("Сессия изменена", "session_changed");
    return this.decode(response, blob);
  }

  clear() {
    ++this.epoch;
    this.tokens = null;
    this.user = null;
  }
  async logout() {
    const token = this.tokens?.refresh_token;
    this.clear();
    if (token)
      await this.decode(
        await this.raw("/auth/logout", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refresh_token: token }),
        }),
      );
  }
}
