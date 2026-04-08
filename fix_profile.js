const { Client } = require('pg');
async function run() {
  const client = new Client({
    connectionString: 'postgresql://postgres:HaJaCp95lSSspgvn@db.rankmykjnicectabtxdf.supabase.co:5432/postgres',
    ssl: { rejectUnauthorized: false }
  });
  await client.connect();

  const user = await client.query("SELECT id FROM auth.users WHERE email = 'yelkarmib@gmail.com'");
  if (!user.rows[0]) { console.log('User not found'); return; }
  const uid = user.rows[0].id;
  console.log('User ID:', uid);

  await client.query(
    "INSERT INTO profiles (id, full_name, role) VALUES ($1, $2, $3::user_role) ON CONFLICT (id) DO NOTHING",
    [uid, 'HWEB', 'business_owner']
  );
  console.log('Profile created!');

  const check = await client.query('SELECT id, full_name, role FROM profiles WHERE id = $1', [uid]);
  console.log('Profile:', JSON.stringify(check.rows[0]));

  await client.end();
}
run().catch(e => console.error(e));
