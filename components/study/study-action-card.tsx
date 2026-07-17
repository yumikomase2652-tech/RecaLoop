import type { ReactNode } from "react";

export type StudyActionCardTone = "schedule" | "review" | "material" | "timer";

type StudyActionCardProps = {
  icon: ReactNode;
  label: string;
  value?: string | number;
  empty?: boolean;
  tone?: StudyActionCardTone;
  onClick?: () => void;
};

export function StudyActionCard({ icon, label, value, empty = false, tone = "schedule", onClick }: StudyActionCardProps) {
  return (
    <button className={`lab-study-action ${tone} ${empty ? "empty" : ""}`} onClick={onClick} title={label}>
      <span className="lab-study-action-icon">{icon}</span>
      {value !== undefined && <b className="lab-study-action-value">{value}</b>}
      <span className="lab-study-action-label">{label}</span>
    </button>
  );
}
