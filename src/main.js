import { invoke } from "@tauri-apps/api/core";
import { getCurrentWindow } from "@tauri-apps/api/window";

const appWindow = getCurrentWindow();

// ============================================================================
// CONSTANTS & CONFIG
// ============================================================================

const STORAGE_KEYS = {
  acknowledgement: "af-acknowledgement-v1",
  checklist: "af-checklist-v1",
  history: "af-history-v1",
};

const DAILY_NON_NEGOTIABLES = [
  { id: "brush-teeth", label: "Brush teeth (morning & night)" },
  { id: "wash-face", label: "Wash face (morning & night)" },
  { id: "leetcode", label: "LeetCode: 1 problem minimum" },
  { id: "cold-message", label: "Send 1 cold message/email" },
  { id: "gym", label: "Gym/30min physical activity" },
  { id: "journal", label: "Journal: 5-10 minutes" },
  { id: "read", label: "Read: 15-30 minutes" },
  { id: "no-doomscroll", label: "No doomscrolling (sit in silence 5-10 min)" },
];

const CONTRACT_MARKDOWN = `# Acknowledgement Force Daily Contract

**Date:** {{DATE}}
**For:** Samridh Limbu

---

## I. WHO I AM

I am Samridh Limbu. I am building a high-leverage tech career in Australia while securing PR as early as possible. My success depends on **sustained performance**, not bursts of effort.

---

## II. NON-NEGOTIABLE RULES

1. **Sleep 11pm-7am.** Without 7-8 hours, everything else collapses.
2. **Anxiety needs systems, not willpower.** Box breathing, 5-4-3-2-1 grounding, structured journaling.
3. **Avoidance creates lethargy.** Gaming and scrolling extend suffering. Real rest is deliberate.
4. **Execution beats planning.** Commits, deployments, and documentation are the only valid measures.
5. **One project at a time.** Finish before starting new.
6. **DSEC: 5 hours/week max** unless it produces portfolio ROI.
7. **Every decision aligns with PR.** Backend roles in Australian enterprise are the target.
8. **Work shifts are chaos; systems adapt.** My schedule is unpredictable. I plan accordingly.
9. **Burnout isn't honourable.** I monitor energy and adjust load proactively.

---

## III. CURRENT PRIORITIES (Q1 2026)

**Academic:** High Distinction standard. Every assignment is a portfolio piece.

**Technical:** Meta Back-End Cert (9 credits), AWS + Azure certs, Docker/Kubernetes, LeetCode (NeetCode Blind 75 + company-specific).

**Portfolio:** Current project documented and deployed. All work public on GitHub.

**Financial:** Save $400/week → MacBook Pro + Bali trip fund + etc...

**Health:** Gym consistency established as non-negotiable routine.

**Systems:** Anxiety management operational. Sleep restructured. Motion AI evaluated.

---

## IV. DAILY NON-NEGOTIABLES

**I will complete these every day:**

- [ ] Brush teeth (morning & night)
- [ ] Wash face (morning & night)
- [ ] LeetCode: 1 problem minimum
- [ ] Send 1 cold message/email to a professional or company
- [ ] Gym session or 30min physical activity
- [ ] Journal: 5-10 minutes (structured template)
- [ ] Read: 15-30 minutes (technical or strategic)
- [ ] **No doomscrolling.** Sit in silence instead (5-10 min minimum)

---

## V. WHAT I WILL NOT DO

- Stay up past midnight without explicit justification.
- Run multiple side projects simultaneously.
- Accept commitments without clear portfolio ROI.
- Confuse busyness with progress.
- Skip rest cycles for "grinding."
- Ignore anxiety symptoms until lethargy hits.

---

## VI. DAILY ACKNOWLEDGEMENT

**By opening this app, I acknowledge:**

- I have read and understood all principles above.
- I commit to executing with discipline and clarity.
- I accept that sustainable performance requires protecting sleep, managing anxiety, and building demonstrable work.
- I measure progress by outputs, not hours or plans.

---

## VII. ACCOUNTABILITY

**When I notice failure modes (skipping sleep, planning instead of doing, treating symptoms):**

1. Stop immediately.
2. Box breathing + 5-4-3-2-1 grounding.
3. Structured journaling.
4. Reassess with Claude.

---

**I am Samridh Limbu. I commit to this contract for today.**`;

const INTRO_DURATION_MS = 3200;
const SCROLL_UNLOCK_DELAY_MS = 2000;

// ============================================================================
// DOM ELEMENTS
// ============================================================================

const bodyElement = document.body;
const introGreeting = document.getElementById("intro-greeting");

// Contract View Elements
const contractView = document.getElementById("contract-view");
const contractContainer = document.getElementById("contract-container");
const contractContent = document.getElementById("contract-content");
const ackCheckbox = document.getElementById("ack-checkbox");
const ackActionInput = document.getElementById("ack-action-input");
const ackConfirmBtn = document.getElementById("ack-confirm-btn");
const ackStatus = document.getElementById("ack-status");

// App View Elements
const appView = document.getElementById("app-view");
const sidebar = document.getElementById("sidebar");
const checklist = document.getElementById("checklist");
const progressBadge = document.getElementById("progress-badge");
const userNameDisplay = document.getElementById("user-name-display");
const dateDisplay = document.getElementById("date-display");
const todayActionText = document.getElementById("today-action-text");
const viewHistoryBtn = document.getElementById("view-history-btn");
const logoutBtn = document.getElementById("logout-btn");

// History Modal Elements
const historyModal = document.getElementById("history-modal");
const historyList = document.getElementById("history-list");
const historyCloseBtn = document.getElementById("history-close-btn");

// ============================================================================
// STATE
// ============================================================================

let scrollUnlocked = false;
let unlockTimer = null;
let checklistState = {};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

const getTodayDateString = () => {
  const now = new Date();
  return now.toISOString().split("T")[0];
};

const getFormattedDate = () => {
  const now = new Date();
  return now.toLocaleDateString("en-AU", {
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  });
};

const getShortDate = (dateStr) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString("en-AU", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
};

// ============================================================================
// STORAGE FUNCTIONS
// ============================================================================

const loadAcknowledgement = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.acknowledgement);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (error) {
    console.warn("Failed to load acknowledgement:", error);
    return null;
  }
};

const saveAcknowledgement = (data) => {
  localStorage.setItem(STORAGE_KEYS.acknowledgement, JSON.stringify(data));
};

const loadChecklist = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.checklist);
    if (!raw) return { date: null, items: {} };
    return JSON.parse(raw);
  } catch (error) {
    console.warn("Failed to load checklist:", error);
    return { date: null, items: {} };
  }
};

const saveChecklist = (data) => {
  localStorage.setItem(STORAGE_KEYS.checklist, JSON.stringify(data));
};

const loadHistory = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEYS.history);
    if (!raw) return [];
    return JSON.parse(raw);
  } catch (error) {
    console.warn("Failed to load history:", error);
    return [];
  }
};

const saveHistory = (history) => {
  localStorage.setItem(STORAGE_KEYS.history, JSON.stringify(history));
};

const addToHistory = (action, date) => {
  const history = loadHistory();
  // Only keep last 30 days of history
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - 30);
  const filteredHistory = history.filter(
    (item) => new Date(item.date) >= cutoffDate
  );
  // Add new entry at the beginning
  filteredHistory.unshift({ date, action, timestamp: Date.now() });
  saveHistory(filteredHistory);
};

// ============================================================================
// MARKDOWN PARSER (Simple)
// ============================================================================

const parseMarkdown = (markdown) => {
  let html = markdown;

  // Replace date placeholder
  html = html.replace("{{DATE}}", getFormattedDate());

  // Headers
  html = html.replace(/^### (.+)$/gm, '<h3 class="md-h3">$1</h3>');
  html = html.replace(/^## (.+)$/gm, '<h2 class="md-h2">$1</h2>');
  html = html.replace(/^# (.+)$/gm, '<h1 class="md-h1">$1</h1>');

  // Horizontal rules
  html = html.replace(/^---$/gm, '<hr class="md-hr">');

  // Bold
  html = html.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");

  // Italic (but not inside checkboxes)
  html = html.replace(/(?<!\[)\*(?!\s)(.+?)(?<!\s)\*(?!\])/g, "<em>$1</em>");

  // Checkboxes (non-interactive display)
  html = html.replace(
    /^- \[ \] (.+)$/gm,
    '<div class="md-checkbox-item"><span class="md-checkbox-icon"></span><span>$1</span></div>'
  );
  html = html.replace(
    /^- \[x\] (.+)$/gim,
    '<div class="md-checkbox-item checked"><span class="md-checkbox-icon"></span><span>$1</span></div>'
  );

  // Numbered lists
  html = html.replace(
    /^(\d+)\. (.+)$/gm,
    '<div class="md-list-item"><span class="md-list-number">$1.</span><span>$2</span></div>'
  );

  // Unordered lists (without checkboxes)
  html = html.replace(
    /^- (?!\[)(.+)$/gm,
    '<div class="md-bullet-item"><span class="md-bullet"></span><span>$1</span></div>'
  );

  // Paragraphs - wrap text blocks
  const lines = html.split("\n");
  const processed = [];
  let inParagraph = false;
  let paragraphContent = [];

  for (const line of lines) {
    const trimmed = line.trim();
    const isSpecial =
      trimmed.startsWith("<h") ||
      trimmed.startsWith("<hr") ||
      trimmed.startsWith("<div") ||
      trimmed === "";

    if (isSpecial) {
      if (inParagraph && paragraphContent.length > 0) {
        processed.push(
          `<p class="md-paragraph">${paragraphContent.join(" ")}</p>`
        );
        paragraphContent = [];
        inParagraph = false;
      }
      if (trimmed !== "") {
        processed.push(trimmed);
      }
    } else {
      inParagraph = true;
      paragraphContent.push(trimmed);
    }
  }

  if (paragraphContent.length > 0) {
    processed.push(`<p class="md-paragraph">${paragraphContent.join(" ")}</p>`);
  }

  return processed.join("\n");
};

// ============================================================================
// RENDER FUNCTIONS
// ============================================================================

const renderContract = () => {
  if (!contractContent) return;
  const html = parseMarkdown(CONTRACT_MARKDOWN);
  contractContent.innerHTML = html;
};

const renderIntro = () => {
  if (!introGreeting) return;
  introGreeting.textContent = "Welcome, Samridh. Take a deep breath.";
};

const renderChecklist = () => {
  if (!checklist) return;

  const today = getTodayDateString();
  const stored = loadChecklist();

  // Reset if it's a new day
  if (stored.date !== today) {
    checklistState = {};
    DAILY_NON_NEGOTIABLES.forEach((item) => {
      checklistState[item.id] = false;
    });
  } else {
    checklistState = stored.items || {};
  }

  checklist.innerHTML = "";

  DAILY_NON_NEGOTIABLES.forEach((item) => {
    const li = document.createElement("li");
    li.className = "checklist-item";
    li.dataset.id = item.id;

    const isChecked = checklistState[item.id] || false;
    if (isChecked) {
      li.classList.add("completed");
    }

    li.innerHTML = `
      <label class="checklist-label">
        <input type="checkbox" class="checklist-checkbox" ${isChecked ? "checked" : ""} />
        <span class="checklist-checkbox-custom"></span>
        <span class="checklist-text">${item.label}</span>
      </label>
    `;

    const checkbox = li.querySelector(".checklist-checkbox");
    checkbox.addEventListener("change", () => handleChecklistChange(item.id, checkbox.checked));

    checklist.appendChild(li);
  });

  updateProgress();
};

const updateProgress = () => {
  const completed = Object.values(checklistState).filter(Boolean).length;
  const total = DAILY_NON_NEGOTIABLES.length;

  if (progressBadge) {
    progressBadge.textContent = `${completed}/${total}`;
    progressBadge.dataset.progress = completed === total ? "complete" : completed > 0 ? "partial" : "none";
  }
};

const renderHistory = () => {
  if (!historyList) return;

  const history = loadHistory();
  const last7 = history.slice(0, 7);

  if (last7.length === 0) {
    historyList.innerHTML = '<p class="history-empty">No past actions recorded yet.</p>';
    return;
  }

  historyList.innerHTML = last7
    .map(
      (item) => `
      <div class="history-item">
        <span class="history-date">${getShortDate(item.date)}</span>
        <span class="history-action">${escapeHtml(item.action)}</span>
      </div>
    `
    )
    .join("");
};

const escapeHtml = (text) => {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
};

// ============================================================================
// VIEW MANAGEMENT
// ============================================================================

const showContractView = () => {
  if (contractView) contractView.dataset.visible = "true";
  if (appView) appView.dataset.visible = "false";
};

const showAppView = () => {
  if (contractView) contractView.dataset.visible = "false";
  if (appView) appView.dataset.visible = "true";

  // Load today's acknowledgement data
  const ack = loadAcknowledgement();
  if (ack && todayActionText) {
    todayActionText.textContent = ack.action;
  }

  if (dateDisplay) {
    dateDisplay.textContent = getFormattedDate();
  }

  renderChecklist();
  renderHistory();
};

const startIntro = () => {
  bodyElement.classList.add("intro-active");
  window.setTimeout(() => {
    bodyElement.classList.remove("intro-active");
    bodyElement.classList.add("intro-complete");
  }, INTRO_DURATION_MS);
};

// ============================================================================
// EVENT HANDLERS
// ============================================================================

const isAtBottom = (element) => {
  return element.scrollTop + element.clientHeight >= element.scrollHeight - 10;
};

const clearUnlockTimer = () => {
  if (unlockTimer) {
    window.clearTimeout(unlockTimer);
    unlockTimer = null;
  }
};

const scheduleUnlock = () => {
  if (scrollUnlocked || unlockTimer) return;

  unlockTimer = window.setTimeout(() => {
    scrollUnlocked = true;
    unlockTimer = null;
    updateAckFormState();
    if (ackStatus) {
      ackStatus.textContent = "Check the box and enter your highest-leverage action.";
    }
  }, SCROLL_UNLOCK_DELAY_MS);
};

const handleContractScroll = () => {
  if (!contractContainer || scrollUnlocked) return;

  if (isAtBottom(contractContainer)) {
    scheduleUnlock();
  } else if (unlockTimer) {
    clearUnlockTimer();
  }
};

const updateAckFormState = () => {
  const isChecked = ackCheckbox?.checked || false;
  const hasAction = (ackActionInput?.value?.trim().length || 0) > 0;
  const canConfirm = scrollUnlocked && isChecked && hasAction;

  if (ackConfirmBtn) {
    ackConfirmBtn.disabled = !canConfirm;
  }

  // Update status message
  if (ackStatus) {
    if (!scrollUnlocked) {
      ackStatus.textContent = "Scroll to the bottom of the contract.";
    } else if (!isChecked) {
      ackStatus.textContent = "Check the acknowledgement box.";
    } else if (!hasAction) {
      ackStatus.textContent = "Enter your highest-leverage action for today.";
    } else {
      ackStatus.textContent = "Ready to confirm.";
    }
  }
};

const handleAckCheckboxChange = () => {
  updateAckFormState();
};

const handleAckActionInput = () => {
  updateAckFormState();
};

const handleConfirmAcknowledgement = async () => {
  const action = ackActionInput?.value?.trim();
  if (!action || !ackCheckbox?.checked) return;

  const today = getTodayDateString();
  const ackData = {
    date: today,
    action,
    timestamp: Date.now(),
  };

  // Save acknowledgement
  saveAcknowledgement(ackData);

  // Add to history
  addToHistory(action, today);

  // Initialize checklist for today
  const checklistData = {
    date: today,
    items: {},
  };
  DAILY_NON_NEGOTIABLES.forEach((item) => {
    checklistData.items[item.id] = false;
  });
  saveChecklist(checklistData);

  // Record in Tauri backend
  try {
    await invoke("record_acknowledgement");
  } catch (error) {
    console.error("Failed to record acknowledgement:", error);
  }

  // Switch to app view
  showAppView();
};

const handleChecklistChange = (itemId, checked) => {
  checklistState[itemId] = checked;

  const today = getTodayDateString();
  saveChecklist({
    date: today,
    items: checklistState,
  });

  // Update UI
  const li = checklist?.querySelector(`[data-id="${itemId}"]`);
  if (li) {
    li.classList.toggle("completed", checked);
    // Add animation
    if (checked) {
      li.classList.add("just-completed");
      setTimeout(() => li.classList.remove("just-completed"), 400);
    }
  }

  updateProgress();
};

const handleViewHistory = () => {
  if (historyModal) {
    renderHistory();
    historyModal.dataset.visible = "true";
  }
};

const handleCloseHistory = () => {
  if (historyModal) {
    historyModal.dataset.visible = "false";
  }
};

const handleLogout = async () => {
  try {
    await appWindow.setClosable(true);
    await appWindow.destroy();
  } catch (error) {
    console.error("Failed to close app:", error);
    try {
      await appWindow.close();
    } catch (e) {
      console.error("Failed to close window:", e);
    }
  }
};

// ============================================================================
// SECURITY HANDLERS
// ============================================================================

const blockEvent = (event) => {
  // Allow events in app view
  if (appView?.dataset.visible === "true") return;
  event.preventDefault();
};

const blockKeys = (event) => {
  // Allow normal key usage in app view
  if (appView?.dataset.visible === "true") return;

  const blockedCombos = new Set(["a", "c", "v", "x", "p", "s"]);
  if ((event.ctrlKey || event.metaKey) && blockedCombos.has(event.key.toLowerCase())) {
    event.preventDefault();
    event.stopPropagation();
  }
};

// ============================================================================
// INITIALIZATION
// ============================================================================

const checkTodayAcknowledgement = () => {
  const today = getTodayDateString();
  const ack = loadAcknowledgement();

  if (ack && ack.date === today) {
    // Already acknowledged today - show app view directly
    return true;
  }

  // Need to acknowledge
  return false;
};

const init = async () => {
  renderIntro();
  renderContract();
  startIntro();

  // Check if already acknowledged today
  const alreadyAcknowledged = checkTodayAcknowledgement();

  if (alreadyAcknowledged) {
    showAppView();
  } else {
    showContractView();
  }

  // Event listeners for contract view
  if (contractContainer) {
    contractContainer.addEventListener("scroll", handleContractScroll, { passive: true });
  }

  if (ackCheckbox) {
    ackCheckbox.addEventListener("change", handleAckCheckboxChange);
  }

  if (ackActionInput) {
    ackActionInput.addEventListener("input", handleAckActionInput);
  }

  if (ackConfirmBtn) {
    ackConfirmBtn.addEventListener("click", handleConfirmAcknowledgement);
  }

  // Event listeners for app view
  if (viewHistoryBtn) {
    viewHistoryBtn.addEventListener("click", handleViewHistory);
  }

  if (historyCloseBtn) {
    historyCloseBtn.addEventListener("click", handleCloseHistory);
  }

  if (logoutBtn) {
    logoutBtn.addEventListener("click", handleLogout);
  }

  // Security event listeners (only in contract view)
  document.addEventListener("contextmenu", blockEvent);
  document.addEventListener("copy", blockEvent);
  document.addEventListener("cut", blockEvent);
  document.addEventListener("paste", blockEvent);
  document.addEventListener("selectstart", blockEvent);
  document.addEventListener("dragstart", blockEvent);
  document.addEventListener("keydown", blockKeys, true);

  // Prevent closing before acknowledgement
  await appWindow.onCloseRequested((event) => {
    const ack = loadAcknowledgement();
    const today = getTodayDateString();
    if (!ack || ack.date !== today) {
      event.preventDefault();
    }
  });
};

init();
