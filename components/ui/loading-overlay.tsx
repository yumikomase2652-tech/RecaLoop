import { CoffeeLoader } from "@/components/coffee-loader";

export function UiLoadingOverlay({ label = "準備しています" }: { label?: string }) {
  return (
    <div className="lab-loading-overlay" aria-label={label}>
      <CoffeeLoader label={label} />
    </div>
  );
}

