import type { ReactNode } from "react";

type UiBottomSheetProps = {
  title: string;
  open: boolean;
  onClose: () => void;
  children: ReactNode;
};

export function UiBottomSheet({ title, open, onClose, children }: UiBottomSheetProps) {
  if (!open) return null;
  return (
    <div className="lab-sheet-backdrop" role="presentation" onClick={onClose}>
      <section className="lab-bottom-sheet" role="dialog" aria-modal="true" aria-label={title} onClick={(event) => event.stopPropagation()}>
        <span className="lab-sheet-handle" />
        <h2>{title}</h2>
        {children}
      </section>
    </div>
  );
}

