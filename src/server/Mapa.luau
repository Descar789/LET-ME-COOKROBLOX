--[[
	Mapa.luau  (ModuleScript)
	UBICACIÓN EN STUDIO: ServerScriptService > Server > Mapa
	(hijo del Script "Server", igual que GameState)

	Construye la TIENDA completa por código (cero assets externos) y
	ejecuta los eventos de ambiente que sirven de PISTA al jugador.

	Vive en el SERVIDOR porque todo lo que se crea aquí (paredes, gato,
	NPCs) se replica automáticamente a todos los jugadores. Los eventos
	también se ejecutan aquí para que nadie pueda fingir "no lo vi".

	PLANO DE LA TIENDA (vista desde arriba, unidades en studs):

	        z=-14  PARED FRONTAL (puerta de vidrio al centro)
	       ┌─────────────┬puerta┬─────────────┐
	       │  estante    estante    estante   │
	  x=-21│ refris                           │x=21
	       │            MOSTRADOR             │
	       │            [jugador]             │
	       ├──────────────────────┬puerta─────┤ z=8 (muro trastienda)
	       │      TRASTIENDA  (frasco, gato)  │
	       └──────────────────────────────────┘ z=14

	API que usa el Script del servidor:
	  Mapa.construir()          -> levanta toda la tienda + iluminación
	  Mapa.mostrarNPC(info)     -> figura en el mostrador ({tipo, color})
	  Mapa.quitarNPC()          -> la figura actual se va
	  Mapa.ejecutarEvento(id)   -> "gato_cruza" | "luces_parpadean"
]]

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Mapa = {}

-- Referencias que llenamos al construir (las usan los eventos).
local carpeta -- Folder "Tienda" en Workspace
local lucesTecho = {} -- focos del techo (para el parpadeo)
local gato -- Model del gato blanco
local npcActual -- Model del NPC en el mostrador

-- ── Fábrica de partes ────────────────────────────────────────────────
-- Todas las piezas del mapa pasan por aquí: ancladas y lisas por defecto.
local function parte(props, padre)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = padre or carpeta
	return p
end

-- ── Ambiente nocturno ────────────────────────────────────────────────
local function configurarNoche()
	Lighting.ClockTime = 0 -- medianoche
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(20, 20, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 35)
	Lighting.FogEnd = 260 -- la calle se pierde en la niebla
	Lighting.FogColor = Color3.fromRGB(8, 8, 16)
end

-- ── El gato blanco (un ojo de cada color) ────────────────────────────
local function construirGato()
	gato = Instance.new("Model")
	gato.Name = "GatoBlanco"

	local cuerpo = parte({
		Name = "Cuerpo",
		Size = Vector3.new(1.6, 0.8, 0.7),
		Color = Color3.fromRGB(240, 240, 240),
		Material = Enum.Material.Fabric,
	}, gato)

	local cabeza = parte({
		Name = "Cabeza",
		Size = Vector3.new(0.7, 0.6, 0.6),
		Color = Color3.fromRGB(245, 245, 245),
		Material = Enum.Material.Fabric,
		CFrame = cuerpo.CFrame * CFrame.new(0.95, 0.35, 0),
	}, gato)

	-- Orejas: dos cuñas pequeñas.
	for lado = -1, 1, 2 do
		local oreja = Instance.new("WedgePart")
		oreja.Anchored = true
		oreja.Size = Vector3.new(0.15, 0.3, 0.25)
		oreja.Color = Color3.fromRGB(235, 235, 235)
		oreja.CFrame = cabeza.CFrame * CFrame.new(0, 0.4, 0.18 * lado)
		oreja.Parent = gato
	end

	-- Los ojos: UNO VERDE, UNO ÁMBAR — la seña que menciona Elvira.
	local ojoVerde = parte({
		Name = "OjoVerde",
		Size = Vector3.new(0.08, 0.12, 0.12),
		Color = Color3.fromRGB(80, 255, 120),
		Material = Enum.Material.Neon,
		CFrame = cabeza.CFrame * CFrame.new(0.36, 0.05, 0.15),
	}, gato)
	ojoVerde.Shape = Enum.PartType.Ball

	local ojoAmbar = parte({
		Name = "OjoAmbar",
		Size = Vector3.new(0.08, 0.12, 0.12),
		Color = Color3.fromRGB(255, 190, 60),
		Material = Enum.Material.Neon,
		CFrame = cabeza.CFrame * CFrame.new(0.36, 0.05, -0.15),
	}, gato)
	ojoAmbar.Shape = Enum.PartType.Ball

	-- Cola levantada.
	parte({
		Name = "Cola",
		Size = Vector3.new(0.15, 0.9, 0.15),
		Color = Color3.fromRGB(235, 235, 235),
		Material = Enum.Material.Fabric,
		CFrame = cuerpo.CFrame * CFrame.new(-0.85, 0.5, 0) * CFrame.Angles(0, 0, math.rad(15)),
	}, gato)

	gato.PrimaryPart = cuerpo
	gato.Parent = carpeta

	-- Empieza ESCONDIDO fuera de la tienda (aparece con su evento).
	gato:PivotTo(CFrame.new(0, -50, 0))
end

-- Mueve el gato suavemente por una lista de puntos (camina, no teletransporta).
local function caminarGato(puntos, tiempoPorTramo)
	for i = 1, #puntos - 1 do
		local desde, hasta = puntos[i], puntos[i + 1]
		-- Orientamos el gato hacia donde camina.
		local mirada = CFrame.lookAt(desde, hasta) * CFrame.Angles(0, math.rad(-90), 0)
		local pasos = 20
		for paso = 1, pasos do
			local posicion = desde:Lerp(hasta, paso / pasos)
			gato:PivotTo(mirada.Rotation + posicion)
			task.wait(tiempoPorTramo / pasos)
		end
	end
end

-- ── Construcción de la tienda ────────────────────────────────────────
function Mapa.construir()
	-- Si ya existía una tienda (re-ejecución), la tiramos y empezamos limpio.
	local vieja = workspace:FindFirstChild("Tienda")
	if vieja then
		vieja:Destroy()
	end
	carpeta = Instance.new("Folder")
	carpeta.Name = "Tienda"
	carpeta.Parent = workspace

	configurarNoche()

	local COLOR_PISO = Color3.fromRGB(200, 195, 180)
	local COLOR_PARED = Color3.fromRGB(120, 130, 140)
	local COLOR_MADERA = Color3.fromRGB(110, 80, 55)

	-- Piso interior (tienda + trastienda) y banqueta exterior.
	parte({ Name = "Piso", Size = Vector3.new(44, 1, 30), Position = Vector3.new(0, -0.5, 0),
		Color = COLOR_PISO, Material = Enum.Material.Marble })
	parte({ Name = "Banqueta", Size = Vector3.new(44, 1, 10), Position = Vector3.new(0, -0.55, -19),
		Color = Color3.fromRGB(90, 90, 95), Material = Enum.Material.Concrete })

	-- Techo.
	parte({ Name = "Techo", Size = Vector3.new(44, 1, 30), Position = Vector3.new(0, 12.5, 0),
		Color = Color3.fromRGB(80, 80, 85), Material = Enum.Material.Concrete })

	-- Paredes laterales y trasera.
	parte({ Name = "ParedIzq", Size = Vector3.new(1, 12, 30), Position = Vector3.new(-21.5, 6, 0),
		Color = COLOR_PARED, Material = Enum.Material.Brick })
	parte({ Name = "ParedDer", Size = Vector3.new(1, 12, 30), Position = Vector3.new(21.5, 6, 0),
		Color = COLOR_PARED, Material = Enum.Material.Brick })
	parte({ Name = "ParedTrasera", Size = Vector3.new(44, 12, 1), Position = Vector3.new(0, 6, 14.5),
		Color = COLOR_PARED, Material = Enum.Material.Brick })

	-- Pared frontal: dos tramos de VIDRIO (escaparate) + puerta al centro.
	for lado = -1, 1, 2 do
		parte({ Name = "Escaparate", Size = Vector3.new(19, 9, 0.6), Position = Vector3.new(11.5 * lado, 4.5, -14),
			Color = Color3.fromRGB(150, 200, 220), Material = Enum.Material.Glass, Transparency = 0.55 })
	end
	parte({ Name = "DintelPuerta", Size = Vector3.new(6, 3, 0.6), Position = Vector3.new(0, 10.5, -14),
		Color = COLOR_PARED, Material = Enum.Material.Brick })
	-- La puerta: vidrio, SIN colisión — los "clientes" pasan, y tú también.
	parte({ Name = "PuertaVidrio", Size = Vector3.new(6, 9, 0.4), Position = Vector3.new(0, 4.5, -14),
		Color = Color3.fromRGB(170, 220, 235), Material = Enum.Material.Glass,
		Transparency = 0.65, CanCollide = false })

	-- Letrero de neón "24 HRS" sobre la puerta, mirando a la calle.
	local letrero = parte({ Name = "Letrero", Size = Vector3.new(10, 2.2, 0.5),
		Position = Vector3.new(0, 13.6, -14.3), Color = Color3.fromRGB(10, 10, 14),
		Material = Enum.Material.SmoothPlastic })
	local guiLetrero = Instance.new("SurfaceGui")
	guiLetrero.Face = Enum.NormalId.Front
	guiLetrero.Parent = letrero
	local textoLetrero = Instance.new("TextLabel")
	textoLetrero.Size = UDim2.new(1, 0, 1, 0)
	textoLetrero.BackgroundTransparency = 1
	textoLetrero.Font = Enum.Font.Code
	textoLetrero.TextScaled = true
	textoLetrero.TextColor3 = Color3.fromRGB(120, 220, 160)
	textoLetrero.Text = "24 HRS"
	textoLetrero.Parent = guiLetrero

	-- Muro de la trastienda con su puerta (hueco a la derecha).
	parte({ Name = "MuroTrastienda", Size = Vector3.new(32, 12, 1), Position = Vector3.new(-6, 6, 8),
		Color = COLOR_PARED, Material = Enum.Material.Brick })
	parte({ Name = "DintelTrastienda", Size = Vector3.new(12, 4, 1), Position = Vector3.new(16, 10, 8),
		Color = COLOR_PARED, Material = Enum.Material.Brick })
	-- Marco visible de la puerta de la trastienda (siempre entreabierta...).
	parte({ Name = "PuertaTrastienda", Size = Vector3.new(3.5, 7.5, 0.3),
		CFrame = CFrame.new(12.5, 3.75, 8.6) * CFrame.Angles(0, math.rad(25), 0),
		Color = COLOR_MADERA, Material = Enum.Material.WoodPlanks, CanCollide = false })

	-- EL MOSTRADOR: aquí pasa toda la historia.
	parte({ Name = "Mostrador", Size = Vector3.new(14, 3.4, 2.5), Position = Vector3.new(0, 1.7, 3),
		Color = COLOR_MADERA, Material = Enum.Material.WoodPlanks })
	parte({ Name = "CubiertaMostrador", Size = Vector3.new(14.6, 0.3, 3.1), Position = Vector3.new(0, 3.55, 3),
		Color = Color3.fromRGB(60, 45, 35), Material = Enum.Material.Wood })
	-- Caja registradora (dos bloques).
	parte({ Name = "Caja", Size = Vector3.new(2, 1.2, 1.6), Position = Vector3.new(-4, 4.3, 3),
		Color = Color3.fromRGB(50, 50, 60), Material = Enum.Material.Metal })
	parte({ Name = "PantallaCaja", Size = Vector3.new(1.4, 0.9, 0.15),
		CFrame = CFrame.new(-4, 5.2, 3.4) * CFrame.Angles(math.rad(-12), 0, 0),
		Color = Color3.fromRGB(120, 220, 160), Material = Enum.Material.Neon })

	-- Estanterías con "productos" (bloques de colores) — 3 filas.
	local coloresProductos = {
		Color3.fromRGB(200, 80, 80), Color3.fromRGB(80, 140, 200),
		Color3.fromRGB(220, 180, 70), Color3.fromRGB(120, 190, 110),
		Color3.fromRGB(190, 120, 200), Color3.fromRGB(230, 130, 60),
	}
	local posicionesEstantes = {
		Vector3.new(-12, 0, -4), Vector3.new(-12, 0, -9), Vector3.new(10, 0, -6),
	}
	for e, base in ipairs(posicionesEstantes) do
		-- Cuerpo del estante.
		parte({ Name = "Estante" .. e, Size = Vector3.new(12, 6, 1.2),
			Position = base + Vector3.new(0, 3, 0),
			Color = Color3.fromRGB(160, 160, 165), Material = Enum.Material.Metal })
		-- Repisas con productos.
		for nivel = 1, 3 do
			parte({ Name = "Repisa", Size = Vector3.new(12.4, 0.2, 1.6),
				Position = base + Vector3.new(0, nivel * 1.8, 0),
				Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal })
			for prod = 1, 8 do
				parte({
					Name = "Producto",
					Size = Vector3.new(0.9, 1.1, 0.8),
					Position = base + Vector3.new(-5.2 + (prod - 1) * 1.5, nivel * 1.8 + 0.75, 0),
					Color = coloresProductos[(prod + nivel + e) % #coloresProductos + 1],
					Material = Enum.Material.SmoothPlastic,
				})
			end
		end
	end

	-- Refrigeradores contra la pared izquierda (brillan en la noche).
	for r = 1, 3 do
		parte({ Name = "Refri" .. r, Size = Vector3.new(1.4, 8, 5),
			Position = Vector3.new(-20.5, 4, -8 + (r - 1) * 5.6),
			Color = Color3.fromRGB(230, 235, 240), Material = Enum.Material.Metal })
		local puertaRefri = parte({ Name = "PuertaRefri", Size = Vector3.new(0.3, 6.5, 4.4),
			Position = Vector3.new(-19.7, 4, -8 + (r - 1) * 5.6),
			Color = Color3.fromRGB(180, 230, 255), Material = Enum.Material.Glass, Transparency = 0.4 })
		local luzRefri = Instance.new("PointLight")
		luzRefri.Color = Color3.fromRGB(200, 235, 255)
		luzRefri.Range = 9
		luzRefri.Brightness = 0.7
		luzRefri.Parent = puertaRefri
	end

	-- La CÁMARA DE SEGURIDAD (protagonista del cliente 5).
	local camara = parte({ Name = "CamaraSeguridad", Size = Vector3.new(0.8, 0.8, 1.6),
		CFrame = CFrame.new(19.5, 10.5, -12) * CFrame.Angles(math.rad(-20), math.rad(-135), 0),
		Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal })
	parte({ Name = "LenteCamara", Size = Vector3.new(0.3, 0.3, 0.2),
		CFrame = camara.CFrame * CFrame.new(0, 0, -0.9),
		Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon })

	-- Focos del techo: 4 lámparas de neón (las que parpadean en el evento).
	for i = 1, 4 do
		local x = (i <= 2) and -10 or 10
		local z = (i % 2 == 0) and -8 or 2
		local foco = parte({ Name = "Foco" .. i, Size = Vector3.new(5, 0.3, 1.2),
			Position = Vector3.new(x, 11.9, z),
			Color = Color3.fromRGB(255, 250, 230), Material = Enum.Material.Neon })
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 245, 220)
		luz.Range = 22
		luz.Brightness = 1.1
		luz.Parent = foco
		table.insert(lucesTecho, foco)
	end

	-- TRASTIENDA: estante con el frasco sin etiqueta que brilla.
	parte({ Name = "EstanteTrastienda", Size = Vector3.new(8, 6, 1),
		Position = Vector3.new(-14, 3, 12.5),
		Color = Color3.fromRGB(90, 70, 55), Material = Enum.Material.WoodPlanks })
	local frasco = parte({ Name = "FrascoSinEtiqueta", Size = Vector3.new(0.9, 1.3, 0.9),
		Position = Vector3.new(-14, 5.2, 12.2),
		Color = Color3.fromRGB(150, 255, 180), Material = Enum.Material.Neon, Transparency = 0.25 })
	local luzFrasco = Instance.new("PointLight")
	luzFrasco.Color = Color3.fromRGB(120, 255, 160)
	luzFrasco.Range = 8
	luzFrasco.Brightness = 0.8
	luzFrasco.Parent = frasco

	-- SPAWN: el jugador nace DETRÁS del mostrador, mirando a la puerta.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnEmpleado"
	spawn.Size = Vector3.new(4, 0.5, 4)
	spawn.CFrame = CFrame.new(0, 0.25, 6.2) * CFrame.Angles(0, math.rad(180), 0)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = carpeta

	-- El gato existe desde el inicio (escondido) para poder animarlo.
	construirGato()

	print("[Mapa] Tienda construida. Turno nocturno ambientado.")
end

-- ── NPCs en el mostrador ─────────────────────────────────────────────
-- Figura simple (torso + cabeza) parada FRENTE al mostrador.
-- No es un Humanoid: es utilería de la escena, como en un teatro.
function Mapa.mostrarNPC(info)
	Mapa.quitarNPC()
	if info == nil then
		return
	end

	if info.tipo == "gato" then
		-- El gato sale de la trastienda y salta al mostrador.
		task.spawn(caminarGato, {
			Vector3.new(12.5, 0.6, 10),
			Vector3.new(12.5, 0.6, 5),
			Vector3.new(2, 0.6, 1),
			Vector3.new(0, 4.2, 3), -- arriba del mostrador
		}, 1.2)
		npcActual = gato -- lo tratamos como el NPC actual
		return
	end

	local color = Color3.fromRGB(info.color[1], info.color[2], info.color[3])
	npcActual = Instance.new("Model")
	npcActual.Name = "Cliente"

	local torso = parte({
		Name = "Torso",
		Size = Vector3.new(2, 2.6, 1),
		CFrame = CFrame.new(0, 2.5, 0.4) * CFrame.Angles(0, math.rad(180), 0),
		Color = color,
		Material = Enum.Material.Fabric,
	}, npcActual)
	local cabeza = parte({
		Name = "Cabeza",
		Size = Vector3.new(1.1, 1.1, 1.1),
		CFrame = torso.CFrame * CFrame.new(0, 1.85, 0),
		Color = Color3.fromRGB(215, 180, 150),
		Material = Enum.Material.SmoothPlastic,
	}, npcActual)
	cabeza.Shape = Enum.PartType.Ball
	-- Piernas sugeridas con un bloque.
	parte({
		Name = "Piernas",
		Size = Vector3.new(1.8, 1.2, 0.9),
		CFrame = torso.CFrame * CFrame.new(0, -1.9, 0),
		Color = Color3.fromRGB(40, 40, 55),
		Material = Enum.Material.Fabric,
	}, npcActual)

	npcActual.Parent = carpeta
end

function Mapa.quitarNPC()
	if npcActual == nil then
		return
	end
	if npcActual == gato then
		-- El gato se baja del mostrador y sale por la puerta principal.
		local g = gato
		task.spawn(function()
			caminarGato({
				Vector3.new(0, 4.2, 3),
				Vector3.new(0, 0.6, 0),
				Vector3.new(0, 0.6, -13),
				Vector3.new(0, 0.6, -20),
			}, 1)
			g:PivotTo(CFrame.new(0, -50, 0)) -- vuelve a esconderse
		end)
	else
		npcActual:Destroy()
	end
	npcActual = nil
end

-- ── Eventos de ambiente (las PISTAS) ─────────────────────────────────
local eventos = {}

-- El gato blanco cruza la tienda y se mete a la trastienda.
-- Quien lo ve, sabrá qué responderle a Elvira.
eventos.gato_cruza = function()
	caminarGato({
		Vector3.new(0, 0.6, -20), -- desde la calle
		Vector3.new(0, 0.6, -10), -- entra por la puerta
		Vector3.new(8, 0.6, -2), -- cruza el pasillo
		Vector3.new(12.5, 0.6, 6), -- llega a la puerta de la trastienda
		Vector3.new(12.5, 0.6, 11), -- ...y se mete
	}, 1.6)
	-- Se queda "dormido" dentro de la trastienda (visible si entras).
	gato:PivotTo(CFrame.new(-10, 0.6, 12) * CFrame.Angles(0, math.rad(90), 0))
end

-- Las luces fallan unos segundos. Pista para engañar al encapuchado.
eventos.luces_parpadean = function()
	for ciclo = 1, 8 do
		for _, foco in ipairs(lucesTecho) do
			local apagado = (ciclo % 2 == 1)
			foco.Material = apagado and Enum.Material.SmoothPlastic or Enum.Material.Neon
			local luz = foco:FindFirstChildOfClass("PointLight")
			if luz then
				luz.Enabled = not apagado
			end
		end
		task.wait(ciclo <= 4 and 0.15 or 0.4) -- tiembla rápido, luego lento
	end
	-- Todo vuelve a la normalidad... ¿o no?
	for _, foco in ipairs(lucesTecho) do
		foco.Material = Enum.Material.Neon
		local luz = foco:FindFirstChildOfClass("PointLight")
		if luz then
			luz.Enabled = true
		end
	end
end

function Mapa.ejecutarEvento(id)
	local evento = eventos[id]
	if evento == nil then
		warn("[Mapa] Evento desconocido:", id)
		return
	end
	evento()
end

return Mapa
