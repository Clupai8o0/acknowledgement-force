import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import ApiKeysClient from "./api-keys-client";

export const metadata = { title: "API keys — Force" };

export type ApiKeyRow = {
  id: string;
  name: string;
  prefix: string;
  scopes: string[];
  last_used_at: string | null;
  expires_at: string | null;
  revoked_at: string | null;
  created_at: string;
};

export default async function ApiKeysPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data } = await supabase
    .from("api_keys")
    .select(
      "id, name, prefix, scopes, last_used_at, expires_at, revoked_at, created_at"
    )
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  return <ApiKeysClient initial={(data as ApiKeyRow[]) ?? []} />;
}
