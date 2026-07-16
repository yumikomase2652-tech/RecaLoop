"use client";

import type { SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function LineSvg({ size = 24, children, ...props }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...props}
    >
      {children}
    </svg>
  );
}

export function HomeTabIcon(props: IconProps) {
  return (
    <LineSvg {...props}>
      <path d="M3.5 11.2 12 4l8.5 7.2" />
      <path d="M5.7 10.4v8.2a1.4 1.4 0 0 0 1.4 1.4h9.8a1.4 1.4 0 0 0 1.4-1.4v-8.2" />
      <path d="M9.6 20v-5.2h4.8V20" />
    </LineSvg>
  );
}

export function StudyTabIcon(props: IconProps) {
  return (
    <LineSvg {...props}>
      <path d="M4.5 19.2 14.9 8.8" />
      <path d="m13.2 7.1 3.7 3.7" />
      <path d="m16.5 3.8 3.7 3.7-3.3 3.3-3.7-3.7z" />
      <path d="m4 20 3.6-1" />
    </LineSvg>
  );
}

export function CalendarTabIcon(props: IconProps) {
  return (
    <LineSvg {...props}>
      <rect x="3.8" y="5.2" width="16.4" height="15" rx="3" />
      <path d="M8 3.8v3" />
      <path d="M16 3.8v3" />
      <path d="M3.8 9.3h16.4" />
      <path d="M8 13h.01" />
      <path d="M12 13h.01" />
      <path d="M16 13h.01" />
      <path d="M8 16.6h.01" />
      <path d="M12 16.6h.01" />
    </LineSvg>
  );
}

export function SummaryTabIcon(props: IconProps) {
  return (
    <LineSvg {...props}>
      <path d="M4.5 20h15" />
      <path d="M7 16v-5" />
      <path d="M12 16V7" />
      <path d="M17 16v-9" />
      <path d="M6.2 7.8 10 4.5l3.3 2.7L18 3.8" />
    </LineSvg>
  );
}

export function CafeTabIcon(props: IconProps) {
  return (
    <LineSvg {...props}>
      <path d="M5 9h11v4.8A5.2 5.2 0 0 1 10.8 19h-.6A5.2 5.2 0 0 1 5 13.8z" />
      <path d="M16 10.5h1.5a3 3 0 0 1 0 6H16" />
      <path d="M4.5 21h13" />
      <path d="M7 6c.8-.7.8-1.5 0-2.2" />
      <path d="M11 6c.8-.7.8-1.5 0-2.2" />
    </LineSvg>
  );
}
