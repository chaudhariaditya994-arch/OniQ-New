"use client";

import { useEffect, useState } from "react";

export default function TypingText({
  phrases,
  className = "",
  typingSpeed = 38,
  deletingSpeed = 22,
  pauseAfterType = 1900,
  pauseAfterDelete = 350,
}: {
  phrases: readonly string[];
  className?: string;
  typingSpeed?: number;
  deletingSpeed?: number;
  pauseAfterType?: number;
  pauseAfterDelete?: number;
}) {
  const [index, setIndex] = useState(0);
  const [text, setText] = useState("");
  const [phase, setPhase] = useState<"typing" | "pausing" | "deleting">("typing");

  useEffect(() => {
    const current = phrases[index] ?? "";
    let timeout: ReturnType<typeof setTimeout>;

    if (phase === "typing") {
      if (text.length < current.length) {
        timeout = setTimeout(() => setText(current.slice(0, text.length + 1)), typingSpeed);
      } else {
        timeout = setTimeout(() => setPhase("deleting"), pauseAfterType);
      }
    } else {
      if (text.length > 0) {
        timeout = setTimeout(() => setText(text.slice(0, -1)), deletingSpeed);
      } else {
        timeout = setTimeout(() => {
          setIndex((i) => (i + 1) % phrases.length);
          setPhase("typing");
        }, pauseAfterDelete);
      }
    }

    return () => clearTimeout(timeout);
  }, [text, phase, index, phrases, typingSpeed, deletingSpeed, pauseAfterType, pauseAfterDelete]);

  return (
    <span className={className}>
      <span aria-hidden="true">
        {text}
        <span className="animate-caret-blink border-r-2 border-current" />
      </span>
      <span className="sr-only">{phrases.join(". ")}</span>
    </span>
  );
}
