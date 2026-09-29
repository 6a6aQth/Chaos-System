import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      // Baseline only for the template shell -- a DVFP prompt can and
      // should push well past these defaults (custom palette, type scale,
      // motion). This isn't a creative constraint.
      colors: {
        ink: "#0a0a0a",
        paper: "#fafaf9",
      },
    },
  },
  plugins: [],
};

export default config;
