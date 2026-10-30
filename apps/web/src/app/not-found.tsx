import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="py-24 text-center">
      <h1 className="font-display text-5xl font-bold">Page not found</h1>
      <p className="mt-3 text-lg text-muted">That page doesn&rsquo;t exist, or it moved.</p>
      <Link
        href="/"
        className="brand-gradient mt-8 inline-flex min-h-14 items-center rounded-full px-7 text-lg font-bold"
      >
        Go home
      </Link>
    </div>
  );
}
