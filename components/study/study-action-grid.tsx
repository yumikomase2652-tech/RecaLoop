import { BookOpen, CalendarDays, RotateCcw, Timer } from "lucide-react";
import { StudyActionCard } from "./study-action-card";

type StudyActionGridProps = {
  scheduleCount: number;
  reviewCount: number;
  lastMaterial?: { title: string; progress: number } | null;
  onSchedule?: () => void;
  onReview?: () => void;
  onMaterial?: () => void;
  onTimer?: () => void;
};

export function StudyActionGrid({ scheduleCount, reviewCount, lastMaterial, onSchedule, onReview, onMaterial, onTimer }: StudyActionGridProps) {
  return (
    <div className="lab-study-action-grid">
      <StudyActionCard icon={<CalendarDays />} label="予定に取り組む" value={scheduleCount} tone="schedule" onClick={onSchedule} />
      <StudyActionCard icon={<RotateCcw />} label="復習する" value={reviewCount} tone="review" onClick={onReview} />
      <StudyActionCard
        icon={<BookOpen />}
        label={lastMaterial?.title || "教材がありません"}
        value={lastMaterial ? `${lastMaterial.progress}%` : undefined}
        empty={!lastMaterial}
        tone="material"
        onClick={onMaterial}
      />
      <StudyActionCard icon={<Timer />} label="タイマー" tone="timer" onClick={onTimer} />
    </div>
  );
}

