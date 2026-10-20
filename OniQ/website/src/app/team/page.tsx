import type { Metadata } from "next";
import Reveal from "@/components/Reveal";
import TeamCard from "@/components/TeamCard";
import HeroCarousel from "@/components/HeroCarousel";
import TypingText from "@/components/TypingText";
import { TEAM, TEAM_HERO_IMAGES, TEAM_TYPING_PHRASES } from "@/lib/data";

export const metadata: Metadata = {
  title: "Team — OnionGuard",
  description: "Meet the Nkabom Honours Team behind OnionGuard, University of Ghana.",
};

export default function TeamPage() {
  return (
    <div>
      <HeroCarousel
        images={TEAM_HERO_IMAGES}
        fit="cover"
        heightClassName="min-h-[480px] sm:min-h-[560px]"
        overlayClassName="bg-linear-to-b from-brand-950/85 via-brand-950/60 to-brand-950/85"
      >
        <Reveal className="px-5 py-10 text-center sm:px-8">
          <span className="text-xs font-semibold uppercase tracking-widest text-brand-200">
            Meet the team
          </span>
          <h1 className="font-display mt-3 whitespace-nowrap text-[clamp(0px,calc(11px+2.53vw),2.75rem)] font-extrabold text-white">
            The Nkabom Honours Team
          </h1>
          <div className="mx-auto mt-4 flex min-h-14 max-w-3xl items-start justify-center">
            <TypingText
              phrases={TEAM_TYPING_PHRASES}
              className="text-base leading-relaxed text-white/85 sm:text-lg"
            />
          </div>
        </Reveal>
      </HeroCarousel>

      <section className="bg-white">
        <div className="mx-auto max-w-6xl px-5 py-16 sm:px-8">
          <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {TEAM.map((member, i) => (
              <TeamCard key={member.name} {...member} delay={i * 0.08} />
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}
