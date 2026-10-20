import type { ReactNode } from "react";

export default function PhoneFrame({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`relative mx-auto aspect-[9/19] w-full max-w-[280px] overflow-hidden rounded-[2.25rem] border-[6px] border-brand-950 bg-brand-950 shadow-2xl ${className}`}
    >
      <div className="absolute left-1/2 top-0 z-10 h-5 w-28 -translate-x-1/2 rounded-b-2xl bg-brand-950" />
      <div className="relative h-full w-full overflow-hidden rounded-[1.75rem] bg-black">
        {children}
      </div>
    </div>
  );
}
