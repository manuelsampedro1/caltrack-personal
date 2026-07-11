class LocalCaltrackStore {
  constructor() {
    this.name = "caltrack-mobile";
    this.version = 1;
    this.defaults = {
      name: "", weight_kg: 75, maintenance_kcal: 2300, deficit_kcal: 500,
      protein_g_per_kg: 2, timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      locale: "es", configured: false
    };
    this.foods = [
      ["chicken breast", ["chicken breast","chicken","pechuga de pollo","pechuga","pollo"], 165, 31, 150],
      ["turkey", ["turkey","pechuga de pavo","pavo"], 135, 29, 150],
      ["lean beef", ["lean beef","beef","carne picada","ternera","vacuno"], 200, 26, 150],
      ["pork", ["pork","lomo de cerdo","cerdo"], 242, 27, 150],
      ["salmon", ["salmon fillet","salmon","salmón"], 208, 20, 150],
      ["tuna", ["tuna","atun al natural","atún al natural","atun","atún"], 116, 26, 120],
      ["sardines", ["sardines","sardinas"], 208, 25, 100],
      ["egg whites", ["egg whites","claras de huevo","claras"], 52, 11, 150],
      ["egg", ["eggs","egg","huevos","huevo"], 143, 13, 60],
      ["greek yogurt", ["greek yogurt","yogur griego","yogurt","yoghurt","yogur","yopro"], 73, 10, 250],
      ["cottage cheese", ["cottage cheese","queso fresco batido","queso cottage"], 98, 11, 200],
      ["milk", ["milk","leche"], 60, 3.2, 250],
      ["whey protein", ["protein shake","whey","batido de proteina","batido de proteína","proteina en polvo","proteína en polvo"], 400, 80, 30],
      ["rice cooked", ["cooked rice","arroz cocido","rice","arroz"], 130, 2.7, 150],
      ["potato", ["potatoes","potato","patatas","patata"], 87, 1.9, 250],
      ["oats", ["oatmeal","oats","avena"], 389, 17, 60],
      ["bread", ["toast","bread","tostada","pan"], 265, 9, 50],
      ["pasta cooked", ["cooked pasta","pasta cocida","pasta"], 157, 5.8, 180],
      ["banana", ["banana","platano","plátano"], 89, 1.1, 120],
      ["apple", ["apple","manzana"], 52, .3, 180],
      ["avocado", ["avocado","aguacate"], 160, 2, 100],
      ["lettuce", ["lettuce","lechuga"], 15, 1.4, 100],
      ["vegetables", ["vegetables","veggies","verduras","vegetales"], 50, 2.5, 200],
      ["olive oil", ["olive oil","aceite de oliva","aceite"], 884, 0, 10],
      ["dark chocolate", ["dark chocolate","chocolate negro","chocolate"], 598, 7.8, 20],
      ["coffee", ["black coffee","cafe solo","café solo","coffee","cafe","café"], 2, .3, 250],
      ["tea", ["hibiscus tea","infusion","infusión","tea","te","té"], 1, 0, 250]
    ];
  }

  open() {
    if (this.database) return this.database;
    this.database = new Promise((resolve, reject) => {
      const request = indexedDB.open(this.name, this.version);
      request.onupgradeneeded = () => {
        const db = request.result;
        if (!db.objectStoreNames.contains("meta")) db.createObjectStore("meta", {keyPath:"id"});
        if (!db.objectStoreNames.contains("food")) db.createObjectStore("food", {keyPath:"id", autoIncrement:true});
        if (!db.objectStoreNames.contains("exercise")) db.createObjectStore("exercise", {keyPath:"id", autoIncrement:true});
        if (!db.objectStoreNames.contains("weights")) db.createObjectStore("weights", {keyPath:"id", autoIncrement:true});
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    return this.database;
  }

  async action(store, mode, operation) {
    const db = await this.open();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(store, mode);
      const request = operation(tx.objectStore(store));
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  getAll(store) { return this.action(store, "readonly", object => object.getAll()); }
  put(store, value) { return this.action(store, "readwrite", object => object.put(value)); }
  add(store, value) { return this.action(store, "readwrite", object => object.add(value)); }
  remove(store, id) { return this.action(store, "readwrite", object => object.delete(id)); }

  localDay(value = new Date()) {
    const date = value instanceof Date ? value : new Date(value);
    const pad = n => String(n).padStart(2, "0");
    return `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())}`;
  }

  localNow() {
    const d = new Date();
    const pad = n => String(n).padStart(2, "0");
    return `${this.localDay(d)}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  }

  normalize(value) { return value.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, ""); }

  async settings() {
    const saved = await this.action("meta", "readonly", store => store.get("settings"));
    return {...this.defaults, ...(saved || {})};
  }

  async configure(values) {
    const current = await this.settings();
    const next = {...current, ...values, id:"settings", configured:true};
    for (const key of ["weight_kg","maintenance_kcal","deficit_kcal","protein_g_per_kg"]) {
      next[key] = Number(next[key]);
      if (!(next[key] > 0)) throw new Error(`${key} debe ser mayor que cero`);
    }
    if (next.deficit_kcal > 1000) throw new Error("Un déficit superior a 1.000 kcal requiere supervisión profesional");
    await this.put("meta", next);
    return next;
  }

  mealFromText(text) {
    const simple = this.normalize(text);
    for (const [meal, names] of Object.entries({breakfast:["breakfast","desayuno"],lunch:["lunch","comida","almuerzo"],dinner:["dinner","cena"],snack:["snack","merienda","tentempie"]})) {
      if (names.some(name => new RegExp(`\\b${name}\\b`).test(simple))) return meal;
    }
    return "";
  }

  parseFood(text) {
    const raw = text.trim();
    if (!raw) throw new Error("Escribe un alimento, por ejemplo: 200 g de pollo");
    const simple = this.normalize(raw);
    const numberFor = regex => { const found = simple.match(regex); return found ? Number(found[1].replace(",",".")) : null; };
    const explicitCalories = numberFor(/(\d+(?:[.,]\d+)?)\s*(?:kcal|calorias|calories|cal)\b/i);
    const explicitProtein = numberFor(/(\d+(?:[.,]\d+)?)\s*(?:g\s*)?(?:p\b|proteina\b|protein\b)/i);
    const quantityMatch = simple.match(/(\d+(?:[.,]\d+)?)\s*(kg|g|gr|gramos?|ml|l|unidad(?:es)?|uds?|x)\b/i);
    let amount = quantityMatch ? Number(quantityMatch[1].replace(",",".")) : null;
    let unit = quantityMatch ? quantityMatch[2] : "";
    if (amount === null) {
      const leading = simple.match(/^\s*(\d+(?:[.,]\d+)?)\s+/);
      if (leading) { amount = Number(leading[1].replace(",",".")); unit = "unit"; }
    }
    let matched = null, matchedAlias = "";
    for (const food of this.foods) {
      for (const alias of food[1]) {
        const normalized = this.normalize(alias);
        if (new RegExp(`\\b${normalized.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")}\\b`).test(simple) && normalized.length > matchedAlias.length) {
          matched = food; matchedAlias = normalized;
        }
      }
    }
    if (matched) {
      let grams = matched[4];
      if (amount !== null) {
        if (unit === "kg" || unit === "l") grams = amount * 1000;
        else if (["g","gr","gramo","gramos","ml"].includes(unit)) grams = amount;
        else grams = amount * matched[4];
      }
      return {
        name:matched[0], quantity:Math.round(grams*10)/10, unit:"g",
        calories:Math.round(explicitCalories ?? matched[2]*grams/100),
        protein_g:Math.round((explicitProtein ?? matched[3]*grams/100)*10)/10,
        estimated:explicitCalories === null || explicitProtein === null,
        assumption:`${grams} g, referencia por 100 g`
      };
    }
    if (explicitCalories !== null) {
      let name = simple.replace(/\d+(?:[.,]\d+)?\s*(?:kcal|calorias|calories|cal)\b/g, "")
        .replace(/\d+(?:[.,]\d+)?\s*(?:g\s*)?(?:p\b|proteina\b|protein\b)/g, "")
        .replace(/^\s*\d+(?:[.,]\d+)?\s*(?:kg|g|gr|gramos?|ml|l)\b/, "").replace(/\s+/g," ").trim();
      return {name:name || "alimento", quantity:amount, unit, calories:Math.round(explicitCalories), protein_g:Math.round((explicitProtein || 0)*10)/10, estimated:false, assumption:"macros indicados"};
    }
    throw new Error("No conozco ese alimento. Añade sus macros, por ejemplo: 'lasaña 420 kcal 24 g proteína'.");
  }

  async addFood(body) {
    const parsed = body.text ? this.parseFood(body.text) : {...body, estimated:false, assumption:"macros indicados"};
    const entry = {
      eaten_at:body.eaten_at || this.localNow(), meal:body.meal || this.mealFromText(body.text || ""),
      name:String(parsed.name || "").trim(), quantity:parsed.quantity ?? null, unit:parsed.unit || "",
      calories:Number(parsed.calories || 0), protein_g:Number(parsed.protein_g || 0), source:"mobile",
      note:parsed.note || "", photo_path:parsed.photo_path || null, created_at:this.localNow()
    };
    if (!entry.name) throw new Error("El alimento necesita un nombre");
    if (entry.calories < 0 || entry.protein_g < 0) throw new Error("Calorías y proteína no pueden ser negativas");
    entry.id = await this.add("food", entry);
    return {...entry, estimated:parsed.estimated, assumption:parsed.assumption};
  }

  async updateFood(id, values) {
    const all = await this.getAll("food");
    const item = all.find(entry => entry.id === Number(id));
    if (!item) throw new Error("Entrada no encontrada");
    Object.assign(item, values);
    await this.put("food", item);
    return item;
  }

  async addExercise(body) {
    const item = {performed_at:body.performed_at || this.localNow(), name:String(body.name || "").trim(), duration_min:Number(body.duration_min || 0), calories_burned:Number(body.calories_burned || 0), note:body.note || ""};
    if (!item.name) throw new Error("El entrenamiento necesita un nombre");
    item.id = await this.add("exercise", item); return item;
  }

  async addWeight(body) {
    const item = {measured_at:body.measured_at || this.localNow(), weight_kg:Number(body.weight_kg), note:body.note || ""};
    if (!(item.weight_kg > 0)) throw new Error("El peso debe ser mayor que cero");
    item.id = await this.add("weights", item);
    const settings = await this.settings(); await this.configure({...settings, weight_kg:item.weight_kg});
    return item;
  }

  async daySummary(day, collections = null) {
    const [settings, foods, exercises, weights] = collections || await Promise.all([this.settings(),this.getAll("food"),this.getAll("exercise"),this.getAll("weights")]);
    const entries = foods.filter(item => item.eaten_at.slice(0,10) === day).sort((a,b) => a.eaten_at.localeCompare(b.eaten_at));
    const training = exercises.filter(item => item.performed_at.slice(0,10) === day).sort((a,b) => a.performed_at.localeCompare(b.performed_at));
    const knownWeights = weights.filter(item => item.measured_at.slice(0,10) <= day).sort((a,b) => b.measured_at.localeCompare(a.measured_at));
    const weight = knownWeights[0]?.weight_kg || settings.weight_kg;
    const calories = entries.reduce((sum,item) => sum + Number(item.calories), 0);
    const protein = entries.reduce((sum,item) => sum + Number(item.protein_g), 0);
    const maintenance = Number(settings.maintenance_kcal) + training.reduce((sum,item) => sum + Number(item.calories_burned), 0);
    const target = maintenance - Number(settings.deficit_kcal);
    const proteinGoal = weight * Number(settings.protein_g_per_kg);
    return {day,calories:Math.round(calories),protein_g:Math.round(protein*10)/10,maintenance_kcal:Math.round(maintenance),target_kcal:Math.round(target),protein_goal_g:Math.round(proteinGoal),deficit_kcal:Math.round(maintenance-calories),remaining_kcal:Math.round(target-calories),items:entries.length,entries,exercises:training,weight_kg:Math.round(weight*100)/100,target_hit:calories<=target,protein_hit:protein>=proteinGoal,complete:day<this.localDay()};
  }

  dateMinus(day, offset) { const d = new Date(`${day}T12:00:00`); d.setDate(d.getDate()-offset); return this.localDay(d); }

  analysisFrom(days, rangeDays) {
    const logged = days.filter(item => item.items > 0);
    if (!logged.length) return {headline:"Aún no hay suficiente información",summary:"Registra tu primera comida. Con tres días podré señalar patrones útiles.",observations:[],score:0};
    const avgCalories = logged.reduce((s,d)=>s+d.calories,0)/logged.length;
    const avgDeficit = logged.reduce((s,d)=>s+d.deficit_kcal,0)/logged.length;
    const proteinDays = logged.filter(d=>d.protein_hit).length;
    const targetDays = logged.filter(d=>d.target_hit).length;
    const proteinRate = proteinDays/logged.length, targetRate = targetDays/logged.length;
    const score = Math.round((proteinRate+targetRate)*50), observations=[];
    observations.push(proteinRate < .7 ? `La proteína llegó al objetivo ${proteinDays} de ${logged.length} días. Prioriza una fuente magra en la primera mitad del día.` : `La proteína llegó al objetivo ${proteinDays} de ${logged.length} días, una base sólida para mantener masa muscular.`);
    if (avgDeficit > 850) observations.push(`El déficit medio registrado es de ${Math.round(avgDeficit)} kcal, bastante agresivo. Revisa hambre, energía y recuperación.`);
    else if (avgDeficit < 200) observations.push(`El déficit medio es de ${Math.round(avgDeficit)} kcal. Si el peso no baja durante dos semanas, revisa porciones y mantenimiento.`);
    else observations.push(`El déficit medio es de ${Math.round(avgDeficit)} kcal, dentro de un rango moderado para el objetivo configurado.`);
    if (logged.length < rangeDays*.7) observations.push(`Hay datos en ${logged.length} de ${rangeDays} días. Registrar también los días imperfectos mejorará mucho el análisis.`);
    const weekly = avgDeficit*7/7700;
    return {headline:`${score}% de adherencia en ${logged.length} días`,summary:`Media: ${Math.round(avgCalories)} kcal, déficit ${Math.round(avgDeficit)} kcal, proteína cumplida ${Math.round(proteinRate*100)}%. Ritmo teórico: ${weekly.toFixed(2)} kg/semana.`,observations,score,logged_days:logged.length,range_days:rangeDays,avg_calories:Math.round(avgCalories),avg_deficit:Math.round(avgDeficit),protein_rate:Math.round(proteinRate*100),target_rate:Math.round(targetRate*100),theoretical_kg_week:Math.round(weekly*100)/100};
  }

  async dashboard(count = 7) {
    const collections = await Promise.all([this.settings(),this.getAll("food"),this.getAll("exercise"),this.getAll("weights")]);
    const today = this.localDay();
    const days = await Promise.all(Array.from({length:count},(_,i)=>this.daySummary(this.dateMinus(today,count-1-i),collections)));
    const analysisDays = await Promise.all(Array.from({length:14},(_,i)=>this.daySummary(this.dateMinus(today,13-i),collections)));
    return {settings:collections[0],days,today:days[days.length-1],analysis:this.analysisFrom(analysisDays,14)};
  }

  async answer(question) {
    const data = await this.dashboard(14), a = data.analysis, q = this.normalize(question || "");
    if (!a.logged_days) return a.summary;
    if (/prote|musculo/.test(q)) return `Has cumplido proteína el ${a.protein_rate}% de los días registrados. ${a.observations[0]}`;
    if (/peso|weight|ritmo/.test(q)) return `Con el déficit registrado, el ritmo teórico es ${a.theoretical_kg_week.toFixed(2)} kg por semana. Compáralo con la tendencia real de 2 a 4 semanas.`;
    if (/mejor|improve|cambiar|change/.test(q)) return `Lo más útil ahora: ${a.observations.join(" ")}`;
    return `${a.headline}. ${a.summary} ${a.observations.join(" ")}`;
  }

  async backup() {
    const [settings, food, exercise, weights] = await Promise.all([this.settings(),this.getAll("food"),this.getAll("exercise"),this.getAll("weights")]);
    return {format:"caltrack-backup",version:1,exported_at:new Date().toISOString(),settings,food,exercise,weights};
  }

  async restore(data) {
    if (data?.format !== "caltrack-backup" || data.version !== 1) throw new Error("Esta copia no tiene un formato válido de Caltrack");
    const db = await this.open();
    for (const storeName of ["meta","food","exercise","weights"]) await new Promise((resolve,reject)=>{const tx=db.transaction(storeName,"readwrite"),request=tx.objectStore(storeName).clear();request.onsuccess=()=>resolve();request.onerror=()=>reject(request.error);});
    await this.put("meta", {...this.defaults,...data.settings,id:"settings"});
    for (const item of data.food || []) await this.put("food", item);
    for (const item of data.exercise || []) await this.put("exercise", item);
    for (const item of data.weights || []) await this.put("weights", item);
  }

  async exportCSV() {
    const rows = await this.getAll("food"), fields=["id","eaten_at","meal","name","quantity","unit","calories","protein_g","source","note"];
    const cell=value=>`"${String(value??"").replace(/"/g,'""')}"`;
    return [fields.join(","),...rows.sort((a,b)=>a.eaten_at.localeCompare(b.eaten_at)).map(row=>fields.map(key=>cell(row[key])).join(","))].join("\n");
  }

  async route(path, options = {}) {
    const method = options.method || "GET", body = options.body ? JSON.parse(options.body) : {};
    if (path.startsWith("/api/dashboard")) return this.dashboard(7);
    if (path === "/api/settings" && method === "POST") return this.configure(body);
    if (path === "/api/food" && method === "POST") return {ok:true,entry:await this.addFood(body)};
    if (path === "/api/exercise" && method === "POST") return {ok:true,exercise:await this.addExercise(body)};
    if (path === "/api/weight" && method === "POST") return {ok:true,weight:await this.addWeight(body)};
    if (path === "/api/ask" && method === "POST") return {ok:true,answer:await this.answer(body.question)};
    if (path === "/api/photo" && method === "POST") { await this.updateFood(body.entry_id,{photo_path:body.data_url}); return {ok:true,path:body.data_url}; }
    const remove = path.match(/^\/api\/food\/(\d+)$/);
    if (remove && method === "DELETE") { await this.remove("food",Number(remove[1])); return {ok:true}; }
    throw new Error("Acción no disponible");
  }
}

window.localCaltrack = new LocalCaltrackStore();

