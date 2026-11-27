import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  agentRules: false,
  poweredByHeader: false,
  reactStrictMode: true,
  async headers() {
    const securityHeaders = [
      { key: "X-Content-Type-Options", value: "nosniff" },
      { key: "X-Frame-Options", value: "DENY" },
      { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
      { key: "Permissions-Policy", value: "camera=(self), microphone=(), geolocation=()" }
    ];

    if (process.env.VERCEL_ENV === "production") {
      securityHeaders.push({
        key: "Strict-Transport-Security",
        value: "max-age=31536000"
      });
    }

    return [
      {
        source: "/:path*",
        headers: securityHeaders
      },
      {
        source: "/auth/callback",
        headers: [{ key: "Referrer-Policy", value: "no-referrer" }]
      }
    ];
  }
};

export default nextConfig;
