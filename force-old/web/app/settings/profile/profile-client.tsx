"use client";

import { useState, useTransition } from "react";
import { updateDisplayName } from "./actions";
import styles from "../settings.module.css";

export default function ProfileClient({
  displayName,
}: {
  displayName: string;
}) {
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [isPending, startTransition] = useTransition();

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setSaved(false);
    setError(null);
    const data = new FormData(e.currentTarget);
    startTransition(async () => {
      const result = await updateDisplayName(data);
      if (result.error) {
        setError(result.error);
      } else {
        setSaved(true);
      }
    });
  }

  return (
    <section className={styles.section}>
      <h2 className={styles.sectionHead}>Profile</h2>
      <p className={styles.sectionSub}>
        Your name appears in the contract wherever{" "}
        <code>{"{{NAME}}"}</code> is used.
      </p>

      {error && <div className={styles.error}>{error}</div>}

      <form onSubmit={handleSubmit}>
        <div className={styles.field}>
          <label htmlFor="display_name">Display name</label>
          <input
            id="display_name"
            name="display_name"
            type="text"
            defaultValue={displayName}
            placeholder="e.g. Jane Smith"
            maxLength={120}
          />
        </div>

        <div className={styles.formActions}>
          <button type="submit" className="btn-primary" disabled={isPending}>
            {isPending ? "Saving…" : "Save"}
          </button>
          {saved && (
            <span style={{ color: "var(--mute)", fontSize: "0.88rem" }}>
              Saved.
            </span>
          )}
        </div>
      </form>
    </section>
  );
}
