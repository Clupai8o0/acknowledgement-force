import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import ProfileClient from "./profile-client";

export const metadata = { title: "Profile — Force" };

export default async function ProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const displayName = (user.user_metadata?.display_name as string) ?? "";

  return <ProfileClient displayName={displayName} />;
}
