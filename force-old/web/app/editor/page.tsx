import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { type Content, EMPTY_CONTENT, type Goal } from "@/lib/content";
import Editor from "./editor";

export const metadata = { title: "Your contract — Acknowledgement Force" };

export default async function EditorPage() {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) redirect("/login");

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data } = await supabase
    .from("contents")
    .select("contract_md, quotes, goals, reflection, updated_at")
    .eq("user_id", user.id)
    .maybeSingle();

  const content: Content = data
    ? {
        contract_md: data.contract_md ?? "",
        quotes: (data.quotes as string[]) ?? [],
        goals: (data.goals as Goal[]) ?? [],
        reflection: data.reflection ?? "",
        updated_at: data.updated_at ?? undefined,
      }
    : EMPTY_CONTENT;

  return <Editor initial={content} email={user.email ?? ""} userId={user.id} />;
}
