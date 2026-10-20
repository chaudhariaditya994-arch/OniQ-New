import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import Gallery from "@/components/Gallery";
import VideoShowcase from "@/components/VideoShowcase";
import HeroCarousel from "@/components/HeroCarousel";
import TypingText from "@/components/TypingText";
import { GALLERY_HERO_IMAGES, GALLERY_TYPING_PHRASES } from "@/lib/data";

export const metadata: Metadata = {
  title: "Gallery — OnionGuard",
  description: "Demo videos and field photos from the OnionGuard team's work with onion farmers.",
};

export default function GalleryPage() {
  return (
    <div>
      <HeroCarousel images={GALLERY_HERO_IMAGES}>
        <Reveal className="px-5 py-10 text-center sm:px-8">
          <span className="text-xs font-semibold uppercase tracking-widest text-brand-200">
            Gallery
          </span>
          <h1 className="font-display mt-3 whitespace-nowrap text-[clamp(0px,calc(6px+2.79vw),2.75rem)] font-extrabold text-white">
            OnionGuard, from pitch to the field
          </h1>
          <div className="mx-auto mt-4 flex min-h-14 max-w-3xl items-start justify-center">
            <TypingText
              phrases={GALLERY_TYPING_PHRASES}
              className="text-base leading-relaxed text-white/85 sm:text-lg"
            />
          </div>
        </Reveal>
      </HeroCarousel>

      <section className="bg-white">
        <div className="mx-auto max-w-6xl px-5 pb-8 sm:px-8">
          <Reveal>
            <h2 className="font-display text-2xl font-bold text-brand-950">Team videos</h2>
          </Reveal>
          <div className="mt-10">
            <VideoShowcase />
          </div>
        </div>
      </section>

      <section className="bg-surface">
        <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8">
          <Reveal>
            <h2 className="font-display text-2xl font-bold text-brand-950">Photos</h2>
          </Reveal>
          <div className="mt-10">
            <Gallery />
          </div>
        </div>
      </section>
    </div>
  );
}
