import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// Next 16 renamed `middleware` to `proxy`. This refreshes the Supabase auth
// session on every request and gates the editor behind authentication.
export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  // Supabase not configured yet — let the app run (landing, static pages) and
  // skip auth gating rather than 500 every route.
  if (!url || !key) return response;

  const supabase = createServerClient(url, key, {
      // Auth cookies are signed JWTs. They can't be httpOnly (the browser
      // Supabase client needs to read them), so we pin the rest: HTTPS-only
      // in production and SameSite=Lax so cross-site requests never carry
      // the session.
      cookieOptions: {
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
      },
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          );
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const path = request.nextUrl.pathname;

  if ((path.startsWith("/editor") || path.startsWith("/settings")) && !user) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
  if ((path === "/login" || path === "/signup") && user) {
    return NextResponse.redirect(new URL("/editor", request.url));
  }

  return response;
}

export const config = {
  matcher: [
    // Run on everything except static assets and the JSON-only public API
    // (the API uses its own bearer-token auth, no cookie refresh needed).
    "/((?!api/|_next/static|_next/image|favicon.ico|assets|.*\\.(?:png|jpg|jpeg|gif|svg|ico|mp4|webm)$).*)",
  ],
};
