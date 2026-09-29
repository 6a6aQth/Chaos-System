/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    // Loosened for demo/DVFP use. Tighten to real domains once a project
    // has real image sources (Vercel Blob, a CMS, etc).
    remotePatterns: [{ protocol: "https", hostname: "**" }],
  },
};

export default nextConfig;
