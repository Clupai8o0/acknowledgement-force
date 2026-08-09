import { authenticate, authError } from "@/lib/auth/apiKey";
import { createAdminClient } from "@/lib/supabase/admin";
import { badRequest, LIMITS, readJson, serverError } from "@/lib/api-utils";

export async function GET(req: Request) {
  const auth = await authenticate(req, "reflection:read");
  if (!auth.ok) return authError(auth);

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("contents")
    .select("reflection, updated_at")
    .eq("user_id", auth.userId)
    .maybeSingle();

  if (error) return serverError(error.message);
  return Response.json({
    reflection: data?.reflection ?? "",
    updated_at: data?.updated_at ?? null,
  });
}

export async function PUT(req: Request) {
  const auth = await authenticate(req, "reflection:write");
  if (!auth.ok) return authError(auth);

  const body = await readJson(req);
  if (!body || typeof body.reflection !== "string") {
    return badRequest("Body must be { reflection: string }");
  }
  if (body.reflection.length > LIMITS.reflectionChars) {
    return badRequest(`reflection must be at most ${LIMITS.reflectionChars} characters`);
  }

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("contents")
    .upsert(
      { user_id: auth.userId, reflection: body.reflection },
      { onConflict: "user_id" }
    )
    .select("reflection, updated_at")
    .single();

  if (error) return serverError(error.message);
  return Response.json({
    reflection: data.reflection,
    updated_at: data.updated_at,
  });
}
