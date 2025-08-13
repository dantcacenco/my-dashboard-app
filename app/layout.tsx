import { Inter } from "next/font/google";
import "./globals.css";

export const metadata = {
  title: "Service Pro - HVAC Management",
  description: "Field Service Management for HVAC Businesses",
};

const inter = Inter({ subsets: ["latin"] });

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="bg-gray-50 text-gray-900">
        {children}
      </body>
    </html>
  );
}
