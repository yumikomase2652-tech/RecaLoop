"use client";

import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, Eye, EyeOff, Sparkles } from "lucide-react";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/client";

function authMessage(message: string) {
  const text = message.toLowerCase();
  if (text.includes("invalid login credentials")) return "メールアドレスまたはパスワードが正しくありません。";
  if (text.includes("email not confirmed")) return "メールアドレスの確認が完了していません。確認メールをご確認ください。";
  if (text.includes("too many requests") || text.includes("rate limit")) return "ログイン試行回数が多すぎます。しばらくしてから再度お試しください。";
  if (text.includes("network") || text.includes("fetch failed")) return "通信に失敗しました。インターネット接続をご確認ください。";
  return message || "認証に失敗しました。";
}

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [signup, setSignup] = useState(false);
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [capsLock, setCapsLock] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (busy) return;
    if (!hasSupabaseEnv) {
      setMessage("Supabase環境変数が設定されていません。");
      return;
    }
    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail) {
      setMessage("メールアドレスを入力してください。");
      return;
    }
    setBusy(true);
    setMessage("");
    const s = createClient();
    const result = signup
      ? await s.auth.signUp({
          email: normalizedEmail,
          password,
          options: {
            data: { display_name: normalizedEmail.split("@")[0] },
            emailRedirectTo: `${location.origin}/auth/callback?next=/dashboard`,
          },
        })
      : await s.auth.signInWithPassword({ email: normalizedEmail, password });
    setBusy(false);
    if (result.error) {
      console.error("Supabase auth failed", result.error);
      setMessage(authMessage(result.error.message));
      return;
    }
    if (signup) {
      setEmail(normalizedEmail);
      setMessage("確認メールを送信しました。メール内のリンクから登録を完了してください。");
      return;
    }
    router.push("/dashboard");
  }

  async function reset() {
    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail) {
      setMessage("先にメールアドレスを入力してください。");
      return;
    }
    if (!hasSupabaseEnv) {
      setMessage("Supabase環境変数が設定されていません。");
      return;
    }
    const { error } = await createClient().auth.resetPasswordForEmail(normalizedEmail, {
      redirectTo: `${location.origin}/auth/callback?next=/auth/update-password`,
    });
    if (error) console.error("Supabase password reset failed", error);
    setMessage(error ? authMessage(error.message) : "パスワード再設定メールを送信しました。");
  }

  return (
    <main className="auth-page">
      <div className="auth-panel">
        <Link href="/" className="brand">
          <Sparkles size={21} />
          RecaLoop
        </Link>
        <div className="mt-10">
          <p className="eyebrow">PERSONAL LEARNING</p>
          <h1 className="text-3xl font-black mt-2">{signup ? "学習を始める" : "おかえりなさい"}</h1>
          <p className="text-sm text-[#788794] mt-2">デッキを作り、今日の復習へ。</p>
        </div>
        <form onSubmit={submit} className="space-y-3 mt-8">
          <input
            required
            type="email"
            autoComplete="email"
            inputMode="email"
            className="field"
            placeholder="メールアドレス"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <div className="password-field">
            <input
              required
              minLength={6}
              type={showPassword ? "text" : "password"}
              autoComplete={signup ? "new-password" : "current-password"}
              className="field"
              placeholder="パスワード"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onKeyUp={(e) => setCapsLock(e.getModifierState("CapsLock"))}
              onKeyDown={(e) => setCapsLock(e.getModifierState("CapsLock"))}
            />
            <button type="button" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? "パスワードを隠す" : "パスワードを表示"}>
              {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
            </button>
          </div>
          {capsLock && <p className="field-help">Caps Lockが有効です。大文字・小文字をご確認ください。</p>}
          {password !== password.trim() && <p className="field-help">パスワードの前後に空白が含まれています。意図した入力か確認してください。</p>}
          <button disabled={busy} className="primary-button w-full justify-center">
            {busy ? "処理中..." : signup ? "アカウントを作成" : "ログイン"}
            <ArrowRight size={17} />
          </button>
        </form>
        {message && <p className="notice mt-4">{message}</p>}
        <div className="flex justify-between mt-5 text-sm">
          <button onClick={() => { setSignup(!signup); setMessage(""); }} className="font-bold text-[#337fa7]">
            {signup ? "ログインへ戻る" : "新規登録"}
          </button>
          {!signup && <button onClick={reset} className="text-[#788794]">パスワードを忘れた</button>}
        </div>
      </div>
    </main>
  );
}
