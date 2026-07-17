import type { InputHTMLAttributes } from "react";
import { Search } from "lucide-react";

type UiSearchFieldProps = InputHTMLAttributes<HTMLInputElement>;

export function UiSearchField({ className = "", ...props }: UiSearchFieldProps) {
  return (
    <label className={`lab-search ${className}`}>
      <Search size={18} />
      <input {...props} type="search" />
    </label>
  );
}

