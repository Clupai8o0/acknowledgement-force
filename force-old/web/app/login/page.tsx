"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import BrandMark from "../brand-mark";
import styles from "../auth/auth.module.css";

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setPending(true);
    const form = new FormData(e.currentTarget);
    const email = String(form.get("email") ?? "");
    const password = String(form.get("password") ?? "");

    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      setError(error.message);
      setPending(false);
      return;
    }
    router.push("/editor");
    router.refresh();
  }

  return (
    <div className={styles.shell}>
      <div className={styles.card}>
        <Link href="/" className={styles.brand}>
          <BrandMark />
          Acknowledgement Force
        </Link>
        <h1 className={styles.title}>Welcome back</h1>
        <p className={styles.sub}>Log in to edit your contract from anywhere.</p>

        {error && <div className={styles.error}>{error}</div>}

        <form onSubmit={onSubmit}>
          <div className={styles.field}>
            <label htmlFor="email">Email</label>
            <input id="email" name="email" type="email" autoComplete="email" required />
          </div>
          <div className={styles.field}>
            <label htmlFor="password">Password</label>
            <input
              id="password"
              name="password"
              type="password"
              autoComplete="current-password"
              required
            />
          </div>
          <button
            className={`btn btn-primary ${styles.submit}`}
            type="submit"
            disabled={pending}
          >
            {pending && <span className={styles.spinner} aria-hidden="true" />}
            {pending ? "Logging in…" : "Log in"}
          </button>
        </form>

        <p className={styles.alt}>
          No account yet? <Link href="/signup">Create one</Link>
        </p>
      </div>
    </div>
  );
}
