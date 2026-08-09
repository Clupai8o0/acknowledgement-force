"use client";

import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import styles from "./settings.module.css";

export default function SettingsTopBar({ email }: { email: string }) {
  const router = useRouter();
  async function logout() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }
  return (
    <div className={styles.barRight}>
      <span className={styles.email}>{email}</span>
      <button className={styles.linkBtn} onClick={logout}>
        Log out
      </button>
    </div>
  );
}
