"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { signOutAction } from "@/app/auth/actions";
import {
  getAllowedNavPaths,
  ROLE_META,
  type AppNavPath,
  type CanonicalRoleCode
} from "@/lib/auth/roles";

type AppTopbarProps = {
  subtitle: string;
  activePath: AppNavPath;
  canManageIdentity?: boolean;
  activeRoles?: CanonicalRoleCode[];
};

const ALL_NAV_ITEMS: Array<{ href: AppNavPath; label: string }> = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/workspace", label: "Workspace" },
  { href: "/inspections", label: "Inspeksi" },
  { href: "/operations", label: "Dokumen & Laporan" },
  { href: "/notifications", label: "Notifikasi" },
  { href: "/admin/accounts", label: "Kelola Akun" }
];

export function AppTopbar({
  subtitle,
  activePath,
  canManageIdentity = false,
  activeRoles
}: AppTopbarProps) {
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

  const allowedSet = activeRoles
    ? new Set<AppNavPath>(getAllowedNavPaths(activeRoles))
    : null;

  const navItems = ALL_NAV_ITEMS.filter((item) => {
    if (allowedSet) {
      if (item.href === "/admin/accounts" && !canManageIdentity && !allowedSet.has(item.href)) {
        return false;
      }
      return allowedSet.has(item.href);
    }
    if (item.href === "/admin/accounts") return canManageIdentity;
    return true;
  });

  const roleBadgeLabel =
    activeRoles && activeRoles.length > 0
      ? activeRoles.length === 1
        ? ROLE_META[activeRoles[0]].shortLabel
        : `Multi-Peran (${activeRoles.length})`
      : null;

  return (
    <header className="topbar topbar-wrap">
      <Link className="brand" href="/dashboard" aria-label="Dit. SD Inspection dashboard">
        <span className="brand-mark">SD</span>
        <span>
          <strong>Dit. SD Inspection</strong>
          <small>{subtitle}</small>
        </span>
      </Link>

      <nav className="admin-inline" aria-label="Navigasi operasional">
        {roleBadgeLabel ? (
          <span className="status-badge status-badge-approved">{roleBadgeLabel}</span>
        ) : null}
        <span
          className={`status-badge ${online ? "status-badge-approved" : "status-badge-pending"}`}
          title={online ? "Terhubung ke server" : "Mode offline — perubahan disimpan ke antrean lokal"}
        >
          {online ? "ONLINE" : "OFFLINE"}
        </span>
        {navItems.map((item) => (
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
