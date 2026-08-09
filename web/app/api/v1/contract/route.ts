import { authenticate, authError } from "@/lib/auth/apiKey";
import { createAdminClient } from "@/lib/supabase/admin";
import { badRequest, LIMITS, readJson, serverError } from "@/lib/api-utils";

export async function GET(req: Request) {
  const auth = await authenticate(req, "contract:read");
  if (!auth.ok) return authError(auth);

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("contents")
    .select("contract_md, updated_at")
    .eq("user_id", auth.userId)
    .maybeSingle();

  if (error) return serverError(error.message);
  return Response.json({
    contract_md: data?.contract_md ?? "",
    updated_at: data?.updated_at ?? null,
  });
}

export async function PUT(req: Request) {
  const auth = await authenticate(req, "contract:write");
  if (!auth.ok) return authError(auth);

  const body = await readJson(req);
  if (!body || typeof body.contract_md !== "string") {
    return badRequest("Body must be { contract_md: string }");
  }
  if (body.contract_md.length > LIMITS.contractChars) {
    return badRequest(`contract_md must be at most ${LIMITS.contractChars} characters`);
  }

  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from("contents")
    .upsert(
      { user_id: auth.userId, contract_md: body.contract_md },
      { onConflict: "user_id" }
    )
    .select("contract_md, updated_at")
    .single();

  if (error) return serverError(error.message);
  return Response.json({
    contract_md: data.contract_md,
    updated_at: data.updated_at,
  });
}
