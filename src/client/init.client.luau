--[[
	init.client.luau  (LocalScript)
	UBICACIÓN EN STUDIO: StarterPlayer > StarterPlayerScripts > Client
	(con Rojo se sincroniza solo; si pegas a mano, crea un LocalScript
	llamado "Client" dentro de StarterPlayerScripts y pega esto)

	Este script es SOLO la "pantalla" del juego. No guarda estado, no
	decide nada, no sabe de banderas ni de finales. Su trabajo:
	  1. Construir el GUI por código (nada de armar frames a mano).
	  2. Escuchar los RemoteEvents del servidor y mostrar lo que llegue.
	  3. Cuando el jugador pulsa un botón, avisar al servidor y ya.

	Si un tramposo modifica este script, no gana nada: el servidor
	valida cada decisión y el estado real vive allá.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local jugador = Players.LocalPlayer

-- Esperamos a que el servidor cree la carpeta de remotos.
local remotos = ReplicatedStorage:WaitForChild("Remotos")
local remotoMostrarCliente = remotos:WaitForChild("MostrarCliente")
local remotoMostrarRespuesta = remotos:WaitForChild("MostrarRespuesta")
local remotoFinDeTurno = remotos:WaitForChild("FinDeTurno")
local remotoDecision = remotos:WaitForChild("TomarDecision")

-- ── Paleta de colores del turno nocturno ─────────────────────────────
-- Definirlos aquí arriba facilita cambiar el look del juego completo.
local COLOR_FONDO = Color3.fromRGB(18, 18, 28) -- casi negro azulado
local COLOR_PANEL = Color3.fromRGB(28, 28, 42) -- panel del diálogo
local COLOR_ACENTO = Color3.fromRGB(120, 220, 160) -- verde neón de tienda 24h
local COLOR_TEXTO = Color3.fromRGB(235, 235, 240)
local COLOR_TEXTO_SUAVE = Color3.fromRGB(160, 160, 180)
local COLOR_BOTON = Color3.fromRGB(45, 45, 68)
local COLOR_BOTON_HOVER = Color3.fromRGB(65, 65, 95)

-- ── 1. Construcción del GUI ──────────────────────────────────────────
-- Estructura:
--   ScreenGui
--   └── PanelPrincipal (abajo de la pantalla, estilo "novela visual")
--       ├── EtiquetaHora     (esquina: "10:30 PM")
--       ├── EtiquetaNombre   (nombre del cliente en acento verde)
--       ├── EtiquetaDialogo  (lo que dice el cliente)
--       └── ContenedorBotones (los botones de decisión, generados al vuelo)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TurnoDeNocheGui"
screenGui.ResetOnSpawn = false -- que no se destruya si el personaje muere
screenGui.IgnoreGuiInset = true
screenGui.Parent = jugador:WaitForChild("PlayerGui")

-- Panel principal: ocupa la franja inferior de la pantalla.
local panel = Instance.new("Frame")
panel.Name = "PanelPrincipal"
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -20)
panel.Size = UDim2.new(0.8, 0, 0.38, 0)
panel.BackgroundColor3 = COLOR_PANEL
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false -- oculto hasta que llegue el primer cliente
panel.Parent = screenGui

-- Esquinas redondeadas: se logran con un UICorner adentro del frame.
local esquinas = Instance.new("UICorner")
esquinas.CornerRadius = UDim.new(0, 14)
esquinas.Parent = panel

-- Borde sutil color acento.
local borde = Instance.new("UIStroke")
borde.Color = COLOR_ACENTO
borde.Transparency = 0.6
borde.Thickness = 2
borde.Parent = panel

-- Relleno interno para que el texto no pegue con los bordes.
local margen = Instance.new("UIPadding")
margen.PaddingTop = UDim.new(0, 16)
margen.PaddingBottom = UDim.new(0, 16)
margen.PaddingLeft = UDim.new(0, 24)
margen.PaddingRight = UDim.new(0, 24)
margen.Parent = panel

-- Hora ficticia (arriba a la derecha del panel).
local etiquetaHora = Instance.new("TextLabel")
etiquetaHora.Name = "EtiquetaHora"
etiquetaHora.AnchorPoint = Vector2.new(1, 0)
etiquetaHora.Position = UDim2.new(1, 0, 0, 0)
etiquetaHora.Size = UDim2.new(0.3, 0, 0, 24)
etiquetaHora.BackgroundTransparency = 1
etiquetaHora.Font = Enum.Font.Code
etiquetaHora.TextSize = 18
etiquetaHora.TextColor3 = COLOR_ACENTO
etiquetaHora.TextXAlignment = Enum.TextXAlignment.Right
etiquetaHora.Text = ""
etiquetaHora.Parent = panel

-- Nombre del cliente.
local etiquetaNombre = Instance.new("TextLabel")
etiquetaNombre.Name = "EtiquetaNombre"
etiquetaNombre.Position = UDim2.new(0, 0, 0, 0)
etiquetaNombre.Size = UDim2.new(0.65, 0, 0, 24)
etiquetaNombre.BackgroundTransparency = 1
etiquetaNombre.Font = Enum.Font.GothamBold
etiquetaNombre.TextSize = 20
etiquetaNombre.TextColor3 = COLOR_ACENTO
etiquetaNombre.TextXAlignment = Enum.TextXAlignment.Left
etiquetaNombre.Text = ""
etiquetaNombre.Parent = panel

-- Diálogo del cliente (el texto grande del centro).
local etiquetaDialogo = Instance.new("TextLabel")
etiquetaDialogo.Name = "EtiquetaDialogo"
etiquetaDialogo.Position = UDim2.new(0, 0, 0, 32)
etiquetaDialogo.Size = UDim2.new(1, 0, 1, -110)
etiquetaDialogo.BackgroundTransparency = 1
etiquetaDialogo.Font = Enum.Font.Gotham
etiquetaDialogo.TextSize = 19
etiquetaDialogo.TextColor3 = COLOR_TEXTO
etiquetaDialogo.TextXAlignment = Enum.TextXAlignment.Left
etiquetaDialogo.TextYAlignment = Enum.TextYAlignment.Top
etiquetaDialogo.TextWrapped = true -- que el texto haga saltos de línea solo
etiquetaDialogo.Text = ""
etiquetaDialogo.Parent = panel

-- Contenedor de botones de decisión (fila inferior del panel).
local contenedorBotones = Instance.new("Frame")
contenedorBotones.Name = "ContenedorBotones"
contenedorBotones.AnchorPoint = Vector2.new(0, 1)
contenedorBotones.Position = UDim2.new(0, 0, 1, 0)
contenedorBotones.Size = UDim2.new(1, 0, 0, 64)
contenedorBotones.BackgroundTransparency = 1
contenedorBotones.Parent = panel

-- UIListLayout acomoda los botones en fila horizontal automáticamente.
local layoutBotones = Instance.new("UIListLayout")
layoutBotones.FillDirection = Enum.FillDirection.Horizontal
layoutBotones.HorizontalAlignment = Enum.HorizontalAlignment.Center
layoutBotones.VerticalAlignment = Enum.VerticalAlignment.Center
layoutBotones.Padding = UDim.new(0, 16)
layoutBotones.Parent = contenedorBotones

-- Pantalla de final (cubre todo, aparece al terminar la noche).
local pantallaFinal = Instance.new("Frame")
pantallaFinal.Name = "PantallaFinal"
pantallaFinal.Size = UDim2.new(1, 0, 1, 0)
pantallaFinal.BackgroundColor3 = COLOR_FONDO
pantallaFinal.BackgroundTransparency = 1 -- empieza invisible, hace fade
pantallaFinal.BorderSizePixel = 0
pantallaFinal.Visible = false
pantallaFinal.ZIndex = 5
pantallaFinal.Parent = screenGui

local tituloFinal = Instance.new("TextLabel")
tituloFinal.AnchorPoint = Vector2.new(0.5, 0.5)
tituloFinal.Position = UDim2.new(0.5, 0, 0.38, 0)
tituloFinal.Size = UDim2.new(0.8, 0, 0, 60)
tituloFinal.BackgroundTransparency = 1
tituloFinal.Font = Enum.Font.GothamBold
tituloFinal.TextSize = 38
tituloFinal.TextColor3 = COLOR_ACENTO
tituloFinal.TextTransparency = 1
tituloFinal.TextWrapped = true
tituloFinal.ZIndex = 6
tituloFinal.Text = ""
tituloFinal.Parent = pantallaFinal

local textoFinal = Instance.new("TextLabel")
textoFinal.AnchorPoint = Vector2.new(0.5, 0.5)
textoFinal.Position = UDim2.new(0.5, 0, 0.55, 0)
textoFinal.Size = UDim2.new(0.6, 0, 0, 160)
textoFinal.BackgroundTransparency = 1
textoFinal.Font = Enum.Font.Gotham
textoFinal.TextSize = 20
textoFinal.TextColor3 = COLOR_TEXTO
textoFinal.TextTransparency = 1
textoFinal.TextWrapped = true
textoFinal.ZIndex = 6
textoFinal.Text = ""
textoFinal.Parent = pantallaFinal

-- ── 2. Funciones de apoyo ────────────────────────────────────────────

-- Efecto "máquina de escribir": el texto aparece letra por letra.
-- Le da ambiente de novela de terror sin necesitar ningún asset.
local escrituraActual = 0 -- contador para cancelar escrituras viejas

local function escribirTexto(etiqueta, textoCompleto)
	escrituraActual += 1
	local miTurno = escrituraActual

	etiqueta.MaxVisibleGraphemes = 0
	etiqueta.Text = textoCompleto

	task.spawn(function()
		for i = 1, #textoCompleto do
			-- Si empezó otra escritura, esta se cancela sola.
			if escrituraActual ~= miTurno then
				return
			end
			etiqueta.MaxVisibleGraphemes = i
			task.wait(0.015)
		end
		etiqueta.MaxVisibleGraphemes = -1 -- -1 = mostrar todo
	end)
end

-- Borra los botones de decisión anteriores.
local function limpiarBotones()
	for _, hijo in ipairs(contenedorBotones:GetChildren()) do
		if hijo:IsA("TextButton") then
			hijo:Destroy()
		end
	end
end

-- Crea un botón de decisión y lo conecta al servidor.
-- 'totalOpciones' reparte el ancho: 2 opciones = botones anchos,
-- 3 o más = botones más angostos, todos caben en la fila.
-- 'orden' fija LayoutOrder: sin él, UIListLayout acomoda los botones
-- alfabéticamente y desordena las opciones.
local function crearBoton(idCliente, opcion, totalOpciones, orden)
	local anchoBoton = math.min(0.42, (1 / totalOpciones) - 0.03)

	local boton = Instance.new("TextButton")
	boton.Name = "Opcion_" .. opcion.id
	boton.LayoutOrder = orden
	boton.Size = UDim2.new(anchoBoton, 0, 0, 52)
	boton.BackgroundColor3 = COLOR_BOTON
	boton.Font = Enum.Font.GothamMedium
	boton.TextSize = 17
	boton.TextColor3 = COLOR_TEXTO
	boton.TextWrapped = true
	boton.AutoButtonColor = false -- el hover lo hacemos nosotros con tween
	boton.Text = opcion.texto
	boton.Parent = contenedorBotones

	local esquinasBoton = Instance.new("UICorner")
	esquinasBoton.CornerRadius = UDim.new(0, 10)
	esquinasBoton.Parent = boton

	-- Hover: aclarar el botón cuando el mouse pasa encima.
	boton.MouseEnter:Connect(function()
		TweenService:Create(boton, TweenInfo.new(0.15), {
			BackgroundColor3 = COLOR_BOTON_HOVER,
		}):Play()
	end)
	boton.MouseLeave:Connect(function()
		TweenService:Create(boton, TweenInfo.new(0.15), {
			BackgroundColor3 = COLOR_BOTON,
		}):Play()
	end)

	-- Click: avisar al servidor QUÉ se eligió y bloquear los botones
	-- para no mandar decisiones dobles.
	boton.Activated:Connect(function()
		remotoDecision:FireServer(idCliente, opcion.id)
		for _, hijo in ipairs(contenedorBotones:GetChildren()) do
			if hijo:IsA("TextButton") then
				hijo.Active = false
				hijo.TextColor3 = COLOR_TEXTO_SUAVE
			end
		end
	end)

	return boton
end

-- ── 3. Reaccionar a los mensajes del servidor ────────────────────────

-- Llega un cliente nuevo al mostrador.
remotoMostrarCliente.OnClientEvent:Connect(function(datosCliente)
	panel.Visible = true
	etiquetaHora.Text = datosCliente.hora
	etiquetaNombre.Text = datosCliente.nombre
	escribirTexto(etiquetaDialogo, datosCliente.dialogo)

	limpiarBotones()
	for indice, opcion in ipairs(datosCliente.opciones) do
		crearBoton(datosCliente.id, opcion, #datosCliente.opciones, indice)
	end
end)

-- Llega la consecuencia de la decisión tomada.
remotoMostrarRespuesta.OnClientEvent:Connect(function(textoRespuesta)
	limpiarBotones()
	etiquetaNombre.Text = ""
	escribirTexto(etiquetaDialogo, textoRespuesta)
end)

-- Se acabó la noche: pantalla de final con fade a negro.
remotoFinDeTurno.OnClientEvent:Connect(function(datosFinal)
	panel.Visible = false
	pantallaFinal.Visible = true
	tituloFinal.Text = datosFinal.titulo
	textoFinal.Text = datosFinal.texto

	-- Fade del fondo y luego del texto, usando tweens encadenados.
	local fadeFondo = TweenService:Create(pantallaFinal, TweenInfo.new(1.5), {
		BackgroundTransparency = 0,
	})
	fadeFondo.Completed:Connect(function()
		TweenService:Create(tituloFinal, TweenInfo.new(1), { TextTransparency = 0 }):Play()
		TweenService:Create(textoFinal, TweenInfo.new(1.5), { TextTransparency = 0 }):Play()
	end)
	fadeFondo:Play()
end)

print("[TurnoDeNoche] GUI del cliente construido. Que empiece el turno.")
