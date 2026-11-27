"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { signOutAction } from "@/app/auth/actions";

type AppTopbarProps = {
  subtitle: string;
  activePath: "/workspace" | "/inspections" | "/operations" | "/notifications" | "/admin/accounts";
  canManageIdentity?: boolean;
};

export function AppTopbar({ subtitle, activePath, canManageIdentity = false }: AppTopbarProps) {
  const [online, setOnline] = useState(true);

  useEffect(() => {
    const update = () => setOnline(typeof navigator === "undefined" ? true : navigator.onLine);
    update();
    window.addEventListener("online", update);
    window.addEventListener("offline", update);
    return () => {
      window.removeEventListener("online", update);
      window.removeEventListener("offline", update);
    };
  }, []);

  const navItems: Array<{ href: AppTopbarProps["activePath"]; label: string; show?: boolean }> = [
    { href: "/workspace", label: "Workspace" },
    { href: "/inspections", label: "Inspeksi" },
    { href: "/operations", label: "Dokumen & Laporan" },
    { href: "/notifications", label: "Notifikasi" },
    { href: "/admin/accounts", label: "Admin RBAC", show: canManageIdentity }
  ];

  return (
    <header className="topbar topbar-wrap">
      <Link className="brand" href="/" aria-label="Dit. SD Inspection home">
        <span className="brand-mark">SD</span>
        <span>
          <strong>Dit. SD Inspection</strong>
          <small>{subtitle}</small>
        </span>
      </Link>

      <nav className="admin-inline" aria-label="Navigasi operasional">
        <span
          className={`status-badge ${online ? "status-badge-approved" : "status-badge-pending"}`}
          title={online ? "Terhubung ke server" : "Mode offline — perubahan disimpan ke antrean lokal"}
        >
          {online ? "ONLINE" : "OFFLINE"}
        </span>
        {navItems
          .filter((item) => item.show !== false)
          .map((item) => (
            <Link
              key={item.href}
              className={`auth-link nav-pill ${activePath === item.href ? "nav-pill-active" : ""}`}
              href={item.href}
            >
              {item.label}
            </Link>
          ))}
        <Link className="auth-link nav-pill" href="/auth/pending">
          Akun
        </Link>
        <form action={signOutAction}>
          <button className="auth-button auth-button-secondary admin-btn-sm" type="submit">
            Keluar
          </button>
        </form>
      </nav>
    </header>
  );
}
