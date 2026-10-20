import Link from "next/link";
import { ArrowRight } from "lucide-react";
import Reveal from "@/components/Reveal";
import StatCounter from "@/components/StatCounter";
import FeatureCard from "@/components/FeatureCard";
import HeroCarousel from "@/components/HeroCarousel";
import TypingText from "@/components/TypingText";
import {
  FEATURES,
  HOME_HERO_IMAGES,
  HOME_TYPING_PHRASES,
  HOW_IT_WORKS,
  PLAY_STORE_URL,
  STATS,
} from "@/lib/data";

export default function Home() {
  const heroFeatures = FEATURES.slice(0, 4);

  return (
    <div>
      {/* Hero */}
      <HeroCarousel images={HOME_HERO_IMAGES}>
        <div className="px-5 py-10 text-center sm:px-8">
          <Reveal delay={0.08}>
            <h1 className="font-display whitespace-normal text-2xl font-extrabold leading-tight tracking-tight text-white sm:whitespace-nowrap sm:text-[clamp(0px,calc(0.5px+3.05vw),2.75rem)]">
              AI-powered onion disease detection for farmers in Ghana
            </h1>
          </Reveal>
          <Reveal delay={0.16}>
            <div className="mx-auto mt-4 flex min-h-16 max-w-xl items-start justify-center sm:min-h-14">
              <TypingText
                phrases={HOME_TYPING_PHRASES}
                className="text-base leading-relaxed text-white/85 sm:text-lg"
              />
            </div>
          </Reveal>
          <Reveal delay={0.24}>
            <div className="mt-6 flex flex-wrap items-center justify-center gap-4">
              <a
                href={PLAY_STORE_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="group inline-flex items-center gap-2 rounded-full bg-brand-600 px-6 py-3.5 text-sm font-semibold text-white shadow-lg shadow-black/20 transition-transform hover:-translate-y-0.5 hover:bg-brand-500"
              >
                Get the App
                <ArrowRight size={16} className="transition-transform group-hover:translate-x-1" />
              </a>
              <Link
                href="/about"
                className="inline-flex items-center gap-1.5 rounded-full border border-white/40 px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-white/10"
              >
                See how it works
              </Link>
            </div>
          </Reveal>
        </div>
      </HeroCarousel>

      {/* Stats */}
      <section className="border-y border-border bg-white">
        <div className="mx-auto max-w-6xl px-5 py-14 sm:px-8">
          <Reveal>
            <div className="grid grid-cols-2 gap-8 sm:grid-cols-4">
              {STATS.map((s) => (
                <StatCounter key={s.label} {...s} />
              ))}
            </div>
          </Reveal>
        </div>
      </section>

      {/* Feature highlights */}
      <section className="bg-surface">
        <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8">
          <Reveal className="mx-auto max-w-2xl text-center">
            <h2 className="font-display text-3xl font-bold text-brand-950 sm:text-4xl">
              Everything a farmer needs, in one scan
            </h2>
            <p className="mt-4 text-muted">
              From detection to treatment to voice guidance — OnionGuard covers the full
              journey from a sick crop to a saved harvest.
            </p>
          </Reveal>

          <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {heroFeatures.map((f, i) => (
              <FeatureCard key={f.title} {...f} delay={i * 0.08} />
            ))}
          </div>

          <Reveal className="mt-10 text-center">
            <Link
              href="/about"
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-brand-800 hover:text-brand-600"
            >
              See all features <ArrowRight size={15} />
            </Link>
          </Reveal>
        </div>
      </section>

      {/* How it works */}
      <section className="bg-white">
        <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8">
          <Reveal className="mx-auto max-w-2xl text-center">
            <h2 className="font-display text-3xl font-bold text-brand-950 sm:text-4xl">
              How OnionGuard works
            </h2>
            <p className="mt-4 text-muted">Four steps between a sick crop and a clear plan.</p>
          </Reveal>

          <div className="mt-14 grid grid-cols-1 gap-x-8 gap-y-12 sm:grid-cols-2 lg:grid-cols-4">
            {HOW_IT_WORKS.map((step, i) => (
              <Reveal key={step.step} delay={i * 0.1}>
                <div>
                  <span className="font-display block text-4xl font-extrabold text-brand-200">
                    {step.step}
                  </span>
                  <h3 className="font-display mt-3 text-lg font-bold text-brand-950">
                    {step.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted">{step.description}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* Closing CTA */}
      <section className="bg-brand-900">
        <Reveal className="mx-auto max-w-4xl px-5 py-20 text-center sm:px-8">
          <h2 className="font-display text-3xl font-bold text-white sm:text-4xl">
            Ready to protect your onion harvest?
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-brand-200">
            OnionGuard is free, works offline, and speaks your language. Download it today.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
            <a
              href={PLAY_STORE_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 rounded-full bg-white px-6 py-3.5 text-sm font-semibold text-brand-900 shadow-lg transition-transform hover:-translate-y-0.5"
            >
              Get the App <ArrowRight size={16} />
            </a>
            <Link
              href="/contact"
              className="inline-flex items-center gap-1.5 rounded-full border border-white/30 px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-white/10"
            >
              Contact the team
            </Link>
          </div>
        </Reveal>
      </section>
    </div>
  );
}
