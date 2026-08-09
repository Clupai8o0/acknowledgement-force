"use client";

import { useEffect } from "react";

// Ports the original landing interactions (formerly js/main.js) into a
// client-side effect that runs once after mount, operating on the DOM.
export default function LandingEffects() {
  useEffect(() => {
    const root = document.documentElement;
    const reduceMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)"
    ).matches;

    // Theme toggle (initial value is set pre-paint in layout.tsx)
    const THEME_KEY = "af-landing-theme";
    const themeToggle = document.getElementById("themeToggle");
    const onThemeClick = () => {
      const next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      localStorage.setItem(THEME_KEY, next);
    };
    themeToggle?.addEventListener("click", onThemeClick);

    // Nav elevation on scroll
    const navInner = document.querySelector<HTMLElement>(".nav-inner");
    const onScroll = () => {
      if (!navInner) return;
      navInner.style.boxShadow =
        window.scrollY > 30
          ? "var(--shadow-ambient), inset 0 0 0 1px color-mix(in srgb, var(--outline) 45%, transparent)"
          : "";
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();

    // Mobile menu
    const menuBtn = document.getElementById("menuBtn");
    const mobileMenu = document.getElementById("mobileMenu");
    const toggleMenu = (open: boolean) => {
      mobileMenu?.classList.toggle("open", open);
      menuBtn?.setAttribute("aria-expanded", String(open));
      document.body.style.overflow = open ? "hidden" : "";
    };
    const onMenuClick = () =>
      toggleMenu(!mobileMenu?.classList.contains("open"));
    menuBtn?.addEventListener("click", onMenuClick);
    const menuLinks = mobileMenu ? Array.from(mobileMenu.querySelectorAll("a")) : [];
    const onMenuLink = () => toggleMenu(false);
    menuLinks.forEach((a) => a.addEventListener("click", onMenuLink));

    // Hero staggered entrance
    const heroEls = Array.from(document.querySelectorAll<HTMLElement>("[data-hero]"));
    heroEls.forEach((el, i) => {
      el.style.opacity = "0";
      el.style.transform = "translateY(20px)";
      el.style.filter = "blur(8px)";
      if (reduceMotion) {
        el.style.opacity = "1";
        el.style.transform = "none";
        el.style.filter = "none";
        return;
      }
      setTimeout(() => {
        el.style.transition =
          "opacity .9s var(--ease-out), transform .9s var(--ease-out), filter .9s var(--ease-out)";
        el.style.opacity = "1";
        el.style.transform = "none";
        el.style.filter = "none";
      }, 180 + i * 130);
    });

    // Scroll reveal w/ stagger among siblings
    const reveals = Array.from(document.querySelectorAll<HTMLElement>(".reveal"));
    let io: IntersectionObserver | undefined;
    if (reduceMotion || !("IntersectionObserver" in window)) {
      reveals.forEach((el) => el.classList.add("in"));
    } else {
      io = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            const el = entry.target as HTMLElement;
            const siblings = Array.from(el.parentElement?.children ?? []).filter(
              (c) => c.classList.contains("reveal")
            );
            const idx = Math.max(0, siblings.indexOf(el));
            el.style.transitionDelay = Math.min(idx * 70, 350) + "ms";
            el.classList.add("in");
            io?.unobserve(el);
          });
        },
        { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
      );
      reveals.forEach((el) => io!.observe(el));
    }

    // Interactive checklist + progress badge
    const checklist = document.getElementById("checklist");
    const badge = document.getElementById("progressBadge");
    const rows = checklist
      ? Array.from(checklist.querySelectorAll<HTMLElement>("[data-check]"))
      : [];
    const total = rows.length;
    const updateBadge = () => {
      if (!badge) return;
      const done = rows.filter((r) => r.classList.contains("checked")).length;
      badge.textContent = `${done}/${total}`;
      badge.classList.toggle("done", done === total && total > 0);
      if (!reduceMotion) {
        badge.animate(
          [
            { transform: "scale(1)" },
            { transform: "scale(1.18)" },
            { transform: "scale(1)" },
          ],
          { duration: 320, easing: "cubic-bezier(0.34,1.56,0.64,1)" }
        );
      }
    };
    const rowHandlers = rows.map((r) => {
      const h = () => {
        r.classList.toggle("checked");
        updateBadge();
      };
      r.addEventListener("click", h);
      return h;
    });
    if (badge) updateBadge();

    // Schedule segmented control
    const segs = document.getElementById("segs");
    const detail = document.getElementById("scheduleDetail");
    const segEls = segs ? Array.from(segs.querySelectorAll<HTMLElement>(".seg")) : [];
    const segHandlers = segEls.map((seg) => {
      const h = () => {
        segs?.querySelector(".active")?.classList.remove("active");
        seg.classList.add("active");
        const text = seg.getAttribute("data-detail") ?? "";
        if (!detail) return;
        if (reduceMotion) {
          detail.textContent = text;
          return;
        }
        detail.style.opacity = "0";
        detail.style.transform = "translateY(4px)";
        setTimeout(() => {
          detail.textContent = text;
          detail.style.transition =
            "opacity .3s var(--ease-out), transform .3s var(--ease-out)";
          detail.style.opacity = "1";
          detail.style.transform = "none";
        }, 160);
      };
      seg.addEventListener("click", h);
      return h;
    });

    // "Today's action" typewriter
    const typeEl = document.getElementById("typeAction");
    let typeStartIO: IntersectionObserver | undefined;
    if (typeEl) {
      const phrases = [
        "Ship the feature behind the flag.",
        "Write the doc no one wants to write.",
        "Finish one hard problem, fully.",
        "Send the email you've been avoiding.",
      ];
      if (reduceMotion) {
        typeEl.textContent = phrases[0];
      } else {
        let p = 0;
        let i = 0;
        let deleting = false;
        const cursor = document.createElement("span");
        cursor.className = "cursor";
        const tick = () => {
          const word = phrases[p];
          typeEl.textContent = word.slice(0, i);
          typeEl.appendChild(cursor);
          if (!deleting && i < word.length) {
            i++;
            setTimeout(tick, 55);
          } else if (!deleting && i === word.length) {
            deleting = true;
            setTimeout(tick, 2200);
          } else if (deleting && i > 0) {
            i--;
            setTimeout(tick, 26);
          } else {
            deleting = false;
            p = (p + 1) % phrases.length;
            setTimeout(tick, 380);
          }
        };
        typeStartIO = new IntersectionObserver((e) => {
          if (e[0].isIntersecting) {
            tick();
            typeStartIO?.disconnect();
          }
        });
        typeStartIO.observe(typeEl);
      }
    }

    // Count-up stats
    const counters = Array.from(document.querySelectorAll<HTMLElement>("[data-count]"));
    let cio: IntersectionObserver | undefined;
    if (counters.length) {
      cio = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            const el = entry.target as HTMLElement;
            const target = parseFloat(el.getAttribute("data-count") ?? "0");
            const suffix = el.getAttribute("data-suffix") || "";
            if (reduceMotion) {
              el.textContent = target + suffix;
              cio?.unobserve(el);
              return;
            }
            const dur = 1100;
            const start = performance.now();
            const step = (now: number) => {
              const t = Math.min(1, (now - start) / dur);
              const eased = 1 - Math.pow(1 - t, 3);
              el.textContent = Math.round(target * eased) + suffix;
              if (t < 1) requestAnimationFrame(step);
            };
            requestAnimationFrame(step);
            cio?.unobserve(el);
          });
        },
        { threshold: 0.6 }
      );
      counters.forEach((c) => cio!.observe(c));
    }

    // Footer year
    const yr = document.getElementById("year");
    if (yr) yr.textContent = String(new Date().getFullYear());

    return () => {
      themeToggle?.removeEventListener("click", onThemeClick);
      window.removeEventListener("scroll", onScroll);
      menuBtn?.removeEventListener("click", onMenuClick);
      menuLinks.forEach((a) => a.removeEventListener("click", onMenuLink));
      rows.forEach((r, idx) => r.removeEventListener("click", rowHandlers[idx]));
      segEls.forEach((s, idx) => s.removeEventListener("click", segHandlers[idx]));
      io?.disconnect();
      cio?.disconnect();
      typeStartIO?.disconnect();
    };
  }, []);

  return null;
}
