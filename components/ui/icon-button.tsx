import type { ButtonHTMLAttributes, ReactNode } from "react";

type UiIconButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  icon: ReactNode;
  label: string;
  selected?: boolean;
};

export function UiIconButton({ icon, label, selected = false, className = "", ...props }: UiIconButtonProps) {
  return (
    <button
      aria-label={label}
      aria-pressed={selected || undefined}
      className={`lab-icon-button ${selected ? "selected" : ""} ${className}`}
      {...props}
    >
      {icon}
    </button>
  );
}

