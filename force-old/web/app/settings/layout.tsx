import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import BrandMark from "../brand-mark";
import SettingsTopBar from "./settings-top-bar";
import styles from "./settings.module.css";

export const metadata = { title: "Settings — Force" };

export default async function SettingsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) redirect("/login");

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  return (
    <div className={styles.page}>
      <div className={styles.bar}>
        <Link href="/editor" className={styles.brand}>
          <BrandMark />
          Acknowledgement Force
        </Link>
        <SettingsTopBar email={user.email ?? ""} />
      </div>

      <div className={styles.layout}>
        <nav className={styles.nav} aria-label="Settings sections">
          <Link href="/settings/profile" className={styles.navItem}>
            Profile
          </Link>
          <Link href="/settings/api-keys" className={styles.navItem}>
            API keys
          </Link>
        </nav>
        <div className={styles.content}>{children}</div>
      </div>
    </div>
  );
}
