/** Original geometric mark: two overlapping answer circles and a spark. */
export function Logo({ size = 32 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden="true" focusable="false">
      <circle cx="36" cy="56" r="34" fill="var(--mm-option-a)" />
      <circle cx="64" cy="44" r="34" fill="var(--mm-option-b)" fillOpacity="0.88" />
      <circle cx="86" cy="14" r="10" fill="var(--mm-accent)" />
    </svg>
  );
}
