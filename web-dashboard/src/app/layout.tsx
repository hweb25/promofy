import type { Metadata } from "next";
import "./globals.css";
import { Toaster } from "react-hot-toast";

export const metadata: Metadata = {
  title: "Promofy - Business Dashboard",
  description: "Manage your promotions and grow your business with Promofy",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {children}
        <Toaster
          position="top-right"
          toastOptions={{
            style: {
              borderRadius: "16px",
              fontFamily: "Poppins, sans-serif",
            },
          }}
        />
      </body>
    </html>
  );
}
