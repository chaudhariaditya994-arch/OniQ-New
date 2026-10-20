"use client";

import { useRef, useState } from "react";
import { Play } from "lucide-react";
import { motion } from "framer-motion";
import { VIDEOS } from "@/lib/data";

function VideoCard({ src, label, delay }: { src: string; label: string; delay: number }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [playing, setPlaying] = useState(false);

  const play = () => {
    videoRef.current?.play();
    setPlaying(true);
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.5, delay }}
      className="overflow-hidden rounded-2xl border border-border bg-white shadow-sm"
    >
      <div className="relative aspect-video w-full bg-brand-950">
        <video
          ref={videoRef}
          src={src}
          controls={playing}
          playsInline
          className="h-full w-full object-contain"
          onPause={() => setPlaying(false)}
          onPlay={() => setPlaying(true)}
        />
        {!playing && (
          <button
            aria-label={`Play ${label}`}
            onClick={play}
            className="absolute inset-0 flex items-center justify-center bg-black/20 transition-colors hover:bg-black/30"
          >
            <span className="flex h-16 w-16 items-center justify-center rounded-full bg-white/90 text-brand-800 shadow-lg transition-transform hover:scale-110">
              <Play size={28} fill="currentColor" />
            </span>
          </button>
        )}
      </div>
      <p className="px-5 py-4 text-sm font-medium text-muted">{label}</p>
    </motion.div>
  );
}

export default function VideoShowcase() {
  return (
    <div className="grid grid-cols-1 gap-8 sm:grid-cols-3">
      {VIDEOS.map((v, i) => (
        <VideoCard key={v.src} src={v.src} label={v.label} delay={i * 0.1} />
      ))}
    </div>
  );
}
