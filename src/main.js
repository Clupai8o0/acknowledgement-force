import { invoke } from "@tauri-apps/api/core";
import { getCurrentWindow } from "@tauri-apps/api/window";
import letter from "./letter.json";

const appWindow = getCurrentWindow();
const bodyElement = document.body;

const introGreeting = document.getElementById("intro-greeting");
const acknowledgeButton = document.getElementById("acknowledge");
const letterContainer = document.getElementById("letter");
const letterTitle = document.getElementById("letter-title");
const letterContent = document.getElementById("letter-content");
const confirmSection = document.querySelector(".confirm");
const ackPrompt = document.getElementById("ack-prompt");
const ackPhrase = document.getElementById("ack-phrase");
const ackInput = document.getElementById("ack-input");
const statusLine = document.getElementById("status");

const editToggle = document.getElementById("edit-toggle");
const editor = document.getElementById("editor");
const editorClose = document.getElementById("editor-close");
const editorCancel = document.getElementById("editor-cancel");
const editorSave = document.getElementById("editor-save");
const editorReset = document.getElementById("editor-reset");
const editName = document.getElementById("edit-name");
const editTitle = document.getElementById("edit-title");
const editBody = document.getElementById("edit-body");
const editClosing = document.getElementById("edit-closing");
const editAckPrompt = document.getElementById("edit-ack-prompt");
const editAckText = document.getElementById("edit-ack-text");

const unlockDelayMs = 4000;
const introDurationMs = 3200;
const storageKey = "acknowledgement-app-settings-v1";
const blockedCombos = new Set(["a", "c", "v", "x", "p", "s"]);

const defaultConfig = {
  userName:
    typeof letter.defaultUserName === "string" && letter.defaultUserName.trim()
      ? letter.defaultUserName.trim()
      : "Friend",
  letterTitle:
    typeof letter.title === "string" && letter.title.trim()
      ? letter.title.trim()
      : "Acknowledgement Letter",
  letterBody: Array.isArray(letter.body) ? letter.body.join("\n\n") : "",
  letterClosing: typeof letter.closing === "string" ? letter.closing.trim() : "",
  acknowledgementPrompt:
    typeof letter.acknowledgementPrompt === "string" && letter.acknowledgementPrompt.trim()
      ? letter.acknowledgementPrompt.trim()
      : "Type the acknowledgement to continue:",
  acknowledgementText:
    typeof letter.acknowledgementText === "string" && letter.acknowledgementText.trim()
      ? letter.acknowledgementText.trim()
      : "I acknowledge that I will begin now.",
};

let appConfig = { ...defaultConfig };
let normalizedAcknowledgement = "";
let acknowledged = false;
let scrollUnlocked = false;
let phraseUnlocked = false;
let unlockTimer = null;

const setStatus = (message) => {
  if (statusLine) {
    statusLine.textContent = message;
  }
};

const normalizeInput = (value) => value.toLowerCase().replace(/\s+/g, " ").trim();

const isAtBottom = (element) =>
  element.scrollTop + element.clientHeight >= element.scrollHeight - 2;

const loadConfig = () => {
  try {
    const raw = localStorage.getItem(storageKey);
    if (!raw) {
      return { ...defaultConfig };
    }
    const parsed = JSON.parse(raw);
    return { ...defaultConfig, ...parsed };
  } catch (error) {
    console.warn("Failed to load settings:", error);
    return { ...defaultConfig };
  }
};

const saveConfig = (config) => {
  localStorage.setItem(storageKey, JSON.stringify(config));
};

const setConfirmLocked = (locked) => {
  if (confirmSection) {
    confirmSection.dataset.locked = locked ? "true" : "false";
  }
  if (ackInput) {
    ackInput.disabled = locked;
    if (locked) {
      ackInput.classList.remove("valid", "invalid");
    }
  }
};

const updateState = () => {
  const ready = scrollUnlocked && phraseUnlocked;
  acknowledgeButton.disabled = !ready;
  setConfirmLocked(!scrollUnlocked);

  if (!scrollUnlocked) {
    setStatus(
      unlockTimer
        ? "Hold for a moment to confirm completion."
        : "Scroll to the bottom to unlock acknowledgement."
    );
    return;
  }

  if (!phraseUnlocked) {
    setStatus("Type the acknowledgement to enable the button.");
    return;
  }

  setStatus("Acknowledgement unlocked.");
  acknowledgeButton.focus();
};

const clearUnlockTimer = () => {
  if (unlockTimer) {
    window.clearTimeout(unlockTimer);
    unlockTimer = null;
  }
};

const scheduleUnlock = () => {
  if (scrollUnlocked || unlockTimer) {
    return;
  }

  setStatus("Hold for a moment to confirm completion.");
  unlockTimer = window.setTimeout(() => {
    scrollUnlocked = true;
    unlockTimer = null;
    updateState();
  }, unlockDelayMs);
};

const handleScroll = () => {
  if (!letterContainer || scrollUnlocked) {
    return;
  }

  if (isAtBottom(letterContainer)) {
    scheduleUnlock();
  } else if (unlockTimer) {
    clearUnlockTimer();
    updateState();
  }
};

const parseParagraphs = (value) =>
  value
    .split(/\n\s*\n/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean);

const renderLetter = () => {
  if (!letterTitle || !letterContent) {
    return;
  }

  letterTitle.textContent = appConfig.letterTitle || defaultConfig.letterTitle;
  letterContent.innerHTML = "";

  const fragment = document.createDocumentFragment();
  const paragraphs = parseParagraphs(appConfig.letterBody || "");

  if (paragraphs.length === 0) {
    const p = document.createElement("p");
    p.textContent = "The acknowledgement letter is empty.";
    fragment.appendChild(p);
  } else {
    paragraphs.forEach((paragraph) => {
      const p = document.createElement("p");
      p.textContent = paragraph;
      fragment.appendChild(p);
    });
  }

  if (appConfig.letterClosing) {
    const closing = document.createElement("p");
    closing.className = "signature";
    closing.textContent = appConfig.letterClosing;
    fragment.appendChild(closing);
  }

  letterContent.appendChild(fragment);
};

const renderAcknowledgement = () => {
  if (ackPrompt) {
    ackPrompt.textContent = appConfig.acknowledgementPrompt;
  }
  if (ackPhrase) {
    ackPhrase.textContent = appConfig.acknowledgementText;
  }
  if (ackInput) {
    ackInput.placeholder = appConfig.acknowledgementText;
  }
};

const renderIntro = () => {
  if (!introGreeting) {
    return;
  }
  const name = appConfig.userName.trim() || "there";
  introGreeting.textContent = `Welcome ${name}, let's take a deep breathe.`;
};

const startIntro = () => {
  bodyElement.classList.add("intro-active");
  window.setTimeout(() => {
    bodyElement.classList.remove("intro-active");
    bodyElement.classList.add("intro-complete");
  }, introDurationMs);
};

const handleAcknowledgementInput = () => {
  if (!ackInput) {
    return;
  }

  if (!scrollUnlocked) {
    return;
  }

  const normalizedInput = normalizeInput(ackInput.value);
  phraseUnlocked = normalizedInput.length > 0 && normalizedInput === normalizedAcknowledgement;

  ackInput.classList.toggle("valid", phraseUnlocked);
  ackInput.classList.toggle("invalid", normalizedInput.length > 0 && !phraseUnlocked);
  updateState();
};

const closeApp = async () => {
  try {
    await appWindow.setClosable(true);
  } catch (error) {
    console.error("Failed to set closable:", error);
  }

  try {
    await appWindow.destroy();
    return;
  } catch (error) {
    console.error("Failed to destroy window:", error);
  }

  try {
    await appWindow.close();
  } catch (error) {
    console.error("Failed to close window:", error);
    throw error;
  }
};

const handleAcknowledge = async () => {
  if (acknowledged || !(scrollUnlocked && phraseUnlocked)) {
    return;
  }

  acknowledged = true;
  acknowledgeButton.disabled = true;
  setStatus("Acknowledged. Closing...");

  try {
    await invoke("record_acknowledgement");
  } catch (error) {
    console.error("Failed to record acknowledgement:", error);
  }

  try {
    await closeApp();
  } catch (error) {
    console.error("Failed to close window:", error);
    acknowledged = false;
    updateState();
  }
};

const isEditableTarget = (target) =>
  target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA");

const isEditorTarget = (target) => target && target.closest(".editor");

const blockEvent = (event) => {
  if (isEditorTarget(event.target)) {
    if (event.type === "selectstart" || event.type === "copy" || event.type === "cut" || event.type === "paste") {
      return;
    }
  }

  if (event.type === "selectstart" && isEditableTarget(event.target)) {
    return;
  }
  event.preventDefault();
};

const closeEditor = () => {
  if (!editor) {
    return;
  }
  editor.dataset.open = "false";
  editor.setAttribute("aria-hidden", "true");
};

const openEditor = () => {
  if (!editor) {
    return;
  }
  editor.dataset.open = "true";
  editor.setAttribute("aria-hidden", "false");
};

const fillEditorFields = () => {
  if (!editName || !editTitle || !editBody || !editClosing || !editAckPrompt || !editAckText) {
    return;
  }
  editName.value = appConfig.userName;
  editTitle.value = appConfig.letterTitle;
  editBody.value = appConfig.letterBody;
  editClosing.value = appConfig.letterClosing;
  editAckPrompt.value = appConfig.acknowledgementPrompt;
  editAckText.value = appConfig.acknowledgementText;
};

const resetProgress = () => {
  acknowledged = false;
  scrollUnlocked = false;
  phraseUnlocked = false;
  clearUnlockTimer();

  if (ackInput) {
    ackInput.value = "";
    ackInput.classList.remove("valid", "invalid");
  }
  if (letterContainer) {
    letterContainer.scrollTop = 0;
  }

  handleScroll();
  updateState();
};

const applyConfig = (config) => {
  appConfig = { ...defaultConfig, ...config };
  normalizedAcknowledgement = normalizeInput(appConfig.acknowledgementText);
  renderLetter();
  renderAcknowledgement();
  renderIntro();
  fillEditorFields();
  resetProgress();
};

const handleEditorSave = () => {
  if (
    !editName ||
    !editTitle ||
    !editBody ||
    !editClosing ||
    !editAckPrompt ||
    !editAckText
  ) {
    return;
  }

  const nextConfig = {
    userName: editName.value.trim() || defaultConfig.userName,
    letterTitle: editTitle.value.trim() || defaultConfig.letterTitle,
    letterBody: editBody.value.trim() || defaultConfig.letterBody,
    letterClosing: editClosing.value.trim(),
    acknowledgementPrompt: editAckPrompt.value.trim() || defaultConfig.acknowledgementPrompt,
    acknowledgementText: editAckText.value.trim() || defaultConfig.acknowledgementText,
  };

  saveConfig(nextConfig);
  applyConfig(nextConfig);
  closeEditor();
};

const handleEditorReset = () => {
  saveConfig(defaultConfig);
  applyConfig(defaultConfig);
};

const blockKeys = (event) => {
  const editorOpen = editor && editor.dataset.open === "true";

  if (editorOpen && event.key === "Escape") {
    event.preventDefault();
    closeEditor();
    return;
  }

  if (editorOpen && isEditorTarget(event.target)) {
    return;
  }

  if (event.key === "Escape") {
    event.preventDefault();
    event.stopPropagation();
    return;
  }

  if ((event.ctrlKey || event.metaKey) && blockedCombos.has(event.key.toLowerCase())) {
    event.preventDefault();
    event.stopPropagation();
  }
};

const init = async () => {
  if (!acknowledgeButton || !letterContainer || !ackInput) {
    return;
  }

  const storedConfig = loadConfig();
  applyConfig(storedConfig);
  startIntro();

  letterContainer.addEventListener("scroll", handleScroll, { passive: true });
  ackInput.addEventListener("input", handleAcknowledgementInput);
  acknowledgeButton.addEventListener("click", handleAcknowledge);

  if (editToggle) {
    editToggle.addEventListener("click", () => {
      fillEditorFields();
      openEditor();
    });
  }
  if (editorClose) {
    editorClose.addEventListener("click", closeEditor);
  }
  if (editorCancel) {
    editorCancel.addEventListener("click", closeEditor);
  }
  if (editorSave) {
    editorSave.addEventListener("click", handleEditorSave);
  }
  if (editorReset) {
    editorReset.addEventListener("click", handleEditorReset);
  }

  document.addEventListener("contextmenu", blockEvent);
  document.addEventListener("copy", blockEvent);
  document.addEventListener("cut", blockEvent);
  document.addEventListener("paste", blockEvent);
  document.addEventListener("selectstart", blockEvent);
  document.addEventListener("dragstart", blockEvent);
  document.addEventListener("keydown", blockKeys, true);

  await appWindow.onCloseRequested((event) => {
    if (!acknowledged) {
      event.preventDefault();
    }
  });
};

init();
