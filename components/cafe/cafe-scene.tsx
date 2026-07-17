export function CafeScene({ label = "Cafe preview" }: { label?: string }) {
  return (
    <div className="lab-cafe-scene" aria-label={label}>
      <span className="window" />
      <span className="lamp" />
      <span className="plant" />
      <span className="table" />
      <span className="cup" />
    </div>
  );
}

