import Link from "next/link";
import { NAV_LINKS, PLAY_STORE_URL } from "@/lib/data";

export default function Footer() {
  return (
    <footer className="border-t border-border bg-brand-950 text-brand-100">
      <div className="mx-auto grid max-w-6xl gap-10 px-5 py-14 sm:px-8 md:grid-cols-3">
        <div>
          <span className="font-display text-xl font-bold text-white">OnionGuard</span>
          <p className="mt-3 max-w-xs text-sm leading-relaxed text-brand-200">
            AI-powered onion disease detection for farmers in Ghana — built as an
            academic project at the University of Ghana.
          </p>
        </div>

        <div>
          <h3 className="text-sm font-semibold uppercase tracking-wide text-brand-400">
            Navigate
          </h3>
          <ul className="mt-4 space-y-2">
            {NAV_LINKS.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  className="relative inline-block text-sm text-brand-100 transition-transform duration-200 hover:translate-x-1.5 hover:text-white after:absolute after:bottom-0 after:left-0 after:h-px after:w-0 after:bg-white after:transition-all after:duration-300 hover:after:w-full"
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <h3 className="text-sm font-semibold uppercase tracking-wide text-brand-400">
            Get OnionGuard
          </h3>
          <p className="mt-4 text-sm text-brand-200">
            Live now on the Google Play Store.
          </p>
          <a
            href={PLAY_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-3 inline-block rounded-full bg-brand-600 px-5 py-2.5 text-sm font-semibold text-brand-950 transition-colors hover:bg-brand-400"
          >
            Download on Play Store
          </a>
        </div>
      </div>

      <div className="border-t border-white/10 px-5 py-6 text-center text-xs text-brand-300 sm:px-8">
        © {new Date().getFullYear()} OnionGuard · Nkabom Honours Team, University of Ghana
      </div>
    </footer>
  );
}
