import type { ButtonHTMLAttributes, ReactNode } from "react";

export type UiButtonVariant = "primary" | "secondary" | "tertiary" | "destructive" | "text";
export type UiButtonSize = "regular" | "compact" | "full";

type UiButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: UiButtonVariant;
  size?: UiButtonSize;
  loading?: boolean;
  icon?: ReactNode;
};

export function UiButton({
  variant = "primary",
  size = "regular",
  loading = false,
  icon,
  children,
  className = "",
  disabled,
  ...props
}: UiButtonProps) {
  return (
    <button
      className={`lab-button lab-button-${variant} lab-button-${size} ${className}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? <span className="lab-spinner" aria-hidden /> : icon}
      <span>{children}</span>
    </button>
  );
}

