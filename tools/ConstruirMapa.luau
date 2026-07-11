--[[
	tools/ConstruirMapa.luau — GENERADOR DEL MAPA (usar UNA sola vez)

	La tienda del juego vive como instancias normales en workspace > Tienda,
	guardadas en el place. NO se construye en runtime.

	Este script existe solo por si necesitas REGENERARLA desde cero
	(la borraste, quieres empezar de nuevo, o montas el juego en otro place).

	CÓMO USARLO:
	1. Abre el place en Roblox Studio, en modo Edit (sin Play).
	2. Abre la Command Bar (View → Command Bar).
	3. Pega TODO este archivo en la Command Bar y presiona Enter.
	   (O créalo como Script temporal, córrelo con Play y copia la carpeta
	   Tienda resultante — pero la Command Bar es más directo.)
	4. Guarda el place (Ctrl+S). Listo: la tienda es permanente.

	OJO: borra la Tienda anterior si existe (empieza limpio).
	El gato NO se genera aquí: es dinámico y lo crea Mapa.luau al arrancar.
]]

local Lighting = game:GetService("Lighting")

local vieja = workspace:FindFirstChild("Tienda")
if vieja then
	vieja:Destroy()
end
local carpeta = Instance.new("Folder")
carpeta.Name = "Tienda"
carpeta.Parent = workspace

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

-- Iluminación nocturna (las propiedades de Lighting se guardan con el place).
Lighting.ClockTime = 0
Lighting.Brightness = 1
Lighting.Ambient = Color3.fromRGB(20, 20, 30)
Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 35)
Lighting.FogEnd = 260
Lighting.FogColor = Color3.fromRGB(8, 8, 16)

local COLOR_PISO = Color3.fromRGB(200, 195, 180)
local COLOR_PARED = Color3.fromRGB(120, 130, 140)
local COLOR_MADERA = Color3.fromRGB(110, 80, 55)

-- Piso, banqueta, techo.
parte({ Name = "Piso", Size = Vector3.new(44, 1, 30), Position = Vector3.new(0, -0.5, 0),
	Color = COLOR_PISO, Material = Enum.Material.Marble })
parte({ Name = "Banqueta", Size = Vector3.new(44, 1, 10), Position = Vector3.new(0, -0.55, -19),
	Color = Color3.fromRGB(90, 90, 95), Material = Enum.Material.Concrete })
parte({ Name = "Techo", Size = Vector3.new(44, 1, 30), Position = Vector3.new(0, 12.5, 0),
	Color = Color3.fromRGB(80, 80, 85), Material = Enum.Material.Concrete })

-- Paredes laterales y trasera.
parte({ Name = "ParedIzq", Size = Vector3.new(1, 12, 30), Position = Vector3.new(-21.5, 6, 0),
	Color = COLOR_PARED, Material = Enum.Material.Brick })
parte({ Name = "ParedDer", Size = Vector3.new(1, 12, 30), Position = Vector3.new(21.5, 6, 0),
	Color = COLOR_PARED, Material = Enum.Material.Brick })
parte({ Name = "ParedTrasera", Size = Vector3.new(44, 12, 1), Position = Vector3.new(0, 6, 14.5),
	Color = COLOR_PARED, Material = Enum.Material.Brick })

-- Frente: escaparates de vidrio + puerta sin colisión.
for lado = -1, 1, 2 do
	parte({ Name = "Escaparate", Size = Vector3.new(19, 9, 0.6), Position = Vector3.new(11.5 * lado, 4.5, -14),
		Color = Color3.fromRGB(150, 200, 220), Material = Enum.Material.Glass, Transparency = 0.55 })
end
parte({ Name = "DintelPuerta", Size = Vector3.new(6, 3, 0.6), Position = Vector3.new(0, 10.5, -14),
	Color = COLOR_PARED, Material = Enum.Material.Brick })
parte({ Name = "PuertaVidrio", Size = Vector3.new(6, 9, 0.4), Position = Vector3.new(0, 4.5, -14),
	Color = Color3.fromRGB(170, 220, 235), Material = Enum.Material.Glass,
	Transparency = 0.65, CanCollide = false })

-- Letrero de neón "24 HRS" sobre la puerta.
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

-- Muro de la trastienda con puerta entreabierta.
parte({ Name = "MuroTrastienda", Size = Vector3.new(32, 12, 1), Position = Vector3.new(-6, 6, 8),
	Color = COLOR_PARED, Material = Enum.Material.Brick })
parte({ Name = "DintelTrastienda", Size = Vector3.new(12, 4, 1), Position = Vector3.new(16, 10, 8),
	Color = COLOR_PARED, Material = Enum.Material.Brick })
parte({ Name = "PuertaTrastienda", Size = Vector3.new(3.5, 7.5, 0.3),
	CFrame = CFrame.new(12.5, 3.75, 8.6) * CFrame.Angles(0, math.rad(25), 0),
	Color = COLOR_MADERA, Material = Enum.Material.WoodPlanks, CanCollide = false })

-- EL MOSTRADOR.
parte({ Name = "Mostrador", Size = Vector3.new(14, 3.4, 2.5), Position = Vector3.new(0, 1.7, 3),
	Color = COLOR_MADERA, Material = Enum.Material.WoodPlanks })
parte({ Name = "CubiertaMostrador", Size = Vector3.new(14.6, 0.3, 3.1), Position = Vector3.new(0, 3.55, 3),
	Color = Color3.fromRGB(60, 45, 35), Material = Enum.Material.Wood })
parte({ Name = "Caja", Size = Vector3.new(2, 1.2, 1.6), Position = Vector3.new(-4, 4.3, 3),
	Color = Color3.fromRGB(50, 50, 60), Material = Enum.Material.Metal })
parte({ Name = "PantallaCaja", Size = Vector3.new(1.4, 0.9, 0.15),
	CFrame = CFrame.new(-4, 5.2, 3.4) * CFrame.Angles(math.rad(-12), 0, 0),
	Color = Color3.fromRGB(120, 220, 160), Material = Enum.Material.Neon })

-- Estanterías con "productos" (bloques de colores).
local coloresProductos = {
	Color3.fromRGB(200, 80, 80), Color3.fromRGB(80, 140, 200),
	Color3.fromRGB(220, 180, 70), Color3.fromRGB(120, 190, 110),
	Color3.fromRGB(190, 120, 200), Color3.fromRGB(230, 130, 60),
}
local posicionesEstantes = {
	Vector3.new(-12, 0, -4), Vector3.new(-12, 0, -9), Vector3.new(10, 0, -6),
}
for e, base in ipairs(posicionesEstantes) do
	parte({ Name = "Estante" .. e, Size = Vector3.new(12, 6, 1.2),
		Position = base + Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(160, 160, 165), Material = Enum.Material.Metal })
	for nivel = 1, 3 do
		parte({ Name = "Repisa", Size = Vector3.new(12.4, 0.2, 1.6),
			Position = base + Vector3.new(0, nivel * 1.8, 0),
			Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal })
		for prod = 1, 8 do
			parte({ Name = "Producto", Size = Vector3.new(0.9, 1.1, 0.8),
				Position = base + Vector3.new(-5.2 + (prod - 1) * 1.5, nivel * 1.8 + 0.75, 0),
				Color = coloresProductos[(prod + nivel + e) % #coloresProductos + 1],
				Material = Enum.Material.SmoothPlastic })
		end
	end
end

-- Refrigeradores que brillan.
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

-- Cámara de seguridad con lente rojo.
local camara = parte({ Name = "CamaraSeguridad", Size = Vector3.new(0.8, 0.8, 1.6),
	CFrame = CFrame.new(19.5, 10.5, -12) * CFrame.Angles(math.rad(-20), math.rad(-135), 0),
	Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal })
parte({ Name = "LenteCamara", Size = Vector3.new(0.3, 0.3, 0.2),
	CFrame = camara.CFrame * CFrame.new(0, 0, -0.9),
	Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon })

-- Focos del techo Foco1..Foco4 (Mapa.luau los busca por nombre
-- para el evento de parpadeo — no los renombres).
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
end

-- Trastienda: estante + frasco sin etiqueta que brilla.
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

-- Spawn: detrás del mostrador, mirando a la puerta.
local spawn = Instance.new("SpawnLocation")
spawn.Name = "SpawnEmpleado"
spawn.Size = Vector3.new(4, 0.5, 4)
spawn.CFrame = CFrame.new(0, 0.25, 6.2) * CFrame.Angles(0, math.rad(180), 0)
spawn.Anchored = true
spawn.Transparency = 1
spawn.Duration = 0
spawn.Neutral = true
spawn.Parent = carpeta

print("[ConstruirMapa] Tienda generada: " .. #carpeta:GetDescendants() .. " instancias. Guarda el place (Ctrl+S).")
