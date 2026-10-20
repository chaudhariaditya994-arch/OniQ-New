import Image from "next/image";
import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import FeatureCard from "@/components/FeatureCard";
import HeroCarousel from "@/components/HeroCarousel";
import TypingText from "@/components/TypingText";
import {
  ABOUT_HERO_IMAGES,
  ABOUT_TYPING_PHRASES,
  DISEASE_CLASSES,
  FEATURES,
  LANGUAGES,
  TECH_STACK,
} from "@/lib/data";

export const metadata: Metadata = {
  title: "About — OnionGuard",
  description:
    "Why OnionGuard exists, how its on-device AI model works, and the technology behind it.",
};

export default function AboutPage() {
  return (
    <div>
      {/* Hero */}
      <HeroCarousel images={ABOUT_HERO_IMAGES}>
        <div className="px-5 py-10 text-center sm:px-8">
          <Reveal>
            <span className="text-xs font-semibold uppercase tracking-widest text-brand-200">
              The problem
            </span>
            <h1 className="font-display mt-3 whitespace-normal text-xl font-extrabold text-white sm:whitespace-nowrap sm:text-[clamp(0px,calc(-2px+2.7vw),2.25rem)]">
              Crop disease is a food security crisis with no onion-specific AI to fight it
            </h1>
          </Reveal>
          <Reveal delay={0.1}>
            <div className="mx-auto mt-4 flex min-h-16 max-w-xl items-start justify-center sm:min-h-14">
              <TypingText
                phrases={ABOUT_TYPING_PHRASES}
                className="text-base leading-relaxed text-white/85 sm:text-lg"
              />
            </div>
          </Reveal>
        </div>
      </HeroCarousel>

      {/* Problem statement */}
      <section className="bg-white">
        <div className="mx-auto max-w-4xl px-5 py-16 sm:px-8">
          <Reveal>
            <p className="text-lg leading-relaxed text-muted">
              Crop losses due to pests and diseases remain a major threat to food security
              in West Africa, with losses reaching up to <strong className="text-brand-900">50%</strong> in
              some regions. While AI-based disease detection has shown promise, most existing
              models and datasets focus on crops like tomatoes and maize — until now, there
              were no pre-existing ML models for onion disease classification.
            </p>
            <p className="mt-4 text-lg leading-relaxed text-muted">
              The TOM2024 dataset — a collection of over 25,000 field-captured images across
              tomato, onion, and maize crops — was published in 2025, but provided only raw
              and augmented data without trained models. OnionGuard closes that gap: a custom
              classification model trained on TOM2024&apos;s onion subset, deployed in a mobile
              app accessible to the farmers who need it most.
            </p>
          </Reveal>
        </div>
      </section>

      {/* Full feature list */}
      <section className="bg-surface">
        <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8">
          <Reveal className="mx-auto max-w-2xl text-center">
            <h2 className="font-display text-3xl font-bold text-brand-950">What OnionGuard does</h2>
          </Reveal>
          <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((f, i) => (
              <FeatureCard key={f.title} {...f} delay={i * 0.06} />
            ))}
          </div>
        </div>
      </section>

      {/* ML model & tech */}
      <section className="bg-white">
        <div className="mx-auto max-w-6xl px-5 py-20 sm:px-8">
          <Reveal className="mx-auto max-w-2xl text-center">
            <span className="text-xs font-semibold uppercase tracking-widest text-brand-700">
              Under the hood
            </span>
            <h2 className="font-display mt-3 text-3xl font-bold text-brand-950">
              The model & the tech
            </h2>
            <p className="mt-4 text-muted">
              A MobileNetV3-Large backbone, fine-tuned in three progressive stages on the
              TOM2024 onion subset, then quantized for on-device inference.
            </p>
          </Reveal>

          <div className="mt-14 grid gap-10 lg:grid-cols-5 lg:items-start">
            <Reveal className="lg:col-span-2">
              <dl className="divide-y divide-border overflow-hidden rounded-2xl border border-border bg-white">
                {[
                  ["Base model", "MobileNetV3-Large (ImageNet pretrained)"],
                  ["Test accuracy", "100.00% (full model)"],
                  ["TFLite accuracy", "94.23%"],
                  ["Model size", "5.99 MB (float16 quantized)"],
                  ["Training images", "3,044 field images, 6 classes"],
                  ["Inference", "On-device + server-side"],
                ].map(([k, v]) => (
                  <div key={k} className="flex items-center justify-between gap-4 px-5 py-3.5 text-sm">
                    <dt className="text-muted">{k}</dt>
                    <dd className="text-right font-semibold text-brand-950">{v}</dd>
                  </div>
                ))}
              </dl>

              <div className="mt-6 flex flex-wrap gap-2">
                {DISEASE_CLASSES.map((c) => (
                  <span
                    key={c}
                    className="rounded-full bg-brand-100 px-3.5 py-1.5 text-xs font-semibold text-brand-800"
                  >
                    {c}
                  </span>
                ))}
              </div>
            </Reveal>

            <Reveal delay={0.1} className="lg:col-span-3">
              <div className="overflow-hidden rounded-2xl border border-border bg-surface p-3 shadow-sm">
                <Image
                  src="/Confusion-Matrix.png"
                  alt="OnionGuard model confusion matrix"
                  width={1000}
                  height={800}
                  className="h-auto w-full rounded-xl"
                />
              </div>
            </Reveal>
          </div>

          <Reveal delay={0.15} className="mt-16">
            <h3 className="font-display text-center text-xl font-bold text-brand-950">
              Built with
            </h3>
            <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
              {TECH_STACK.map((t) => (
                <span
                  key={t}
                  className="rounded-full border border-border bg-white px-4 py-2 text-sm font-medium text-brand-900 shadow-sm"
                >
                  {t}
                </span>
              ))}
            </div>
          </Reveal>

          <Reveal delay={0.2} className="mt-10">
            <h3 className="font-display text-center text-xl font-bold text-brand-950">
              Speaks 5 local languages
            </h3>
            <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
              {LANGUAGES.map((l) => (
                <span
                  key={l.code}
                  className="rounded-full bg-brand-800 px-4 py-2 text-sm font-medium text-white"
                >
                  {l.name}
                </span>
              ))}
            </div>
          </Reveal>
        </div>
      </section>

      {/* Academic credit */}
      <section className="border-t border-border bg-surface">
        <Reveal className="mx-auto max-w-3xl px-5 py-16 text-center sm:px-8">
          <p className="text-sm leading-relaxed text-muted">
            OnionGuard was developed as part of academic research at the{" "}
            <strong className="text-brand-900">University of Ghana</strong> by the Nkabom
            Honours Team, and is now live on the Google Play Store.
          </p>
        </Reveal>
      </section>
    </div>
  );
}
