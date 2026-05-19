import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AI Analytics Chatbot",
  description: "Chat-driven e-commerce analytics dashboard"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
