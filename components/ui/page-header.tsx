import type { ReactNode } from "react";
import { ChevronLeft } from "lucide-react";
import { UiIconButton } from "./icon-button";

type UiPageHeaderProps = {
  title: string;
  subtitle?: string;
  large?: boolean;
  back?: () => void;
  action?: ReactNode;
};

export function UiPageHeader({ title, subtitle, large = false, back, action }: UiPageHeaderProps) {
  return (
    <header className={`lab-page-header ${large ? "large" : ""}`}>
      <div className="lab-page-header-top">
        {back ? <UiIconButton label="戻る" icon={<ChevronLeft size={22} />} onClick={back} /> : <span />}
        {!large && <h1>{title}</h1>}
        <span className="lab-page-action">{action}</span>
      </div>
      {large && <h1>{title}</h1>}
      {subtitle && <p>{subtitle}</p>}
    </header>
  );
}

