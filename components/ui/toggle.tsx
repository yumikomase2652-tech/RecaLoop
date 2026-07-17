type UiToggleProps = {
  checked: boolean;
  label: string;
  onChange: (checked: boolean) => void;
};

export function UiToggle({ checked, label, onChange }: UiToggleProps) {
  return (
    <button className={`lab-toggle ${checked ? "checked" : ""}`} role="switch" aria-checked={checked} onClick={() => onChange(!checked)}>
      <span>{label}</span>
      <i />
    </button>
  );
}

