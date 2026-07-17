import { notFound } from "next/navigation";
import { UiLab } from "@/components/development/ui-lab";

export default function UiLabPage() {
  if (process.env.NODE_ENV === "production") {
    notFound();
  }
  return <UiLab />;
}

