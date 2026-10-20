"use client";

import { useEffect, useRef } from "react";
import { animate, motion, useInView, useMotionValue, useTransform } from "framer-motion";

export default function StatCounter({
  value,
  suffix = "",
  label,
  decimals,
}: {
  value: number;
  suffix?: string;
  label: string;
  decimals?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, margin: "-60px" });
  const count = useMotionValue(0);
  const digits = decimals ?? (Number.isInteger(value) ? 0 : 2);
  const rounded = useTransform(count, (v) => v.toFixed(digits));

  useEffect(() => {
    if (inView) {
      const controls = animate(count, value, { duration: 1.4, ease: [0.22, 1, 0.36, 1] });
      return () => controls.stop();
    }
  }, [inView, value, count]);

  return (
    <div ref={ref} className="text-center">
      <div className="font-display flex items-baseline justify-center gap-0.5 text-4xl font-extrabold text-brand-800 sm:text-5xl">
        <motion.span>{rounded}</motion.span>
        <span>{suffix}</span>
      </div>
      <p className="mt-2 text-sm text-muted">{label}</p>
    </div>
  );
}
