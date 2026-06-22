import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "RecaLoop", description: "忘れる前に、もう一度。",manifest:"/manifest.webmanifest",icons:{icon:"/icon.svg",apple:"/icon.svg"},appleWebApp:{capable:true,title:"RecaLoop",statusBarStyle:"default"} };
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="ja"><body>{children}</body></html>}
