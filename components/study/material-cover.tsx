import { BookOpen, Folder } from "lucide-react";

type MaterialCoverProps = {
  title: string;
  imageUrl?: string;
  folder?: boolean;
};

export function MaterialCover({ title, imageUrl, folder = false }: MaterialCoverProps) {
  return (
    <span className={`lab-material-cover ${folder ? "folder" : ""}`}>
      {imageUrl ? <img src={imageUrl} alt="" /> : folder ? <Folder aria-hidden /> : <BookOpen aria-hidden />}
      <em>{title.slice(0, 1)}</em>
    </span>
  );
}

