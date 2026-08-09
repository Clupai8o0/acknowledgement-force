export class ForceApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = "ForceApiError";
    this.status = status;
  }
}

export class ForceClient {
  constructor(private base: string, private token: string) {}

  private async request<T>(
    method: string,
    path: string,
    body?: unknown
  ): Promise<T> {
    const res = await fetch(`${this.base}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${this.token}`,
        ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    let parsed: unknown = null;
    if (text) {
      try {
        parsed = JSON.parse(text);
      } catch {
        parsed = text;
      }
    }
    if (!res.ok) {
      let msg = res.statusText;
      if (
        parsed &&
        typeof parsed === "object" &&
        "error" in parsed &&
        typeof (parsed as { error: unknown }).error === "string"
      ) {
        msg = (parsed as { error: string }).error;
      }
      throw new ForceApiError(res.status, msg);
    }
    return parsed as T;
  }

  me() {
    return this.request<{ user_id: string; email: string }>("GET", "/api/v1/me");
  }

  getContract() {
    return this.request<{ contract_md: string; updated_at: string | null }>(
      "GET",
      "/api/v1/contract"
    );
  }
  updateContract(contract_md: string) {
    return this.request<{ contract_md: string; updated_at: string | null }>(
      "PUT",
      "/api/v1/contract",
      { contract_md }
    );
  }

  listQuotes() {
    return this.request<{ quotes: string[] }>("GET", "/api/v1/quotes");
  }
  addQuote(text: string) {
    return this.request<{ quotes: string[]; index: number }>(
      "POST",
      "/api/v1/quotes",
      { text }
    );
  }
  deleteQuote(index: number) {
    return this.request<{ quotes: string[] }>(
      "DELETE",
      `/api/v1/quotes/${index}`
    );
  }

  listGoals() {
    return this.request<{ goals: { id: string; label: string }[] }>(
      "GET",
      "/api/v1/goals"
    );
  }
  setGoals(goals: { id?: string; label: string }[]) {
    return this.request<{ goals: { id: string; label: string }[] }>(
      "PUT",
      "/api/v1/goals",
      { goals }
    );
  }

  getReflection() {
    return this.request<{ reflection: string; updated_at: string | null }>(
      "GET",
      "/api/v1/reflection"
    );
  }
  setReflection(reflection: string) {
    return this.request<{ reflection: string; updated_at: string | null }>(
      "PUT",
      "/api/v1/reflection",
      { reflection }
    );
  }
}
