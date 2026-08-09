"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import BrandMark from "../brand-mark";
import styles from "../auth/auth.module.css";

export default function SignupPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setNotice(null);
    setPending(true);
    const form = new FormData(e.currentTarget);
    const email = String(form.get("email") ?? "");
    const password = String(form.get("password") ?? "");

    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      setPending(false);
      return;
    }

    const supabase = createClient();
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) {
      setError(error.message);
      setPending(false);
      return;
    }
    if (data.session) {
      // Email confirmation disabled — we're logged in immediately.
      router.push("/editor");
      router.refresh();
      return;
    }
    // Email confirmation enabled.
    setNotice("Check your email to confirm your account, then log in.");
    setPending(false);
  }

  return (
    <div className={styles.shell}>
      <div className={styles.card}>
        <Link href="/" className={styles.brand}>
          <BrandMark />
          Acknowledgement Force
        </Link>
        <h1 className={styles.title}>Create your account</h1>
        <p className={styles.sub}>
          Your contract is seeded with sensible defaults — edit it any time.
        </p>

        {error && <div className={styles.error}>{error}</div>}
        {notice && <div className={styles.notice}>{notice}</div>}

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
              autoComplete="new-password"
              minLength={8}
              required
            />
          </div>
          <button
            className={`btn btn-primary ${styles.submit}`}
            type="submit"
            disabled={pending}
          >
            {pending && <span className={styles.spinner} aria-hidden="true" />}
            {pending ? "Creating…" : "Create account"}
          </button>
        </form>

        <p className={styles.alt}>
          Already have an account? <Link href="/login">Log in</Link>
        </p>
      </div>
    </div>
  );
}
