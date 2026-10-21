export default function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) return res.status(503).json({ error: 'Supabase public configuration is missing.' });
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'https:' || !parsed.hostname.endsWith('.supabase.co')) throw new Error('Invalid URL');
  } catch {
    return res.status(503).json({ error: 'Supabase URL is invalid.' });
  }
  res.setHeader('Cache-Control', 'public, max-age=300');
  return res.status(200).json({ url, publishableKey: key });
}
