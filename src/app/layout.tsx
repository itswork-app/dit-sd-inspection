import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Dit. SD Inspection",
    template: "%s | Dit. SD Inspection"
  },
  description: "Digital inspection workspace for primary-school equipment.",
  applicationName: "Dit. SD Inspection"
};

export const viewport: Viewport = {
  themeColor: "#0b1220",
  width: "device-width",
  initialScale: 1
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
