import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#f0edfe",
          100: "#d9d1fd",
          200: "#b3a3fb",
          300: "#8d75f9",
          400: "#7a63f8",
          500: "#6C5CE7",
          600: "#5a4cc4",
          700: "#483ca0",
          800: "#362d7d",
          900: "#241d59",
        },
        secondary: {
          500: "#FFA502",
        },
        accent: {
          500: "#00D2D3",
        },
      },
      fontFamily: {
        sans: ["Poppins", "sans-serif"],
      },
    },
  },
  plugins: [],
};
export default config;
