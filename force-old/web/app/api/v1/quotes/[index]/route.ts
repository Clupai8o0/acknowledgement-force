import type { NextRequest } from "next/server";
import { authenticate, authError } from "@/lib/auth/apiKey";
import { createAdminClient } from "@/lib/supabase/admin";
import { badRequest, serverError } from "@/lib/api-utils";

export async function DELETE(
  req: NextRequest,
  ctx: { params: Promise<{ index: string }> }
) {
  const auth = await authenticate(req, "quotes:write");
  if (!auth.ok) return authError(auth);

  const { index } = await ctx.params;
  const i = Number.parseInt(index, 10);
  if (!Number.isInteger(i) || i < 0) {
    return badRequest("Index must be a non-negative integer");
  }

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("contents")
    .select("quotes")
    .eq("user_id", auth.userId)
    .maybeSingle();
  if (error) return serverError(error.message);

  const current = (data?.quotes as string[]) ?? [];
  if (i >= current.length) {
    return Response.json({ error: "Quote not found" }, { status: 404 });
  }
  const next = current.filter((_, j) => j !== i);

  const { error: writeErr } = await supabase
    .from("contents")
    .upsert(
      { user_id: auth.userId, quotes: next },
      { onConflict: "user_id" }
    );
  if (writeErr) return serverError(writeErr.message);

  return Response.json({ quotes: next });
}
