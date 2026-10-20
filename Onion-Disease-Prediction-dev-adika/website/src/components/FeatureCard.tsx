"use client";

import { motion } from "framer-motion";
import {
  BarChart3,
  ClipboardList,
  Leaf,
  ScanLine,
  ShieldCheck,
  Volume2,
  type LucideIcon,
} from "lucide-react";

const ICONS: Record<string, LucideIcon> = {
  scan: ScanLine,
  leaf: Leaf,
  clipboard: ClipboardList,
  volume: Volume2,
  chart: BarChart3,
  shield: ShieldCheck,
};

export default function FeatureCard({
  title,
  description,
  icon,
  delay = 0,
}: {
  title: string;
  description: string;
  icon: string;
  delay?: number;
}) {
  const Icon = ICONS[icon] ?? Leaf;

  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.5, delay, ease: [0.22, 1, 0.36, 1] }}
      whileHover={{ y: -6 }}
      className="group rounded-2xl border border-border bg-white p-6 shadow-sm transition-shadow hover:shadow-lg hover:shadow-brand-100"
    >
      <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-100 text-brand-700 transition-colors group-hover:bg-brand-700 group-hover:text-white">
        <Icon size={22} strokeWidth={2} />
      </div>
      <h3 className="mt-4 font-display text-lg font-bold text-brand-950">{title}</h3>
      <p className="mt-2 text-sm leading-relaxed text-muted">{description}</p>
    </motion.div>
  );
}
