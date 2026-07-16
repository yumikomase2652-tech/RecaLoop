"use client";

import type { SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function StickerSvg({ size = 30, children, ...props }: IconProps) {
  return <svg width={size} height={size} viewBox="0 0 64 64" fill="none" aria-hidden="true" {...props}>{children}</svg>;
}

export function HomeTabIcon(props: IconProps) {
  return (
    <StickerSvg {...props}>
      <defs>
        <linearGradient id="home-tab-fill" x1="14" x2="50" y1="12" y2="54">
          <stop stopColor="#ffd26f" />
          <stop offset="1" stopColor="#e49a2d" />
        </linearGradient>
      </defs>
      <path d="M13 30.5 32 13.2l19 17.3h-5.4v19.8H18.4V30.5z" fill="white" stroke="white" strokeWidth="10" strokeLinejoin="round" />
      <path d="M13 30.5 32 13.2l19 17.3h-5.4v19.8H18.4V30.5z" fill="url(#home-tab-fill)" />
      <circle cx="32" cy="38" r="7.6" fill="#df962d" opacity=".72" />
    </StickerSvg>
  );
}

export function StudyTabIcon(props: IconProps) {
  return (
    <StickerSvg {...props}>
      <defs>
        <linearGradient id="study-tab-body" x1="24" x2="45" y1="46" y2="13">
          <stop stopColor="#ffd06f" />
          <stop offset="1" stopColor="#f5ad3f" />
        </linearGradient>
      </defs>
      <g transform="rotate(35 32 32)">
        <path d="M27 9h10c2.6 0 4.8 2.1 4.8 4.8v32.5L32 56l-9.8-9.7V13.8C22.2 11.1 24.4 9 27 9z" fill="white" stroke="white" strokeWidth="9" strokeLinejoin="round" />
        <path d="M27 9h10c2.6 0 4.8 2.1 4.8 4.8v32.5L32 56l-9.8-9.7V13.8C22.2 11.1 24.4 9 27 9z" fill="url(#study-tab-body)" />
        <path d="M22.2 40.7h19.6v5.6L32 56l-9.8-9.7z" fill="#fff1d8" />
        <path d="M27.2 50.9 32 56l4.8-5.1z" fill="#7b6b58" />
        <path d="M24.6 15.2h14.8" stroke="#f8c261" strokeWidth="3" strokeLinecap="round" opacity=".56" />
        <path d="M27.5 9h9c2.9 0 5.3 2.4 5.3 5.3v4.4H22.2v-4.4C22.2 11.4 24.6 9 27.5 9z" fill="#9d8a75" />
      </g>
    </StickerSvg>
  );
}

export function CalendarTabIcon(props: IconProps) {
  return (
    <StickerSvg {...props}>
      <defs>
        <linearGradient id="calendar-tab-page" x1="13" x2="51" y1="15" y2="54">
          <stop stopColor="#fff7e6" />
          <stop offset="1" stopColor="#f1dfc3" />
        </linearGradient>
      </defs>
      <rect x="12" y="16" width="40" height="38" rx="7" fill="white" stroke="white" strokeWidth="9" />
      <path d="M12 24c0-4.4 3.6-8 8-8h24c4.4 0 8 3.6 8 8v6H12z" fill="#a9c697" />
      <path d="M12 29h40v17c0 4.4-3.6 8-8 8H20c-4.4 0-8-3.6-8-8z" fill="url(#calendar-tab-page)" />
      <rect x="18" y="10" width="7" height="15" rx="3.5" fill="#a38d78" />
      <rect x="39" y="10" width="7" height="15" rx="3.5" fill="#a38d78" />
      {[20, 32, 44].map((x) => [36, 46].map((y) => <rect key={`${x}-${y}`} x={x - 3.4} y={y - 3.4} width="6.8" height="6.8" rx="2" fill="#d8c7ae" opacity=".78" />))}
      <rect x="38.5" y="42.6" width="7.2" height="7.2" rx="2.1" fill="#f5ad3f" />
    </StickerSvg>
  );
}

export function SummaryTabIcon(props: IconProps) {
  return (
    <StickerSvg {...props}>
      <path d="M13 52h38" stroke="white" strokeWidth="10" strokeLinecap="round" />
      <path d="M19 34v18M32 26v26M45 17v35" stroke="white" strokeWidth="15" strokeLinecap="round" />
      <path d="M13 52h38" stroke="#d3b58f" strokeWidth="5.5" strokeLinecap="round" />
      <path d="M19 34v18" stroke="#94b27e" strokeWidth="10" strokeLinecap="round" />
      <path d="M32 26v26" stroke="#f0ad3f" strokeWidth="10" strokeLinecap="round" />
      <path d="M45 17v35" stroke="#8fb1d6" strokeWidth="10" strokeLinecap="round" />
    </StickerSvg>
  );
}

export function CafeTabIcon(props: IconProps) {
  return (
    <StickerSvg {...props}>
      <defs>
        <linearGradient id="cafe-tab-cup" x1="14" x2="45" y1="23" y2="51">
          <stop stopColor="#fff4dc" />
          <stop offset="1" stopColor="#f1d8ad" />
        </linearGradient>
      </defs>
      <path d="M12.5 29h34v8.5c0 9.5-7.3 16.8-16.7 16.8h-.7c-8.4 0-16.6-6.4-16.6-16.8z" fill="white" stroke="white" strokeWidth="9" strokeLinejoin="round" />
      <path d="M44 32h5.2c5.2 0 8.8 3.9 8.8 8.5S54.2 49 49.1 49h-5.8" fill="none" stroke="white" strokeWidth="9" strokeLinecap="round" />
      <path d="M12.5 29h34v8.5c0 9.5-7.3 16.8-16.7 16.8h-.7c-8.4 0-16.6-6.4-16.6-16.8z" fill="url(#cafe-tab-cup)" />
      <path d="M44 32h5.2c5.2 0 8.8 3.9 8.8 8.5S54.2 49 49.1 49h-5.8" stroke="#f1d8ad" strokeWidth="5" strokeLinecap="round" />
      <path d="M15.5 30.5c7 4.6 19.5 4.5 28.4 0v6.3c-7.4 4.2-19.7 4.5-28.4 0z" fill="#c0935d" opacity=".72" />
      <path d="M17 57h29" stroke="white" strokeWidth="8" strokeLinecap="round" />
      <path d="M17 57h29" stroke="#c9b292" strokeWidth="4" strokeLinecap="round" />
    </StickerSvg>
  );
}
