"use client";

export function CoffeeLoader({ label = "データを準備しています", compact = false }: { label?: string; compact?: boolean }) {
  return <div className={compact ? "coffee-loader compact" : "coffee-loader"} role="status" aria-label={label}>
    <svg viewBox="0 0 120 96" aria-hidden="true">
      <defs>
        <clipPath id="coffee-loader-cup">
          <path d="M19 25h70v23c0 22-16 39-37 39h-3c-18 0-30-17-30-39V25Z" />
        </clipPath>
      </defs>
      <g className="coffee-steam">
        <path d="M42 7c-5 6 5 8 0 14" />
        <path d="M59 4c-6 7 6 10 0 17" />
        <path d="M75 7c-5 6 5 8 0 14" />
      </g>
      <path className="coffee-fill-bg" d="M19 25h70v23c0 22-16 39-37 39h-3c-18 0-30-17-30-39V25Z" />
      <g clipPath="url(#coffee-loader-cup)">
        <path className="coffee-liquid" d="M4 55c16-10 25 7 41 0s26-20 43-5 30-1 38-5v51H4Z" />
      </g>
      <path className="coffee-cup-line" d="M19 25h70v23c0 22-16 39-37 39h-3c-18 0-30-17-30-39V25Z" />
      <path className="coffee-cup-line" d="M89 36h10c11 0 18 8 18 18s-8 18-20 18H86" />
      <path className="coffee-cup-line" d="M35 91h42" />
    </svg>
    <span>{label}</span>
  </div>;
}
