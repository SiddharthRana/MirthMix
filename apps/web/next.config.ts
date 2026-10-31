import type { NextConfig } from 'next';

// Every page is static (the web player runs in the browser), so the site is exported as plain files
// to `out/` and served by Cloudflare Pages. Security headers live in public/_headers, because
// `headers()` doesn't apply to a static export.
const nextConfig: NextConfig = {
  output: 'export',
  reactCompiler: true,
  typedRoutes: true,
  poweredByHeader: false,
  transpilePackages: [
    '@mirthmix/content',
    '@mirthmix/design-tokens',
    '@mirthmix/game-engine',
    '@mirthmix/plans',
  ],
};

export default nextConfig;
