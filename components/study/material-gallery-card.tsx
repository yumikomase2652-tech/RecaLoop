import { Ellipsis } from "lucide-react";
import { MaterialCover } from "./material-cover";

type MaterialGalleryCardProps = {
  title: string;
  imageUrl?: string;
  progress?: number;
  folder?: boolean;
};

export function MaterialGalleryCard({ title, imageUrl, progress, folder = false }: MaterialGalleryCardProps) {
  return (
    <article className="lab-material-gallery-card">
      <button className="lab-material-more" aria-label={`${title}の操作`}>
        <Ellipsis size={16} />
      </button>
      <MaterialCover title={title} imageUrl={imageUrl} folder={folder} />
      <b>{title}</b>
      {progress !== undefined && <small>{progress}%</small>}
    </article>
  );
}

