"use client";

import Image from "next/image";
import { motion } from "framer-motion";

export default function TeamCard({
  name,
  role,
  department,
  photo,
  delay = 0,
}: {
  name: string;
  role: string;
  department: string;
  photo: string;
  delay?: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 28 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.5, delay, ease: [0.22, 1, 0.36, 1] }}
      whileHover={{ y: -8 }}
      className="group overflow-hidden rounded-2xl border border-border bg-white shadow-sm transition-shadow hover:shadow-xl"
    >
      <div className="relative aspect-[4/5] w-full overflow-hidden bg-brand-100">
        <Image
          src={photo}
          alt={name}
          fill
          className="object-cover transition-transform duration-500 group-hover:scale-105"
        />
        <div className="absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-brand-950/70 to-transparent" />
      </div>
      <div className="p-5">
        <span className="inline-block rounded-full bg-brand-100 px-3 py-1 text-xs font-semibold text-brand-800">
          {role}
        </span>
        <h3 className="mt-3 font-display text-lg font-bold text-brand-950">{name}</h3>
        <p className="mt-1 text-sm text-muted">{department}</p>
      </div>
    </motion.div>
  );
}
