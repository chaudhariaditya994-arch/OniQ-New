"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { AnimatePresence, motion } from "framer-motion";
import type { ReactNode } from "react";

export default function HeroCarousel({
  images,
  interval = 5000,
  overlayClassName = "bg-linear-to-b from-brand-950/75 via-brand-950/55 to-brand-950/80",
  fit = "contain",
  aspectClassName = "aspect-6/5",
  heightClassName = "min-h-[420px] sm:min-h-[480px]",
  children,
}: {
  images: readonly { src: string; alt: string }[];
  interval?: number;
  overlayClassName?: string;
  /** "contain" shows the full photo with no cropping (height follows aspectClassName).
   *  "cover" fills a fixed-height band and crops the photo — suited to portrait headshots. */
  fit?: "contain" | "cover";
  aspectClassName?: string;
  heightClassName?: string;
  children: ReactNode;
}) {
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (images.length <= 1) return;
    const id = setInterval(() => setIndex((i) => (i + 1) % images.length), interval);
    return () => clearInterval(id);
  }, [images.length, interval]);

  const sizingClassName = fit === "contain" ? `${aspectClassName} min-h-105` : heightClassName;

  return (
    <section className={`relative flex w-full items-center overflow-hidden ${sizingClassName}`}>
      <div className="absolute inset-0 bg-brand-950">
        <AnimatePresence>
          <motion.div
            key={images[index].src}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 1.4, ease: "easeInOut" }}
            className="absolute inset-0"
          >
            {fit === "contain" && (
              <Image
                src={images[index].src}
                alt=""
                aria-hidden
                fill
                className="scale-110 object-cover opacity-60 blur-2xl"
              />
            )}
            <Image
              src={images[index].src}
              alt={images[index].alt}
              fill
              priority={index === 0}
              className={fit === "contain" ? "object-contain" : "object-cover"}
            />
          </motion.div>
        </AnimatePresence>
        <div className={`absolute inset-0 ${overlayClassName}`} />
      </div>

      <div className="relative z-10 w-full -translate-y-2 sm:-translate-y-28 lg:-translate-y-40">
        {children}
      </div>

      {images.length > 1 && (
        <div className="absolute inset-x-0 bottom-4 z-10 flex items-center justify-center gap-2">
          {images.map((img, i) => (
            <button
              key={img.src}
              type="button"
              aria-label={`Show background image ${i + 1}`}
              onClick={() => setIndex(i)}
              className={`h-1.5 rounded-full transition-all duration-300 ${
                i === index ? "w-6 bg-white" : "w-1.5 bg-white/40 hover:bg-white/70"
              }`}
            />
          ))}
        </div>
      )}
    </section>
  );
}
