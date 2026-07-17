import { Coffee, BookOpen } from "lucide-react";
import { CafePreview } from "./cafe-preview";

type ShopCardProps = {
  nickname: string;
  handle: string;
  grade: string;
  minutes: string;
  questions: string;
  onClick?: () => void;
};

export function ShopCard({ nickname, handle, grade, minutes, questions, onClick }: ShopCardProps) {
  return (
    <button className="lab-shop-card" onClick={onClick}>
      <span className="lab-shop-profile">
        <i className="lab-shop-avatar" />
        <span>
          <b>{nickname}</b>
          <small>{handle}　|　{grade}</small>
        </span>
      </span>
      <span className="lab-shop-divider" />
      <span className="lab-shop-records">
        <span><Coffee size={18} /> 今日 {minutes}</span>
        <span><BookOpen size={18} /> 今日 {questions}</span>
      </span>
      <span className="lab-shop-divider" />
      <CafePreview />
    </button>
  );
}

