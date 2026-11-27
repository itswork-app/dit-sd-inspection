import { type NextRequest } from "next/server";
import { getRequestId } from "@/lib/api/errors";
import { updateSession } from "@/lib/supabase/proxy";

export async function proxy(request: NextRequest) {
  // Establish one trusted correlation token before session refresh so logs,
  // downstream request context and the response header share the same value.
  const requestId = getRequestId(request);
  request.headers.set("x-request-id", requestId);

  const response = await updateSession(request);
  response.headers.set("X-Request-Id", requestId);
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)"]
};
