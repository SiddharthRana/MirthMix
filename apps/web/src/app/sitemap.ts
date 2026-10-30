import type { MetadataRoute } from 'next';
import { modes, siteUrl } from '@/lib/site';

export default function sitemap(): MetadataRoute.Sitemap {
  const paths = [
    '/',
    '/games',
    ...modes.flatMap((m) => (m.href ? [m.href] : [])),
    '/privacy',
    '/terms',
  ];
  return paths.map((p) => ({ url: `${siteUrl}${p === '/' ? '' : p}` }));
}
