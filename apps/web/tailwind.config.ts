import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{js,ts,jsx,tsx}", "./components/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#172126",
        cloud: "#f6f7f4",
        harbor: "#167c80",
        berry: "#7b3f61",
        saffron: "#d9902f"
      },
      boxShadow: {
        soft: "0 18px 50px rgba(23, 33, 38, 0.08)"
      }
    }
  },
  plugins: []
};

export default config;
