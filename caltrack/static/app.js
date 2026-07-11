const state = { data: null, photoEntryId: null };

const $ = (selector) => document.querySelector(selector);
const esc = (value) => String(value ?? "").replace(/[&<>'"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]));
const number = (value, digits = 0) => new Intl.NumberFormat("es-ES", {maximumFractionDigits: digits}).format(Number(value || 0));
const dayName = (iso, long = false) => new Intl.DateTimeFormat("es-ES", long ? {weekday:"long", day:"numeric", month:"short"} : {weekday:"short", day:"numeric"}).format(new Date(`${iso}T12:00:00`));
const time = (iso) => iso?.slice(11, 16) || "";
const mealLabel = value => ({breakfast:"desayuno", lunch:"comida", dinner:"cena", snack:"merienda"}[value] || "");
const photoUrl = value => value;

async function api(path, options = {}) {
  return window.localCaltrack.route(path, options);
}

let toastTimer;
function toast(message, error = false) {
  const el = $("#toast");
  el.textContent = message;
  el.className = `toast${error ? " error" : ""}`;
  el.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.hidden = true; }, 3500);
  if (navigator.vibrate) navigator.vibrate(error ? [35, 45, 35] : 25);
}

function setBusy(form, busy) {
  form.querySelectorAll("button,input,select").forEach(el => el.disabled = busy);
}

async function load() {
  $("#syncState").textContent = "cargando";
  try {
    state.data = await api("/api/dashboard?days=7");
    render();
    $("#syncState").textContent = "guardado en este dispositivo";
    if (!state.data.settings.configured) $("#settingsDialog").showModal();
  } catch (error) {
    $("#syncState").textContent = "sin conexión";
    toast(error.message, true);
  }
}

function render() {
  const {settings, days, today, analysis} = state.data;
  const goal = Math.round(settings.maintenance_kcal - settings.deficit_kcal);
  $("#goalLine").textContent = `objetivo ${number(goal)} kcal · ${number(settings.weight_kg * settings.protein_g_per_kg)} g proteína`;
  renderChart($("#calorieChart"), days, "calories", "maintenance_kcal", "target_kcal", false);
  renderChart($("#proteinChart"), days, "protein_g", "protein_goal_g", "protein_goal_g", true);
  $("#todayCard").innerHTML = dayCard(today, true);
  wireEntryActions($("#todayCard"));
  renderCoach(analysis);
  $("#history").innerHTML = days.slice(0, -1).reverse().map(historyDay).join("");
  populateSettings(settings);
}

function renderChart(container, days, valueKey, maxKey, targetKey, protein) {
  container.innerHTML = days.map((day, index) => {
    const ceiling = Math.max(Number(day[maxKey]) * 1.12, Number(day[valueKey]), 1);
    const fill = Math.min(100, Number(day[valueKey]) / ceiling * 100);
    const target = Math.min(100, Number(day[targetKey]) / ceiling * 100);
    const failed = protein ? (day.complete && !day.protein_hit) : Number(day[valueKey]) > Number(day.target_kcal);
    const incomplete = !day.complete && index === days.length - 1;
    const colorClass = failed ? "over" : (incomplete && protein ? "incomplete" : "");
    return `<div class="bar-column" title="${esc(day.day)}: ${number(day[valueKey], protein ? 1 : 0)}">
      <div class="bar-zone">
        <div class="bar-track">
          <i class="target-line" style="bottom:${target}%"></i>
          <span class="bar-value" style="bottom:calc(${fill}% + 7px)">${number(day[valueKey], protein ? 0 : 0)}</span>
          <i class="bar-fill ${colorClass}" style="height:${fill}%"></i>
        </div>
      </div>
      <div class="bar-day">${esc(dayName(day.day))}</div>
    </div>`;
  }).join("");
}

function dayCard(day, expanded) {
  const caloriePercent = Math.min(100, day.calories / Math.max(day.maintenance_kcal, 1) * 100);
  const targetPercent = Math.min(100, day.target_kcal / Math.max(day.maintenance_kcal, 1) * 100);
  const proteinPercent = Math.min(100, day.protein_g / Math.max(day.protein_goal_g, 1) * 100);
  const over = day.calories > day.target_kcal;
  const deficitClass = day.deficit_kcal >= state.data.settings.deficit_kcal ? "good" : "warn";
  const exercises = day.exercises.map(exercise => `<div class="workout"><strong>🏋 ${esc(exercise.name)} · ${number(exercise.duration_min)} min · ~${number(exercise.calories_burned)} kcal</strong><span>${esc(exercise.note || "Entrenamiento añadido al mantenimiento del día")}</span></div>`).join("");
  const photos = day.entries.filter(entry => entry.photo_path).map(entry => `<img src="${esc(photoUrl(entry.photo_path))}" alt="${esc(entry.name)}" loading="lazy">`).join("");
  return `<div class="day-head">
      <div class="day-title"><h2>${esc(dayName(day.day, true))}</h2><span class="pill">${day.exercises.length ? "ENTRENO" : "DÍA BASE"}</span><span class="muted">⚖ ${number(day.weight_kg, 2)} kg</span></div>
      <div class="day-total"><strong class="${over ? "over" : ""}">${number(day.calories)}</strong> / ${number(day.target_kcal)} kcal<small>objetivo ${number(day.target_kcal)}</small></div>
    </div>
    <div class="progress-wrap"><div class="progress"><span class="${over ? "over" : ""}" style="width:${caloriePercent}%"></span></div><i class="target-marker" style="left:${targetPercent}%"></i></div>
    <div class="progress-labels"><span>${number(day.calories)} comido</span><span>mantenimiento ${number(day.maintenance_kcal)}</span></div>
    <div class="progress slim"><span class="blue" style="width:${proteinPercent}%"></span></div>
    <div class="progress-labels"><span>${number(day.protein_g, 1)} g proteína</span><span>objetivo ${number(day.protein_goal_g)} g ${day.protein_hit ? "✓" : ""}</span></div>
    <p class="summary-line">${day.items} ${day.items === 1 ? "entrada" : "entradas"} · <span class="${deficitClass}">déficit ${number(day.deficit_kcal)} kcal ${day.deficit_kcal >= state.data.settings.deficit_kcal ? "✓" : ""}</span></p>
    ${exercises}
    <div class="entries">${day.entries.length ? day.entries.map(entry => entryRow(entry, day.target_kcal, expanded)).join("") : `<div class="empty">Tu día empieza aquí. Registra lo primero que comas o bebas.</div>`}</div>
    ${photos ? `<div class="photos">${photos}</div>` : ""}
    ${expanded ? `<div class="day-tools"><button class="secondary" data-open-tools>+ peso o entreno</button></div>` : ""}`;
}

function entryRow(entry, target, actions = true) {
  const share = Math.round(entry.calories / Math.max(target, 1) * 100);
  const qty = entry.quantity ? `${number(entry.quantity, 1)} ${esc(entry.unit)}` : "";
  return `<div class="entry" data-entry-id="${entry.id}">
    <div class="entry-meal">${esc(mealLabel(entry.meal))}</div>
    <div class="entry-name">${esc(entry.name)} <span>${qty}${qty && time(entry.eaten_at) ? " · " : ""}${esc(time(entry.eaten_at))}</span></div>
    <div class="entry-share"><span>${share}%</span><i class="mini-track"><i style="width:${Math.min(100, share)}%"></i></i></div>
    <div class="entry-macros">${number(entry.protein_g, 1)}g P · ${number(entry.calories)} kcal</div>
    ${actions ? `<div class="entry-actions"><button class="tiny-button photo-button" aria-label="Añadir foto" title="Añadir foto">▧</button><button class="tiny-button delete-button" aria-label="Borrar" title="Borrar">×</button></div>` : ""}
  </div>`;
}

function renderCoach(analysis) {
  $("#coachScore").textContent = analysis.score;
  $("#coachTitle").textContent = analysis.headline;
  $("#coachSummary").textContent = analysis.summary;
  $("#coachObservations").innerHTML = analysis.observations.map(item => `<li>${esc(item)}</li>`).join("");
}

function historyDay(day) {
  const over = day.calories > day.target_kcal;
  const status = day.items ? (over ? "over" : "good") : "muted";
  return `<details class="history-day"><summary><strong>${esc(dayName(day.day, true))}</strong><span>${number(day.protein_g)} / ${number(day.protein_goal_g)} g proteína</span><strong class="${status}">${number(day.calories)} / ${number(day.target_kcal)} kcal</strong></summary><div class="history-content">${day.entries.length ? day.entries.map(entry => entryRow(entry, day.target_kcal, false)).join("") : `<p class="muted">Sin entradas.</p>`}</div></details>`;
}

function wireEntryActions(root) {
  root.querySelectorAll(".delete-button").forEach(button => button.addEventListener("click", async () => {
    const entry = button.closest(".entry");
    if (!confirm("¿Borrar esta entrada?")) return;
    try { await api(`/api/food/${entry.dataset.entryId}`, {method:"DELETE"}); toast("Entrada borrada"); await load(); }
    catch (error) { toast(error.message, true); }
  }));
  root.querySelectorAll(".photo-button").forEach(button => button.addEventListener("click", () => {
    state.photoEntryId = Number(button.closest(".entry").dataset.entryId);
    $("#photoInput").click();
  }));
  root.querySelector("[data-open-tools]")?.addEventListener("click", () => $("#toolsDialog").showModal());
}

function populateSettings(settings) {
  const form = $("#settingsForm");
  ["name","weight_kg","maintenance_kcal","deficit_kcal","protein_g_per_kg"].forEach(key => { form.elements[key].value = settings[key]; });
  previewPlan();
}

function previewPlan() {
  const form = $("#settingsForm");
  const maintenance = Number(form.elements.maintenance_kcal.value || 0);
  const deficit = Number(form.elements.deficit_kcal.value || 0);
  const protein = Number(form.elements.weight_kg.value || 0) * Number(form.elements.protein_g_per_kg.value || 0);
  $("#planPreview").innerHTML = `Día base: <strong>${number(maintenance - deficit)} kcal</strong> · mantenimiento ${number(maintenance)} · <strong>${number(protein)} g proteína</strong>`;
}

$("#quickAddForm").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const text = $("#quickAddInput").value.trim();
  setBusy(form, true);
  try {
    const result = await api("/api/food", {method:"POST", body:JSON.stringify({text})});
    $("#quickAddInput").value = "";
    const assumption = $("#assumption");
    assumption.textContent = result.entry.estimated ? `Estimación usada: ${result.entry.assumption}. Puedes borrarla y registrar macros exactos si hace falta.` : "Macros exactos guardados.";
    assumption.hidden = false;
    toast(`${result.entry.name}: ${number(result.entry.calories)} kcal, ${number(result.entry.protein_g, 1)} g proteína`);
    await load();
  } catch (error) { toast(error.message, true); }
  finally { setBusy(form, false); $("#quickAddInput").focus(); }
});

document.querySelectorAll("[data-example]").forEach(button => button.addEventListener("click", () => { $("#quickAddInput").value = button.dataset.example; $("#quickAddInput").focus(); }));

$("#manualForm").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const data = Object.fromEntries(new FormData(form));
  data.calories = Number(data.calories); data.protein_g = Number(data.protein_g);
  setBusy(form, true);
  try { await api("/api/food", {method:"POST", body:JSON.stringify(data)}); form.reset(); toast("Entrada exacta guardada"); await load(); }
  catch (error) { toast(error.message, true); }
  finally { setBusy(form, false); }
});

$("#settingsButton").addEventListener("click", () => $("#settingsDialog").showModal());
$("#settingsForm").addEventListener("input", previewPlan);
$("#settingsForm").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const data = Object.fromEntries(new FormData(form));
  ["weight_kg","maintenance_kcal","deficit_kcal","protein_g_per_kg"].forEach(key => data[key] = Number(data[key]));
  setBusy(form, true);
  try { await api("/api/settings", {method:"POST", body:JSON.stringify(data)}); $("#settingsDialog").close(); toast("Plan guardado"); await load(); }
  catch (error) { toast(error.message, true); }
  finally { setBusy(form, false); }
});

$("#weightForm").addEventListener("submit", async event => {
  event.preventDefault(); const form = event.currentTarget;
  try { await api("/api/weight", {method:"POST", body:JSON.stringify({weight_kg:Number(form.elements.weight_kg.value)})}); $("#toolsDialog").close(); form.reset(); toast("Peso guardado"); await load(); }
  catch (error) { toast(error.message, true); }
});

$("#exerciseForm").addEventListener("submit", async event => {
  event.preventDefault(); const form = event.currentTarget;
  const body = {name:form.elements.name.value, duration_min:Number(form.elements.duration_min.value), calories_burned:Number(form.elements.calories_burned.value)};
  try { await api("/api/exercise", {method:"POST", body:JSON.stringify(body)}); $("#toolsDialog").close(); form.reset(); toast("Entrenamiento guardado"); await load(); }
  catch (error) { toast(error.message, true); }
});

$("#askForm").addEventListener("submit", async event => {
  event.preventDefault(); const form = event.currentTarget; setBusy(form, true);
  try { const result = await api("/api/ask", {method:"POST", body:JSON.stringify({question:$("#askInput").value})}); $("#answer").textContent = result.answer; $("#answer").hidden = false; }
  catch (error) { toast(error.message, true); }
  finally { setBusy(form, false); }
});

$("#photoInput").addEventListener("change", event => {
  const file = event.target.files[0]; if (!file || !state.photoEntryId) return;
  if (file.size > 8 * 1024 * 1024) { toast("La foto supera 8 MB", true); return; }
  const reader = new FileReader();
  reader.onload = async () => {
    try { await api("/api/photo", {method:"POST", body:JSON.stringify({entry_id:state.photoEntryId, data_url:reader.result})}); toast("Foto añadida"); await load(); }
    catch (error) { toast(error.message, true); }
    finally { event.target.value = ""; state.photoEntryId = null; }
  };
  reader.readAsDataURL(file);
});

function downloadFile(name, content, type) {
  const url = URL.createObjectURL(new Blob([content], {type}));
  const link = document.createElement("a");
  link.href = url; link.download = name; document.body.appendChild(link); link.click(); link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

$("#exportLink").addEventListener("click", async event => {
  event.preventDefault();
  downloadFile(`caltrack-${new Date().toISOString().slice(0,10)}.csv`, await window.localCaltrack.exportCSV(), "text/csv;charset=utf-8");
  toast("CSV exportado");
});

$("#backupButton").addEventListener("click", async () => {
  const backup = await window.localCaltrack.backup();
  downloadFile(`caltrack-copia-${new Date().toISOString().slice(0,10)}.json`, JSON.stringify(backup), "application/json");
  toast("Copia privada descargada");
});

$("#restoreButton").addEventListener("click", () => $("#restoreInput").click());
$("#restoreInput").addEventListener("change", async event => {
  const file = event.target.files[0]; if (!file) return;
  try {
    const data = JSON.parse(await file.text());
    if (!confirm("Esto sustituirá los datos guardados en este dispositivo. ¿Continuar?")) return;
    await window.localCaltrack.restore(data); $("#settingsDialog").close(); toast("Copia restaurada"); await load();
  } catch (error) { toast(error.message, true); }
  finally { event.target.value = ""; }
});

let installPrompt;
window.addEventListener("beforeinstallprompt", event => { event.preventDefault(); installPrompt = event; $("#installButton").hidden = false; });
if (!window.matchMedia("(display-mode: standalone)").matches && !window.navigator.standalone) $("#installButton").hidden = false;
$("#installButton").addEventListener("click", async () => {
  if (installPrompt) { installPrompt.prompt(); await installPrompt.userChoice; installPrompt = null; $("#installButton").hidden = true; }
  else toast("En iPhone: Compartir y después Añadir a pantalla de inicio");
});

if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js", {scope:"./"}).catch(() => {});
load();
