import type { MetadataRoute } from 'next';
import { modes, siteUrl } from '@/lib/site';

// Generated once at build time (static export).
export const dynamic = 'force-static';

export default function sitemap(): MetadataRoute.Sitemap {
  const paths = [
    '/',
    '/games',
    ...modes.flatMap((m) => (m.href ? [m.href] : [])),
    '/pricing',
    '/privacy',
    '/terms',
  ];
  return paths.map((p) => ({ url: `${siteUrl}${p === '/' ? '' : p}` }));
}
