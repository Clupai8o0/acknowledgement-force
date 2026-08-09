"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { type Content, type Goal, slugId } from "@/lib/content";
import BrandMark from "../brand-mark";
import styles from "./editor.module.css";

export default function Editor({
  initial,
  email,
  userId,
}: {
  initial: Content;
  email: string;
  userId: string;
}) {
  const router = useRouter();
  const [contract, setContract] = useState(initial.contract_md);
  const [quotes, setQuotes] = useState<string[]>(initial.quotes);
  const [goals, setGoals] = useState<Goal[]>(initial.goals);
  const [reflection, setReflection] = useState(initial.reflection);

  const [theme, setTheme] = useState<"light" | "dark">("light");

  useEffect(() => {
    const t = document.documentElement.getAttribute("data-theme") as "light" | "dark";
    if (t) setTheme(t);
  }, []);

  function toggleTheme() {
    const next = theme === "light" ? "dark" : "light";
    setTheme(next);
    document.documentElement.setAttribute("data-theme", next);
    try { localStorage.setItem("af-landing-theme", next); } catch (_) {}
  }

  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(true);
  const [justSaved, setJustSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const baseline = useMemo(() => JSON.stringify(initial), [initial]);
  const current = JSON.stringify({
    contract_md: contract,
    quotes,
    goals,
    reflection,
    updated_at: initial.updated_at,
  });
  const dirty = current !== baseline && !saved;

  function markChanged() {
    setSaved(false);
    setJustSaved(false);
    setError(null);
  }

  async function save() {
    setSaving(true);
    setError(null);
    const supabase = createClient();
    const { error } = await supabase.from("contents").upsert(
      {
        user_id: userId,
        contract_md: contract,
        quotes,
        goals,
        reflection,
      },
      { onConflict: "user_id" }
    );
    setSaving(false);
    if (error) {
      setError(error.message);
      return;
    }
    setSaved(true);
    setJustSaved(true);
    window.setTimeout(() => setJustSaved(false), 2400);
    router.refresh();
  }

  async function logout() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  return (
    <div className={styles.page}>
      <div className={styles.bar}>
        <a href="/" className={styles.brand}>
          <BrandMark />
          Acknowledgement Force
        </a>
        <div className={styles.barRight}>
          <button
            className={styles.themeBtn}
            onClick={toggleTheme}
            aria-label={theme === "light" ? "Switch to dark mode" : "Switch to light mode"}
            title={theme === "light" ? "Dark mode" : "Light mode"}
          >
            {theme === "light" ? (
              <svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              </svg>
            ) : (
              <svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="5" />
                <line x1="12" y1="1" x2="12" y2="3" />
                <line x1="12" y1="21" x2="12" y2="23" />
                <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
                <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
                <line x1="1" y1="12" x2="3" y2="12" />
                <line x1="21" y1="12" x2="23" y2="12" />
                <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
                <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
              </svg>
            )}
          </button>
          <Link href="/settings/api-keys" className={styles.linkBtn}>
            Settings
          </Link>
          <span className={styles.email}>{email}</span>
          <button className={styles.linkBtn} onClick={logout}>
            Log out
          </button>
        </div>
      </div>

      <div className={styles.wrap}>
        {/* Quotes */}
        <section className={styles.section}>
          <h2 className={styles.sectionHead}>Quotes</h2>
          <p className={styles.sectionSub}>
            Lines that vibe with you. Your Mac shows one of these as the daily
            motivation. Add as many as you like.
          </p>
          {quotes.map((q, i) => (
            <div key={i} className={`${styles.row} ${styles.quoteRow}`}>
              <textarea
                className={styles.textarea}
                rows={2}
                value={q}
                placeholder="A line that keeps you honest…"
                onChange={(e) => {
                  const next = [...quotes];
                  next[i] = e.target.value;
                  setQuotes(next);
                  markChanged();
                }}
              />
              <button
                className={styles.iconBtn}
                aria-label="Remove quote"
                onClick={() => {
                  setQuotes(quotes.filter((_, j) => j !== i));
                  markChanged();
                }}
              >
                ×
              </button>
            </div>
          ))}
          <button
            className={styles.addBtn}
            onClick={() => {
              setQuotes([...quotes, ""]);
              markChanged();
            }}
          >
            + Add quote
          </button>
        </section>

        {/* Daily goals */}
        <section className={styles.section}>
          <h2 className={styles.sectionHead}>Daily goals</h2>
          <p className={styles.sectionSub}>
            Your non-negotiables. These become the checklist on your Mac.
          </p>
          {goals.map((g, i) => (
            <div key={g.id} className={styles.row}>
              <input
                value={g.label}
                placeholder="e.g. LeetCode: 1 problem"
                onChange={(e) => {
                  const next = [...goals];
                  next[i] = { ...g, label: e.target.value };
                  setGoals(next);
                  markChanged();
                }}
              />
              <button
                className={styles.iconBtn}
                aria-label="Move up"
                disabled={i === 0}
                onClick={() => {
                  const next = [...goals];
                  [next[i - 1], next[i]] = [next[i], next[i - 1]];
                  setGoals(next);
                  markChanged();
                }}
              >
                ↑
              </button>
              <button
                className={styles.iconBtn}
                aria-label="Move down"
                disabled={i === goals.length - 1}
                onClick={() => {
                  const next = [...goals];
                  [next[i + 1], next[i]] = [next[i], next[i + 1]];
                  setGoals(next);
                  markChanged();
                }}
              >
                ↓
              </button>
              <button
                className={styles.iconBtn}
                aria-label="Remove goal"
                onClick={() => {
                  setGoals(goals.filter((_, j) => j !== i));
                  markChanged();
                }}
              >
                ×
              </button>
            </div>
          ))}
          <button
            className={styles.addBtn}
            onClick={() => {
              setGoals([...goals, { id: slugId(`goal ${goals.length + 1}`), label: "" }]);
              markChanged();
            }}
          >
            + Add goal
          </button>
        </section>

        {/* Contract */}
        <section className={styles.section}>
          <h2 className={styles.sectionHead}>The contract</h2>
          <p className={styles.sectionSub}>
            Plain Markdown — headings, <code>**bold**</code>, lists, <code>{"> "}</code>
            quotes. <code>{"{{DATE}}"}</code> is replaced with today&apos;s date on
            your Mac.
          </p>
          <textarea
            className={`${styles.textarea} ${styles.mono}`}
            rows={20}
            value={contract}
            onChange={(e) => {
              setContract(e.target.value);
              markChanged();
            }}
          />
        </section>

        {/* Reflection */}
        <section className={styles.section}>
          <h2 className={styles.sectionHead}>Reflection</h2>
          <p className={styles.sectionSub}>
            A free space — where your head is at, what you&apos;re working
            through. Update it whenever.
          </p>
          <textarea
            className={styles.textarea}
            rows={6}
            value={reflection}
            placeholder="Today I'm focused on…"
            onChange={(e) => {
              setReflection(e.target.value);
              markChanged();
            }}
          />
        </section>
      </div>

      <div className={styles.saveBar}>
        {error ? (
          <span className={styles.saveError}>{error}</span>
        ) : justSaved ? (
          <span className={`${styles.hint} ${styles.savedFlash}`}>✓ Saved</span>
        ) : (
          <span className={styles.hint}>
            {dirty ? "Unsaved changes" : "All changes saved"}
          </span>
        )}
        <button
          className="btn btn-primary"
          onClick={save}
          disabled={saving || (!dirty && saved)}
        >
          {saving && <span className={styles.spinner} aria-hidden="true" />}
          {saving ? "Saving…" : "Save"}
        </button>
      </div>
    </div>
  );
}
