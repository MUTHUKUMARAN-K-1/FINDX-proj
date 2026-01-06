import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/contexts/ThemeContext";
import { LocationProvider } from "@/contexts/LocationContext";
import { AuthProvider } from "@/hooks/useAuth";

const inter = Inter({ 
  subsets: ["latin"],
  display: 'swap',
  variable: '--font-inter',
});

export const metadata: Metadata = {
  title: "FINDX - Lost in Seconds, Found in Minutes",
  description: "India's unified AI-powered recovery platform for lost items, pets, and persons. Report in 10 seconds, recover 3x faster.",
  keywords: ["lost and found", "lost items", "lost pets", "missing persons", "India", "recovery platform"],
  authors: [{ name: "FINDX Team" }],
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "FINDX",
  },
  openGraph: {
    title: "FINDX - Lost in Seconds, Found in Minutes",
    description: "Report lost items in 10 seconds. Recover 3x faster with AI-powered matching.",
    type: "website",
    locale: "en_IN",
    siteName: "FINDX",
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#0a0a0a" },
  ],
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="light" suppressHydrationWarning>
      <head>
        <link rel="apple-touch-icon" sizes="180x180" href="/icons/icon-192x192.png" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="mobile-web-app-capable" content="yes" />
      </head>
      <body className={`${inter.variable} font-sans antialiased`}>
        <AuthProvider>
          <ThemeProvider>
            <LocationProvider>
              <main className="min-h-screen pb-20 md:pb-0">
                {children}
              </main>
            </LocationProvider>
          </ThemeProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
