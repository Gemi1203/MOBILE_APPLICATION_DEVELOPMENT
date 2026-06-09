const SACCO_STORAGE_KEY = "saccoDataV1";
const SACCO_USER_KEY = "saccoSessionV1";

function loadData() {
  const base = {
    profile: { fullName: "", memberNumber: "", phone: "" },
    savings: [],
    loans: []
  };
  try {
    const parsed = JSON.parse(localStorage.getItem(SACCO_STORAGE_KEY) || "{}");
    return {
      ...base,
      ...parsed,
      profile: { ...base.profile, ...(parsed.profile || {}) },
      savings: Array.isArray(parsed.savings) ? parsed.savings : [],
      loans: Array.isArray(parsed.loans) ? parsed.loans : []
    };
  } catch {
    return base;
  }
}

function saveData(data) {
  localStorage.setItem(SACCO_STORAGE_KEY, JSON.stringify(data));
}

function saveSession(user) {
  localStorage.setItem(SACCO_USER_KEY, JSON.stringify(user));
}

function getSession() {
  try {
    return JSON.parse(localStorage.getItem(SACCO_USER_KEY) || "null");
  } catch {
    return null;
  }
}

function requireSession() {
  if (!getSession()) {
    window.location.href = "auth.html";
  }
}

function signOut() {
  localStorage.removeItem(SACCO_USER_KEY);
  window.location.href = "auth.html";
}

function money(v) {
  return new Intl.NumberFormat("en-KE", { style: "currency", currency: "KES", maximumFractionDigits: 0 }).format(Number(v || 0));
}

function formatDate(v) {
  return new Date(v).toLocaleDateString("en-KE", { month: "short", day: "numeric", year: "numeric" });
}

async function initParseSdk() {
  if (typeof Parse === "undefined") return;
  if (window.__saccoParseReady) return;

  const appId = localStorage.getItem("b4a_app_id") || "";
  const jsKey = localStorage.getItem("b4a_js_key") || "";
  const serverURL = localStorage.getItem("b4a_server_url") || "https://parseapi.back4app.com/";

  if (!appId || !jsKey) return;
  Parse.initialize(appId, jsKey);
  Parse.serverURL = serverURL;
  window.__saccoParseReady = true;
}

async function saveToBack4App(className, fields) {
  try {
    await initParseSdk();
    if (!window.__saccoParseReady) return false;
    const Obj = Parse.Object.extend(className);
    const obj = new Obj();
    Object.entries(fields).forEach(([k, v]) => obj.set(k, v));
    await obj.save();
    return true;
  } catch {
    return false;
  }
}