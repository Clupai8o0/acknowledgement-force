/* Acknowledgement Force — landing interactions */
(function () {
  "use strict";
  const root = document.documentElement;
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---- Theme (persist + follow system on first visit) ---- */
  const THEME_KEY = "af-landing-theme";
  const saved = localStorage.getItem(THEME_KEY);
  if (saved) {
    root.setAttribute("data-theme", saved);
  } else if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
    root.setAttribute("data-theme", "dark");
  }
  const themeToggle = document.getElementById("themeToggle");
  themeToggle?.addEventListener("click", () => {
    const next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
    root.setAttribute("data-theme", next);
    localStorage.setItem(THEME_KEY, next);
  });

  /* ---- Nav elevation on scroll ---- */
  const navInner = document.querySelector(".nav-inner");
  const onScroll = () => {
    if (!navInner) return;
    navInner.style.boxShadow =
      window.scrollY > 30
        ? "var(--shadow-ambient), inset 0 0 0 1px color-mix(in srgb, var(--outline) 45%, transparent)"
        : "";
  };
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* ---- Mobile menu ---- */
  const menuBtn = document.getElementById("menuBtn");
  const mobileMenu = document.getElementById("mobileMenu");
  const toggleMenu = (open) => {
    mobileMenu.classList.toggle("open", open);
    menuBtn.setAttribute("aria-expanded", String(open));
    document.body.style.overflow = open ? "hidden" : "";
  };
  menuBtn?.addEventListener("click", () =>
    toggleMenu(!mobileMenu.classList.contains("open"))
  );
  mobileMenu?.querySelectorAll("a").forEach((a) =>
    a.addEventListener("click", () => toggleMenu(false))
  );

  /* ---- Hero staggered entrance ---- */
  const heroEls = document.querySelectorAll("[data-hero]");
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

  /* ---- Scroll reveal w/ stagger among siblings ---- */
  const reveals = document.querySelectorAll(".reveal");
  if (reduceMotion || !("IntersectionObserver" in window)) {
    reveals.forEach((el) => el.classList.add("in"));
  } else {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const el = entry.target;
          const siblings = Array.from(el.parentElement.children).filter((c) =>
            c.classList.contains("reveal")
          );
          const idx = Math.max(0, siblings.indexOf(el));
          el.style.transitionDelay = Math.min(idx * 70, 350) + "ms";
          el.classList.add("in");
          io.unobserve(el);
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
    );
    reveals.forEach((el) => io.observe(el));
  }

  /* ---- Interactive checklist + progress badge ---- */
  const checklist = document.getElementById("checklist");
  const badge = document.getElementById("progressBadge");
  const rows = checklist ? Array.from(checklist.querySelectorAll("[data-check]")) : [];
  const total = rows.length;
  const updateBadge = () => {
    const done = rows.filter((r) => r.classList.contains("checked")).length;
    badge.textContent = `${done}/${total}`;
    badge.classList.toggle("done", done === total && total > 0);
    // tiny pop
    if (!reduceMotion) {
      badge.animate(
        [{ transform: "scale(1)" }, { transform: "scale(1.18)" }, { transform: "scale(1)" }],
        { duration: 320, easing: "cubic-bezier(0.34,1.56,0.64,1)" }
      );
    }
  };
  rows.forEach((r) =>
    r.addEventListener("click", () => {
      r.classList.toggle("checked");
      updateBadge();
    })
  );
  if (badge) updateBadge();

  /* ---- Schedule segmented control ---- */
  const segs = document.getElementById("segs");
  const detail = document.getElementById("scheduleDetail");
  segs?.querySelectorAll(".seg").forEach((seg) =>
    seg.addEventListener("click", () => {
      segs.querySelector(".active")?.classList.remove("active");
      seg.classList.add("active");
      const text = seg.getAttribute("data-detail");
      if (reduceMotion) {
        detail.textContent = text;
        return;
      }
      detail.style.opacity = "0";
      detail.style.transform = "translateY(4px)";
      setTimeout(() => {
        detail.textContent = text;
        detail.style.transition = "opacity .3s var(--ease-out), transform .3s var(--ease-out)";
        detail.style.opacity = "1";
        detail.style.transform = "none";
      }, 160);
    })
  );

  /* ---- "Today's action" typewriter ---- */
  const typeEl = document.getElementById("typeAction");
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
      let p = 0,
        i = 0,
        deleting = false;
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
      // Start once visible
      const startIO = new IntersectionObserver((e) => {
        if (e[0].isIntersecting) {
          tick();
          startIO.disconnect();
        }
      });
      startIO.observe(typeEl);
    }
  }

  /* ---- Count-up stats ---- */
  const counters = document.querySelectorAll("[data-count]");
  if (counters.length) {
    const cio = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const el = entry.target;
          const target = parseFloat(el.getAttribute("data-count"));
          const suffix = el.getAttribute("data-suffix") || "";
          if (reduceMotion) {
            el.textContent = target + suffix;
            cio.unobserve(el);
            return;
          }
          const dur = 1100;
          const start = performance.now();
          const step = (now) => {
            const t = Math.min(1, (now - start) / dur);
            const eased = 1 - Math.pow(1 - t, 3);
            el.textContent = Math.round(target * eased) + suffix;
            if (t < 1) requestAnimationFrame(step);
          };
          requestAnimationFrame(step);
          cio.unobserve(el);
        });
      },
      { threshold: 0.6 }
    );
    counters.forEach((c) => cio.observe(c));
  }

  /* ---- Video slot placeholder feedback ---- */
  const videoSlot = document.getElementById("videoSlot");
  videoSlot?.addEventListener("click", () => {
    const cap = videoSlot.querySelector(".video-cap");
    if (cap) cap.textContent = "Drop your screen recording into index.html →";
  });
  videoSlot?.addEventListener("keydown", (e) => {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      videoSlot.click();
    }
  });

  /* ---- Footer year ---- */
  const yr = document.getElementById("year");
  if (yr) yr.textContent = new Date().getFullYear();
})();
