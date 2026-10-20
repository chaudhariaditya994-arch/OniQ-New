"use client";

import { useState, type FormEvent } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { CheckCircle2, Loader2 } from "lucide-react";

type Status = "idle" | "sending" | "sent";

export default function ContactForm() {
  const [status, setStatus] = useState<Status>("idle");
  const [form, setForm] = useState({ name: "", email: "", message: "" });

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    setStatus("sending");
    window.setTimeout(() => {
      setStatus("sent");
    }, 900);
  };

  if (status === "sent") {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="flex flex-col items-center gap-3 rounded-2xl border border-brand-200 bg-brand-50 px-6 py-14 text-center"
      >
        <CheckCircle2 className="text-brand-700" size={40} />
        <h3 className="font-display text-xl font-bold text-brand-950">Message sent</h3>
        <p className="max-w-sm text-sm text-muted">
          Thanks, {form.name.split(" ")[0] || "there"}. The OnionGuard team will get back to
          you soon.
        </p>
      </motion.div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div className="grid gap-5 sm:grid-cols-2">
        <label className="block">
          <span className="mb-1.5 block text-sm font-medium text-brand-950">Name</span>
          <input
            required
            type="text"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className="w-full rounded-xl border border-border bg-white px-4 py-3 text-sm outline-none transition-colors focus:border-brand-600 focus:ring-2 focus:ring-brand-100"
            placeholder="Your name"
          />
        </label>
        <label className="block">
          <span className="mb-1.5 block text-sm font-medium text-brand-950">Email</span>
          <input
            required
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            className="w-full rounded-xl border border-border bg-white px-4 py-3 text-sm outline-none transition-colors focus:border-brand-600 focus:ring-2 focus:ring-brand-100"
            placeholder="you@example.com"
          />
        </label>
      </div>
      <label className="block">
        <span className="mb-1.5 block text-sm font-medium text-brand-950">Message</span>
        <textarea
          required
          rows={5}
          value={form.message}
          onChange={(e) => setForm({ ...form, message: e.target.value })}
          className="w-full resize-none rounded-xl border border-border bg-white px-4 py-3 text-sm outline-none transition-colors focus:border-brand-600 focus:ring-2 focus:ring-brand-100"
          placeholder="Tell us what you'd like to know"
        />
      </label>
      <motion.button
        type="submit"
        disabled={status === "sending"}
        whileHover={{ y: -2 }}
        whileTap={{ scale: 0.97 }}
        className="flex w-full items-center justify-center gap-2 rounded-xl bg-brand-800 px-6 py-3.5 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-brand-700 disabled:opacity-70 sm:w-auto"
      >
        <AnimatePresence mode="wait" initial={false}>
          {status === "sending" ? (
            <motion.span
              key="sending"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="flex items-center gap-2"
            >
              <Loader2 className="animate-spin" size={16} /> Sending…
            </motion.span>
          ) : (
            <motion.span
              key="send"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              Send Message
            </motion.span>
          )}
        </AnimatePresence>
      </motion.button>
    </form>
  );
}
