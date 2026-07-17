type UiSegmentedControlProps<T extends string> = {
  value: T;
  options: readonly T[];
  labels?: Partial<Record<T, string>>;
  onChange: (value: T) => void;
};

export function UiSegmentedControl<T extends string>({ value, options, labels, onChange }: UiSegmentedControlProps<T>) {
  return (
    <div className="lab-segmented" role="tablist">
      {options.map((option) => (
        <button key={option} className={value === option ? "active" : ""} onClick={() => onChange(option)} role="tab" aria-selected={value === option}>
          {labels?.[option] || option}
        </button>
      ))}
    </div>
  );
}

