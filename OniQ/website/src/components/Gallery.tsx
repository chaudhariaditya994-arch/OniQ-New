"use client";

import { useState } from "react";
import Image from "next/image";
import { AnimatePresence, motion } from "framer-motion";
import { X } from "lucide-react";
import { GALLERY_PHOTOS } from "@/lib/data";

export default function Gallery() {
  const [active, setActive] = useState<number | null>(null);

  return (
    <>
      <div className="columns-2 gap-4 sm:columns-3 lg:columns-4 *:mb-4">
        {GALLERY_PHOTOS.map((shot, i) => (
          <motion.button
            key={shot.src}
            type="button"
            onClick={() => setActive(i)}
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-40px" }}
            transition={{ duration: 0.4, delay: (i % 8) * 0.05 }}
            whileHover={{ scale: 1.03 }}
            className="block w-full cursor-zoom-in overflow-hidden rounded-2xl border border-border bg-white shadow-sm"
          >
            <Image
              src={shot.src}
              alt={shot.alt}
              width={640}
              height={480}
              className="h-auto w-full object-cover"
            />
          </motion.button>
        ))}
      </div>

      <AnimatePresence>
        {active !== null && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setActive(null)}
            className="fixed inset-0 z-100 flex items-center justify-center bg-brand-950/90 p-6"
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.92 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.92 }}
              transition={{ duration: 0.2 }}
              onClick={(e) => e.stopPropagation()}
              className="relative max-h-[85vh] w-auto"
            >
              <Image
                src={GALLERY_PHOTOS[active].src}
                alt={GALLERY_PHOTOS[active].alt}
                width={1280}
                height={960}
                className="max-h-[85vh] w-auto rounded-2xl object-contain shadow-2xl"
              />
              <button
                aria-label="Close"
                onClick={() => setActive(null)}
                className="absolute -top-4 -right-4 flex h-10 w-10 items-center justify-center rounded-full bg-white text-brand-950 shadow-lg"
              >
                <X size={20} />
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
