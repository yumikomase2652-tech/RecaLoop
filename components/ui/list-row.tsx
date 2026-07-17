import type { ReactNode } from "react";
import { ChevronRight } from "lucide-react";

type UiListRowProps = {
  icon?: ReactNode;
  title: ReactNode;
  subtitle?: ReactNode;
  value?: ReactNode;
  chevron?: boolean;
  selected?: boolean;
  onClick?: () => void;
};

export function UiListRow({ icon, title, subtitle, value, chevron = true, selected = false, onClick }: UiListRowProps) {
  const content = (
    <>
      {icon && <span className="lab-list-icon">{icon}</span>}
      <span className="lab-list-main">
        <b>{title}</b>
        {subtitle && <small>{subtitle}</small>}
      </span>
      {value && <span className="lab-list-value">{value}</span>}
      {chevron && <ChevronRight size={18} className="lab-chevron" />}
    </>
  );

  if (onClick) {
    return (
      <button className={`lab-list-row ${selected ? "selected" : ""}`} onClick={onClick}>
        {content}
      </button>
    );
  }
  return <div className={`lab-list-row ${selected ? "selected" : ""}`}>{content}</div>;
}

