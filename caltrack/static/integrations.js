class CaltrackIntegrations {
  constructor(fetcher = window.fetch.bind(window)) {
    this.fetcher = fetcher;
    this.xaiBase = "https://api.x.ai/v1";
    this.hevyBase = "https://api.hevyapp.com/v1";
  }

  async request(url, options, service) {
    let response;
    try {
      response = await this.fetcher(url, options);
    } catch (_) {
      throw new Error(`No se pudo conectar con ${service}. Revisa la conexión y vuelve a intentarlo.`);
    }
    if (!response.ok) {
      let message = "";
      try {
        const payload = await response.json();
        message = payload?.error?.message || payload?.message || "";
      } catch (_) {}
      if (response.status === 401) message = `La clave de ${service} no es válida.`;
      if (response.status === 403 && service === "Hevy") message = "La API oficial de Hevy requiere una cuenta Pro y una clave activa.";
      throw new Error(message || `${service} devolvió el código ${response.status}.`);
    }
    return response;
  }

  async validateXAI(apiKey) {
    if (!String(apiKey || "").trim()) throw new Error("Añade una clave de xAI.");
    await this.request(`${this.xaiBase}/models`, {
      headers:{Authorization:`Bearer ${String(apiKey).trim()}`, Accept:"application/json"}
    }, "xAI");
    return true;
  }

  foodSchema() {
    const number = {type:"number", minimum:0};
    return {
      type:"object", additionalProperties:false,
      required:["title","items","calories","protein_g","carbs_g","fat_g","fiber_g","confidence","assumptions","warning"],
      properties:{
        title:{type:"string"},
        items:{type:"array",items:{
          type:"object", additionalProperties:false,
          required:["name","portion","calories","protein_g","carbs_g","fat_g","fiber_g"],
          properties:{name:{type:"string"},portion:{type:"string"},calories:number,protein_g:number,carbs_g:number,fat_g:number,fiber_g:number}
        }},
        calories:number, protein_g:number, carbs_g:number, fat_g:number, fiber_g:number,
        confidence:{type:"number",minimum:0,maximum:1},
        assumptions:{type:"array",items:{type:"string"}}, warning:{type:"string"}
      }
    };
  }

  outputText(payload) {
    if (typeof payload?.output_text === "string") return payload.output_text;
    for (const output of payload?.output || []) {
      for (const content of output?.content || []) {
        if (content?.type === "output_text" && typeof content.text === "string") return content.text;
      }
    }
    throw new Error("Grok respondió con un formato que Caltrack no reconoce.");
  }

  async analyzeMeal(dataURL, apiKey) {
    if (!String(apiKey || "").trim()) throw new Error("Conecta xAI en Ajustes para analizar la foto con Grok.");
    const response = await this.request(`${this.xaiBase}/responses`, {
      method:"POST",
      headers:{Authorization:`Bearer ${String(apiKey).trim()}`,"Content-Type":"application/json"},
      body:JSON.stringify({
        model:"grok-4.5", store:false,
        input:[{role:"user",content:[
          {type:"input_image",image_url:dataURL,detail:"high"},
          {type:"input_text",text:"Analiza esta comida para un registro nutricional. Identifica cada componente visible, estima porciones realistas y calcula calorías, proteína, carbohidratos, grasa y fibra. Ten en cuenta aceites, salsas y bebidas visibles. No inventes certeza. Explica los supuestos y avisa si un ingrediente oculto puede cambiar mucho el total. Responde únicamente con el esquema solicitado. El usuario revisará cada valor antes de guardarlo."}
        ]}],
        text:{format:{type:"json_schema",name:"food_analysis",strict:true,schema:this.foodSchema()}}
      })
    }, "xAI");
    const payload = await response.json();
    let result;
    try { result = JSON.parse(this.outputText(payload)); }
    catch (error) {
      if (error instanceof SyntaxError) throw new Error("Grok no devolvió un análisis nutricional válido.");
      throw error;
    }
    if (!result?.title || !Array.isArray(result.items)) throw new Error("El análisis de Grok está incompleto.");
    return result;
  }

  async askCoach(question, dashboard, apiKey) {
    if (!String(apiKey || "").trim()) throw new Error("Conecta xAI en Ajustes para preguntar a Grok.");
    const safeContext = {
      goals:{
        calories:[dashboard.settings.calorie_goal_min,dashboard.settings.calorie_goal_max],
        protein:[dashboard.settings.protein_goal_min,dashboard.settings.protein_goal_max],
        deficit:dashboard.settings.deficit_kcal, training_days:dashboard.training
      },
      last_days:dashboard.days.map(day => ({
        date:day.day,calories:day.calories,protein_g:day.protein_g,deficit_kcal:day.deficit_kcal,
        target_hit:day.target_hit,protein_hit:day.protein_hit,workouts:day.exercises.map(item => ({name:item.name,duration_min:item.duration_min,source:item.source}))
      })),
      analysis:dashboard.analysis,
      body:{latest:dashboard.body.latest,latest_fat:dashboard.body.latest_fat,change_pct:dashboard.body.change_pct},
      strength:dashboard.strength.focus.map(item => ({exercise:item.exercise,best:item.best ? {weight_kg:item.best.weight_kg,reps:item.best.reps}:null}))
    };
    const response = await this.request(`${this.xaiBase}/responses`, {
      method:"POST",
      headers:{Authorization:`Bearer ${String(apiKey).trim()}`,"Content-Type":"application/json"},
      body:JSON.stringify({
        model:"grok-4.5", store:false,
        input:[{role:"system",content:[{type:"input_text",text:"Eres el entrenador privado de Caltrack. Responde en español, breve, directo y basado solo en los datos aportados. Señala incertidumbre y no des consejo médico. No recomiendes déficits extremos."}]},{role:"user",content:[{type:"input_text",text:`Datos: ${JSON.stringify(safeContext)}\n\nPregunta: ${question}`}]}]
      })
    }, "xAI");
    const payload = await response.json();
    return this.outputText(payload).trim();
  }

  async fetchHevyPage(apiKey, page, pageSize = 10) {
    const url = new URL(`${this.hevyBase}/workouts`);
    url.searchParams.set("page", String(page));
    url.searchParams.set("pageSize", String(pageSize));
    const response = await this.request(url, {headers:{"api-key":String(apiKey).trim(),Accept:"application/json"}}, "Hevy");
    return response.json();
  }

  async validateHevy(apiKey) {
    if (!String(apiKey || "").trim()) throw new Error("Añade una clave de Hevy.");
    await this.fetchHevyPage(apiKey, 1, 1);
    return true;
  }

  localDateTime(value) {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return String(value || "");
    const pad = number => String(number).padStart(2,"0");
    return `${date.getFullYear()}-${pad(date.getMonth()+1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
  }

  mapHevyWorkout(workout) {
    const exercises = (workout.exercises || []).map(exercise => {
      const sets = (exercise.sets || []).filter(set => (set.set_type || "normal") !== "warmup");
      const best = sets.reduce((winner,set) => {
        const score = Number(set.weight_kg || 0) * (1 + Number(set.reps || 0) / 30);
        return !winner || score > winner.score ? {set,score} : winner;
      }, null)?.set;
      const volume = sets.reduce((sum,set) => sum + Number(set.weight_kg || 0) * Number(set.reps || 0), 0);
      return {
        name:exercise.title || "Ejercicio", set_count:sets.length, volume_kg:Math.round(volume),
        best_weight_kg:best?.weight_kg == null ? null : Number(best.weight_kg),
        best_reps:best?.reps == null ? null : Number(best.reps),
        rpe:best?.rpe == null ? null : Number(best.rpe)
      };
    });
    const start = new Date(workout.start_time), end = new Date(workout.end_time);
    const duration = Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) ? 0 : Math.max(0, Math.round((end-start)/60000));
    const setCount = exercises.reduce((sum,item) => sum + item.set_count, 0);
    const volume = exercises.reduce((sum,item) => sum + item.volume_kg, 0);
    const summary = `${exercises.length} ejercicios, ${setCount} series${volume > 0 ? `, ${Math.round(volume).toLocaleString("es-ES")} kg de volumen` : ""}`;
    return {
      id:String(workout.id), title:workout.title || "Entrenamiento Hevy", start_time:this.localDateTime(workout.start_time),
      duration_min:duration, exercise_count:exercises.length, set_count:setCount, total_volume_kg:volume,
      summary, exercises
    };
  }

  async fetchHevyWorkouts(apiKey, maxPages = 10) {
    if (!String(apiKey || "").trim()) throw new Error("Conecta Hevy en Ajustes.");
    const workouts = [], seen = new Set();
    let pagesFetched = 0, pageCount = null;
    for (let page = 1; page <= Math.min(Math.max(maxPages,1),10); page += 1) {
      const payload = await this.fetchHevyPage(apiKey, page, 10);
      pagesFetched += 1;
      pageCount = Number(payload.page_count || pageCount || 0) || null;
      const pageWorkouts = Array.isArray(payload.workouts) ? payload.workouts : [];
      for (const workout of pageWorkouts) if (!seen.has(String(workout.id))) {
        seen.add(String(workout.id)); workouts.push(this.mapHevyWorkout(workout));
      }
      if (!pageWorkouts.length || pageWorkouts.length < 10 || (pageCount && page >= pageCount)) break;
    }
    return {workouts,pages_fetched:pagesFetched,total_pages:pageCount,truncated:Boolean(pageCount && pagesFetched < pageCount)};
  }

  async compressImage(file, maxDimension = 1600, quality = 0.78) {
    if (!file?.type?.startsWith("image/")) throw new Error("Elige una imagen válida.");
    if (file.size > 20 * 1024 * 1024) throw new Error("La foto supera 20 MB.");
    const source = URL.createObjectURL(file);
    try {
      const image = await new Promise((resolve,reject) => {
        const element = new Image();
        element.onload = () => resolve(element);
        element.onerror = () => reject(new Error("No se pudo abrir la foto."));
        element.src = source;
      });
      const scale = Math.min(1, maxDimension / Math.max(image.naturalWidth,image.naturalHeight,1));
      const canvas = document.createElement("canvas");
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
      canvas.getContext("2d", {alpha:false}).drawImage(image,0,0,canvas.width,canvas.height);
      return canvas.toDataURL("image/jpeg", quality);
    } finally { URL.revokeObjectURL(source); }
  }
}

window.caltrackIntegrations = new CaltrackIntegrations();
