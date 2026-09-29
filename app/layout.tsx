import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MC-DOS Template",
  description:
    "MidasCreed starter template — deploy-ready shell. Payments, Auth, and Database are added per project via the docs.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="bg-[#05070d] text-white antialiased">{children}</body>
    </html>
  );
}
