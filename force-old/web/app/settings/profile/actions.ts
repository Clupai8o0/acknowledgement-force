"use server";

import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function updateDisplayName(formData: FormData) {
  const name = (formData.get("display_name") as string | null)?.trim() ?? "";
  const supabase = await createClient();
  const { error } = await supabase.auth.updateUser({
    data: { display_name: name },
  });
  if (error) return { error: error.message };
  revalidatePath("/settings/profile");
  return { error: null };
}
