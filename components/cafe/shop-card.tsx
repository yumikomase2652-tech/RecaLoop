import { ChevronRight, Coffee, BookOpen } from "lucide-react";
import { CafePreview } from "./cafe-preview";

type ShopCardProps = {
  nickname: string;
  handle: string;
  grade: string;
  minutes: string;
  questions: string;
  avatar?: string;
  avatarColor?: string;
  targetSchool?: string;
  background?: { type: "color" | "image"; value: string };
  onAccountClick?: () => void;
  onCafeClick?: () => void;
};

export function ShopCard({ nickname, handle, grade, minutes, questions, avatar, avatarColor, targetSchool, background, onAccountClick, onCafeClick }: ShopCardProps) {
  const style = background?.value
    ? background.type === "image"
      ? { backgroundImage: `linear-gradient(rgba(255,255,255,.72), rgba(255,255,255,.72)), url(${background.value})` }
      : { background: background.value }
    : undefined;
  return (
    <article className="lab-shop-card" style={style}>
      <button className="lab-shop-profile" onClick={onAccountClick} type="button">
        <i className="lab-shop-avatar" style={!avatar && avatarColor ? { background: avatarColor } : undefined}>{avatar ? <img src={avatar} alt="" /> : null}</i>
        <span>
          <b>{nickname}</b>
          <small>{handle}　|　{grade}{targetSchool ? `　|　${targetSchool}` : ""}</small>
        </span>
        <ChevronRight size={18} />
      </button>
      <span className="lab-shop-divider" />
      <span className="lab-shop-records">
        <span><Coffee size={18} /> 今日 {minutes}</span>
        <span><BookOpen size={18} /> 今日 {questions}</span>
      </span>
      <span className="lab-shop-divider" />
      <button className="lab-shop-cafe-button" onClick={onCafeClick} type="button" aria-label="カフェを見る">
        <CafePreview />
      </button>
    </article>
  );
}
