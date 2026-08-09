// The brand logo, theme-aware: near-black artwork on light backgrounds,
// light artwork (icon-dark.png) on dark. The CSS toggle lives in landing.css.
export default function BrandMark({ className }: { className?: string }) {
  const cls = (variant: string) =>
    [variant, className].filter(Boolean).join(" ");
  return (
    <>
      <img src="/assets/illustrations/icon.png" alt="" className={cls("logo-light")} />
      <img src="/assets/illustrations/icon-dark.png" alt="" className={cls("logo-dark")} />
    </>
  );
}
