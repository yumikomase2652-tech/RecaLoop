import type { ReactNode } from "react";

type UiSectionProps = {
  title?: string;
  footer?: ReactNode;
  action?: ReactNode;
  children: ReactNode;
};

export function UiSection({ title, footer, action, children }: UiSectionProps) {
  return (
    <section className="lab-section">
      {(title || action) && (
        <div className="lab-section-header">
          {title && <h2>{title}</h2>}
          {action}
        </div>
      )}
      {children}
      {footer && <p className="lab-section-footer">{footer}</p>}
    </section>
  );
}

