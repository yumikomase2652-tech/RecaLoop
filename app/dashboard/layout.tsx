import{redirect}from"next/navigation";import{createClient}from"@/lib/supabase/server";
export default async function Layout({children}:{children:React.ReactNode}){if(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY){const s=await createClient(),{data:{user}}=await s.auth.getUser();if(!user)redirect("/login")}return children}
