import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import ContactForm from "@/components/ContactForm";
import HeroCarousel from "@/components/HeroCarousel";
import TypingText from "@/components/TypingText";
import { CONTACT_HERO_IMAGES, CONTACT_TYPING_PHRASES } from "@/lib/data";

export const metadata: Metadata = {
  title: "Contact Us — OnionGuard",
  description: "Get in touch with the OnionGuard team.",
};

export default function ContactPage() {
  return (
    <div>
      <HeroCarousel images={CONTACT_HERO_IMAGES}>
        <Reveal className="px-5 py-10 text-center sm:px-8">
          <span className="text-xs font-semibold uppercase tracking-widest text-brand-200">
            Contact us
          </span>
          <h1 className="font-display mt-3 whitespace-nowrap text-[clamp(0px,calc(12px+2.46vw),2.75rem)] font-extrabold text-white">
            We&apos;d love to hear from you
          </h1>
          <div className="mx-auto mt-4 flex min-h-14 max-w-3xl items-start justify-center">
            <TypingText
              phrases={CONTACT_TYPING_PHRASES}
              className="text-base leading-relaxed text-white/85 sm:text-lg"
            />
          </div>
        </Reveal>
      </HeroCarousel>

      <section className="bg-white">
        <div className="mx-auto max-w-2xl px-5 pt-14 pb-24 sm:px-8 sm:pt-20">
          <Reveal>
            <ContactForm />
          </Reveal>
        </div>
      </section>
    </div>
  );
}
