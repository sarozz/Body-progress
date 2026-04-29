// Supabase Edge Function: delete-account
//
// Deletes the calling user's auth row, which cascades to all owned data
// thanks to the FK ON DELETE CASCADE on profiles/body_checkins.
//
// Deploy with: `supabase functions deploy delete-account --no-verify-jwt=false`
// The client invokes this function while signed in.

// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  try {
    const auth = req.headers.get('Authorization');
    if (!auth) return new Response('Unauthorized', { status: 401 });

    const url = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Identify the caller via the user JWT.
    const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
      global: { headers: { Authorization: auth } },
    });
    const { data: { user }, error: userErr } = await userClient.auth.getUser();
    if (userErr || !user) return new Response('Unauthorized', { status: 401 });

    // Service-role client to perform the destructive op.
    const admin = createClient(url, serviceKey);
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) return new Response(error.message, { status: 500 });

    return new Response(JSON.stringify({ deleted: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e: any) {
    return new Response(String(e?.message ?? e), { status: 500 });
  }
});
