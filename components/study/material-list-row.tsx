import { ChevronRight, Ellipsis } from "lucide-react";
import { MaterialCover } from "./material-cover";

type MaterialListRowProps = {
  title: string;
  count: string;
  progress: string;
  due: string;
  imageUrl?: string;
  folder?: boolean;
};

export function MaterialListRow({ title, count, progress, due, imageUrl, folder = false }: MaterialListRowProps) {
  return (
    <div className="lab-material-list-row">
      <MaterialCover title={title} imageUrl={imageUrl} folder={folder} />
      <span>
        <b>{title}</b>
        <small>{count} ・ {progress} ・ {due}</small>
      </span>
      <button aria-label={`${title}の操作`}>
        <Ellipsis size={17} />
      </button>
      <ChevronRight size={18} className="lab-chevron" />
    </div>
  );
}

