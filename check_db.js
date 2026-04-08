const { Client } = require('pg');
async function run() {
  const client = new Client({
    connectionString: 'postgresql://postgres:HaJaCp95lSSspgvn@db.rankmykjnicectabtxdf.supabase.co:5432/postgres',
    ssl: { rejectUnauthorized: false }
  });
  await client.connect();

  // Check businesses
  const biz = await client.query('SELECT * FROM businesses LIMIT 5');
  console.log('Businesses:', JSON.stringify(biz.rows, null, 2));

  // Check profiles
  const profiles = await client.query('SELECT id, full_name, role FROM profiles');
  console.log('\nProfiles:', JSON.stringify(profiles.rows, null, 2));

  // Check RLS policies on businesses
  const rls = await client.query("SELECT polname, polcmd, pg_get_expr(polqual, polrelid) as qual, pg_get_expr(polwithcheck, polrelid) as with_check FROM pg_policy WHERE polrelid = 'businesses'::regclass");
  console.log('\nRLS on businesses:', JSON.stringify(rls.rows, null, 2));

  await client.end();
}
run().catch(e => console.error(e));
