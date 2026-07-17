import type { ReactNode } from "react";

type UiEmptyStateProps = {
  icon?: ReactNode;
  title: string;
  body?: string;
};

export function UiEmptyState({ icon, title, body }: UiEmptyStateProps) {
  return (
    <div className="lab-empty-state">
      {icon}
      <b>{title}</b>
      {body && <p>{body}</p>}
    </div>
  );
}

