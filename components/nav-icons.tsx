"use client";

import type { SVGProps } from "react";

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function Svg({ size = 22, children, ...props }: IconProps) {
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden="true" {...props}>{children}</svg>;
}

export function HomeTabIcon(props: IconProps) {
  return <Svg {...props}><path d="M4.5 11.3 12 4.9l7.5 6.4v7.2a1.6 1.6 0 0 1-1.6 1.6h-3.4v-5.2h-5v5.2H6.1a1.6 1.6 0 0 1-1.6-1.6z" fill="currentColor" opacity=".18"/><path d="M4.5 11.3 12 4.9l7.5 6.4v7.2a1.6 1.6 0 0 1-1.6 1.6h-3.4v-5.2h-5v5.2H6.1a1.6 1.6 0 0 1-1.6-1.6z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round"/></Svg>;
}

export function StudyTabIcon(props: IconProps) {
  return <Svg {...props}><path d="m7 17 9.4-9.4 2.1 2.1L9.1 19.1 5.6 20z" fill="currentColor" opacity=".2"/><path d="m7 17 9.4-9.4 2.1 2.1L9.1 19.1 5.6 20zM14.9 9.1l2.1 2.1" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/></Svg>;
}

export function CalendarTabIcon(props: IconProps) {
  return <Svg {...props}><rect x="4.2" y="5.4" width="15.6" height="14.1" rx="3" fill="currentColor" opacity=".16"/><path d="M8 3.9v3M16 3.9v3M5 9.3h14M7.8 12.7h.1M12 12.7h.1M16.2 12.7h.1M7.8 16h.1M12 16h.1M16.2 16h.1" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/><rect x="4.2" y="5.4" width="15.6" height="14.1" rx="3" stroke="currentColor" strokeWidth="1.8"/></Svg>;
}

export function SummaryTabIcon(props: IconProps) {
  return <Svg {...props}><path d="M5.5 19V12.7M12 19V8.5M18.5 19V5.5" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"/><path d="M4.3 20h15.4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"/><path d="M4.6 13.2h1.8M11.1 9h1.8M17.6 6h1.8" stroke="currentColor" strokeWidth="3.8" strokeLinecap="round" opacity=".18"/></Svg>;
}

export function CafeTabIcon(props: IconProps) {
  return <Svg {...props}><path d="M5.2 9.1h11.2v3.4c0 3.7-2.9 6.7-6.2 6.7H10c-2.9 0-4.8-2.7-4.8-6.7z" fill="currentColor" opacity=".17"/><path d="M5.2 9.1h11.2v3.4c0 3.7-2.9 6.7-6.2 6.7H10c-2.9 0-4.8-2.7-4.8-6.7zM16.4 11h1.3c1.9 0 3.1 1.3 3.1 3s-1.4 3-3.3 3h-1.6M8.2 21h6.3" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/><path d="M8.4 5.2c-.4.5-.4 1 0 1.5M12 4c-.5.7-.5 1.4 0 2.1M15.2 5.2c-.4.5-.4 1 0 1.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></Svg>;
}
