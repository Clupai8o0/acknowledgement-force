import type { Metadata } from "next";
import "./landing.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://acknowledgement-force.vercel.app"),
  title: "Acknowledgement Force — A daily contract for your Mac",
  description:
    "Acknowledgement Force is a free, open-source macOS app that locks your Mac behind a daily contract. Read it, acknowledge it, commit to your single highest-leverage action — every day.",
  openGraph: {
    title: "Acknowledgement Force",
    description:
      "A daily contract you must read and commit to before your Mac is yours. Free & open source.",
    type: "website",
    images: ["/assets/favicon-192.png"],
  },
  icons: {
    icon: [{ url: "/assets/favicon-192.png", type: "image/png", sizes: "32x32" }],
    apple: "/assets/apple-touch-icon.png",
  },
};

const themeInit = `(function(){try{var k='af-landing-theme';var s=localStorage.getItem(k);var d=window.matchMedia('(prefers-color-scheme: dark)').matches;document.documentElement.setAttribute('data-theme',s||(d?'dark':'light'));}catch(e){}})();`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" data-theme="light">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,400;0,9..144,500;0,9..144,600;1,9..144,400&family=Inter:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
        <script dangerouslySetInnerHTML={{ __html: themeInit }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
