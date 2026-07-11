--[[
	Mapa.luau  (ModuleScript)
	UBICACIÓN EN STUDIO: ServerScriptService > Server > Mapa
	(hijo del Script "Server", igual que GameState)

	IMPORTANTE: este módulo YA NO construye la tienda. La tienda vive
	como instancias normales en workspace > Tienda, guardadas en el
	place — puedes editarla a mano en Studio (mover estantes, cambiar
	colores, agregar cosas) sin tocar código.

	Si algún día necesitas REGENERAR la tienda desde cero, el generador
	está en tools/ConstruirMapa.luau (se corre una sola vez en Edit).

	Lo que SÍ hace este módulo (lo dinámico de la escena):
	  - El GATO BLANCO: lo crea y lo anima (cruza la tienda, sale de la
	    trastienda, salta al mostrador). Es un actor, no escenografía.
	  - Los NPCs: figura simple frente al mostrador por cada cliente.
	  - Los EVENTOS-PISTA: gato_cruza, luces_parpadean.

	API que usa el Script del servidor:
	  Mapa.inicializar()        -> encuentra la tienda y prepara el gato
	  Mapa.mostrarNPC(info)     -> figura en el mostrador ({tipo, color})
	  Mapa.quitarNPC()          -> la figura actual se va
	  Mapa.ejecutarEvento(id)   -> "gato_cruza" | "luces_parpadean"
]]

local Mapa = {}

-- Referencias al mapa existente (se llenan en inicializar).
local carpeta -- workspace.Tienda
local lucesTecho = {} -- los focos Foco1..Foco4 (para el parpadeo)
local gato -- Model del gato (dinámico, creado aquí)
local npcActual -- Model del NPC en el mostrador

-- ── Fábrica de partes (solo para el gato y los NPCs) ─────────────────
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

	-- Empieza ESCONDIDO bajo el mapa (aparece con su evento).
	gato:PivotTo(CFrame.new(0, -50, 0))
end

-- Mueve el gato suavemente por una lista de puntos (camina, no teleport).
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

-- ── Inicialización: encontrar la tienda ya construida ────────────────
function Mapa.inicializar()
	carpeta = workspace:FindFirstChild("Tienda")
	if carpeta == nil then
		-- Sin tienda no hay eventos ni NPCs, pero el juego de decisiones
		-- funciona igual. Avisamos claro cómo arreglarlo.
		warn("[Mapa] No existe workspace.Tienda. El mapa es parte del place: "
			.. "córrelo una vez con tools/ConstruirMapa.luau en modo Edit.")
		return
	end

	-- Juntamos los focos del techo (Foco1..Foco4) para el evento de parpadeo.
	lucesTecho = {}
	for _, hijo in ipairs(carpeta:GetChildren()) do
		if hijo.Name:match("^Foco%d+$") then
			table.insert(lucesTecho, hijo)
		end
	end

	construirGato()
	print("[Mapa] Tienda encontrada (" .. #lucesTecho .. " focos). Gato listo.")
end

-- ── NPCs en el mostrador ─────────────────────────────────────────────
-- Figura simple (torso + cabeza + piernas) parada FRENTE al mostrador.
-- No es un Humanoid: es utilería de la escena, como en un teatro.
function Mapa.mostrarNPC(info)
	Mapa.quitarNPC()
	if info == nil or carpeta == nil then
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
	if carpeta == nil then
		return -- sin tienda no hay eventos (ya avisamos en inicializar)
	end
	local evento = eventos[id]
	if evento == nil then
		warn("[Mapa] Evento desconocido:", id)
		return
	end
	evento()
end

return Mapa
