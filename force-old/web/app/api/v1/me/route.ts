import { authenticate, authError } from "@/lib/auth/apiKey";
import { createAdminClient } from "@/lib/supabase/admin";

export async function GET(req: Request) {
  const auth = await authenticate(req, null);
  if (!auth.ok) return authError(auth);

  const supabase = createAdminClient();
  const { data, error } = await supabase.auth.admin.getUserById(auth.userId);
  if (error || !data.user) {
    return Response.json({ error: "User lookup failed" }, { status: 500 });
  }
  return Response.json({ user_id: auth.userId, email: data.user.email });
}
