import type { HTMLAttributes, ReactNode } from "react";

type UiCardProps = HTMLAttributes<HTMLElement> & {
  as?: "section" | "article" | "div";
  interactive?: boolean;
  children: ReactNode;
};

export function UiCard({ as = "article", interactive = false, children, className = "", ...props }: UiCardProps) {
  const Component = as;
  return (
    <Component className={`lab-card ${interactive ? "interactive" : ""} ${className}`} {...props}>
      {children}
    </Component>
  );
}

