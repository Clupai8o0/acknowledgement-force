"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { ALL_SCOPES } from "@/lib/api-keys";
import { createApiKey, revokeApiKey } from "../actions";
import styles from "../settings.module.css";
import type { ApiKeyRow } from "./page";

export default function ApiKeysClient({ initial }: { initial: ApiKeyRow[] }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  // Snapshot "now" once at mount so the table render stays pure.
  const [renderedAt] = useState(() => Date.now());

  const [name, setName] = useState("");
  const [scopes, setScopes] = useState<string[]>([...ALL_SCOPES]);
  const [expiresAt, setExpiresAt] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [revealed, setRevealed] = useState<{ raw: string; name: string } | null>(
    null
  );
  const [copied, setCopied] = useState(false);

  function toggleScope(scope: string) {
    setScopes((curr) =>
      curr.includes(scope) ? curr.filter((s) => s !== scope) : [...curr, scope]
    );
  }

  function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setCopied(false);
    startTransition(async () => {
      const res = await createApiKey({
        name,
        scopes,
        expiresAt: expiresAt || null,
      });
      if (!res.ok) {
        setError(res.error);
        return;
      }
      setRevealed({ raw: res.raw, name: res.name });
      setName("");
      setScopes([...ALL_SCOPES]);
      setExpiresAt("");
      router.refresh();
    });
  }

  function onRevoke(id: string, name: string) {
    if (!confirm(`Revoke "${name}"? Clients using this key will stop working.`)) {
      return;
    }
    startTransition(async () => {
      const res = await revokeApiKey(id);
      if (!res.ok) {
        setError(res.error);
        return;
      }
      router.refresh();
    });
  }

  function copy() {
    if (!revealed) return;
    navigator.clipboard.writeText(revealed.raw).then(
      () => {
        setCopied(true);
        window.setTimeout(() => setCopied(false), 1800);
      },
      () => setCopied(false)
    );
  }

  return (
    <>
      <section className={styles.section}>
        <h2 className={styles.sectionHead}>Create an API key</h2>
        <p className={styles.sectionSub}>
          Use with the MCP server, scripts, or any HTTP client. The key is shown
          once — copy it somewhere safe.
        </p>

        {error && <div className={styles.error}>{error}</div>}

        <form onSubmit={onSubmit}>
          <div className={styles.field}>
            <label htmlFor="key-name">Name</label>
            <input
              id="key-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Claude Desktop, Personal laptop…"
              maxLength={80}
              required
            />
          </div>

          <div className={styles.field}>
            <label>Scopes</label>
            <div className={styles.scopeGrid}>
              {ALL_SCOPES.map((scope) => (
                <label key={scope} className={styles.scopeCheck}>
                  <input
                    type="checkbox"
                    checked={scopes.includes(scope)}
                    onChange={() => toggleScope(scope)}
                  />
                  <code>{scope}</code>
                </label>
              ))}
            </div>
          </div>

          <div className={styles.field}>
            <label htmlFor="key-expiry">Expires (optional)</label>
            <input
              id="key-expiry"
              type="datetime-local"
              value={expiresAt}
              onChange={(e) => setExpiresAt(e.target.value)}
            />
          </div>

          <div className={styles.formActions}>
            <button
              className="btn btn-primary"
              type="submit"
              disabled={pending}
            >
              {pending ? "Creating…" : "Create key"}
            </button>
          </div>
        </form>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionHead}>Your keys</h2>
        <p className={styles.sectionSub}>
          Revoked keys are kept in the table for audit; they can no longer
          authenticate.
        </p>

        {initial.length === 0 ? (
          <div className={styles.empty}>No keys yet.</div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Prefix</th>
                  <th>Scopes</th>
                  <th>Last used</th>
                  <th>Created</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {initial.map((k) => {
                  const revoked = !!k.revoked_at;
                  const expired =
                    !!k.expires_at && new Date(k.expires_at).getTime() < renderedAt;
                  return (
                    <tr key={k.id}>
                      <td>
                        <div>{k.name}</div>
                        {(revoked || expired) && (
                          <div className={styles.revoked}>
                            {revoked ? "revoked" : "expired"}
                          </div>
                        )}
                      </td>
                      <td className={styles.mono}>{k.prefix}••••</td>
                      <td>
                        <div className={styles.scopeTags}>
                          {k.scopes.map((s) => (
                            <span key={s} className={styles.tag}>
                              {s}
                            </span>
                          ))}
                        </div>
                      </td>
                      <td className={styles.muted}>
                        {k.last_used_at
                          ? new Date(k.last_used_at).toLocaleString()
                          : "—"}
                      </td>
                      <td className={styles.muted}>
                        {new Date(k.created_at).toLocaleDateString()}
                      </td>
                      <td>
                        {!revoked && !expired && (
                          <button
                            className={styles.revokeBtn}
                            onClick={() => onRevoke(k.id, k.name)}
                            disabled={pending}
                          >
                            Revoke
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {revealed && (
        <div className={styles.modalBackdrop} role="dialog" aria-modal="true">
          <div className={styles.modal}>
            <h3 className={styles.modalTitle}>“{revealed.name}” is ready</h3>
            <p className={styles.modalSub}>
              Copy this key now — you won&apos;t be able to see it again.
            </p>
            <div className={styles.keyBox}>
              <span className={styles.keyBoxText}>{revealed.raw}</span>
              <button className={styles.copyBtn} onClick={copy}>
                {copied ? "Copied" : "Copy"}
              </button>
            </div>
            <div className={styles.warning}>
              Store it in a password manager or env file. Anyone with this key
              can read and modify your content.
            </div>
            <div className={styles.modalActions}>
              <button
                className="btn btn-primary"
                onClick={() => setRevealed(null)}
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
