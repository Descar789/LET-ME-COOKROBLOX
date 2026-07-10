--[[
	ClientesData.luau  (ModuleScript)
	UBICACIÓN EN STUDIO: ReplicatedStorage > Shared > ClientesData

	Esta es la "base de datos" de la noche: clientes Y eventos de ambiente.
	El servidor la recorre en orden.

	HAY DOS TIPOS DE ENTRADA:

	1) EVENTO DE AMBIENTE — algo pasa en el mapa (sin decisión):
	     { tipo = "evento", evento = "gato_cruza", duracion = 8 }
	   El servidor le pide al módulo Mapa que ejecute el efecto y espera
	   'duracion' segundos. Los eventos dan PISTAS: el jugador que está
	   atento sabrá qué opción es la correcta más tarde.

	2) CLIENTE — llega alguien al mostrador y presenta UNA decisión.
	   Campos:
	     id        -> texto único.
	     nombre    -> lo que ve el jugador.
	     hora      -> hora ficticia (solo se muestra).
	     dialogo   -> lo que dice el cliente.
	     npc       -> (OPCIONAL) figura que aparece en el mostrador:
	                  { tipo = "humano", color = {r, g, b} } o { tipo = "gato" }.
	     condicion -> (OPCIONAL) función(banderas) -> true/false.
	                  Si devuelve false, el cliente no aparece esta noche.
	     opciones  -> lista de decisiones. Cada una:
	         id, texto, respuesta, banderas (tabla que se enciende al elegir).

	DISEÑO DE LAS OPCIONES-SEÑUELO:
	Varias decisiones tienen 3 opciones y solo UNA es "correcta", pero el
	jugador únicamente puede estar seguro si notó un evento del mapa.
	Ejemplo: Elvira pregunta por su gato. Minutos antes, un gato blanco
	CRUZÓ la tienda hacia la trastienda (evento "gato_cruza"). Quien lo
	vio sabe la verdad; quien no, adivinará entre señuelos plausibles.

	PARA AGREGAR CONTENIDO: agrega una entrada a esta tabla. Nada más.
]]

local ClientesData = {

	-- ═══════════ CLIENTE 1: normal (calibración moral) ═══════════
	{
		id = "chico_sopa",
		nombre = "Chico con sudadera",
		hora = "10:30 PM",
		npc = { tipo = "humano", color = { 90, 90, 120 } },
		dialogo = "Oye... quiero esta sopa instantánea pero me faltan 8 pesos. Te juro que mañana te los traigo. ¿Me la fías?",
		opciones = {
			{
				id = "fiar",
				texto = "Fiarle la sopa",
				respuesta = "El chico sonríe, toma la sopa y sale corriendo. \"¡Mañana vengo, lo juro!\"",
				banderas = { fiaste_sopa = true },
			},
			{
				id = "pagar",
				texto = "Pagar los 8 pesos de tu bolsillo",
				respuesta = "Pones los 8 pesos de tu propia cartera. El chico te mira raro. \"Nadie hace eso en este turno\", dice, y se va despacio.",
				banderas = { pagaste_sopa = true },
			},
			{
				id = "negar",
				texto = "Negarle la sopa",
				respuesta = "El chico deja la sopa en el mostrador y se va sin decir nada. Afuera hace frío.",
				banderas = { negaste_sopa = true },
			},
		},
	},

	-- ═══════════ EVENTO: el gato cruza la tienda ═══════════
	-- PISTA para la decisión de Elvira. Un gato blanco entra por la
	-- puerta y se mete a la TRASTIENDA. Si el jugador estaba viendo
	-- el mapa, lo sabe. Si estaba distraído, no.
	{ tipo = "evento", evento = "gato_cruza", duracion = 9 },

	-- ═══════════ CLIENTE 2: pone a prueba tu atención ═══════════
	-- 3 opciones. Solo "trastienda" es verdad — y solo lo sabes si
	-- VISTE el evento anterior. Las otras dos son señuelos plausibles.
	{
		id = "senora_velas",
		nombre = "Señora Elvira",
		hora = "11:15 PM",
		npc = { tipo = "humano", color = { 60, 40, 70 } },
		dialogo = "Buenas noches, joven. Trece velas negras, por favor... Ah, y una pregunta: ¿no ha visto a mi gato? Blanco, con un ojo de cada color.",
		opciones = {
			{
				id = "bosque",
				texto = "\"Lo vi correr hacia el bosque\"",
				respuesta = "La señora entrecierra los ojos. \"¿El bosque? Joven... él nunca sale del pueblo. Y usted lo sabría, si de verdad lo hubiera visto.\" Paga y se va sin darte la espalda.",
				banderas = { mentiste_elvira = true },
			},
			{
				id = "trastienda",
				texto = "\"Se metió a su trastienda hace un rato\"",
				respuesta = "La señora sonríe por primera vez. \"Lo vio. Usted SÍ mira. Déjelo dormir ahí esta noche... y él lo cuidará a usted.\" Deja una moneda antigua de propina.",
				banderas = { dijiste_verdad_elvira = true },
			},
			{
				id = "no_vi",
				texto = "\"No, no he visto ningún gato\"",
				respuesta = "La señora te mira fijamente tres segundos de más. \"Qué curioso. Él sí lo vio a usted. Hace veinte minutos. Por esa puerta.\" Paga y se va.",
				banderas = { mentiste_elvira = true },
			},
		},
	},

	-- ═══════════ CLIENTE 3: paranormal ═══════════
	{
		id = "hombre_palido",
		nombre = "Hombre pálido",
		hora = "12:00 AM",
		npc = { tipo = "humano", color = { 220, 220, 225 } },
		dialogo = "Dame... lo de siempre. (No parpadea. Nunca lo has visto en tu vida, pero en la trastienda hay un frasco sin etiqueta que nadie te explicó.)",
		opciones = {
			{
				id = "dar_frasco",
				texto = "Darle el frasco de la trastienda",
				respuesta = "Toma el frasco sin mirarlo. \"Buen empleado. Los otros siempre preguntaban.\" Deja un billete que no reconoces.",
				banderas = { entregaste_frasco = true },
			},
			{
				id = "cafe",
				texto = "Ofrecerle un café del turno",
				respuesta = "Mira la taza como si fuera un objeto de museo. \"Caliente... qué detalle tan... vivo.\" No lo bebe. Se lo lleva con las dos manos, como una reliquia.",
				banderas = { ofreciste_cafe = true },
			},
			{
				id = "no_hay",
				texto = "\"No sé de qué me habla\"",
				respuesta = "Ladea la cabeza como un pájaro. \"Nuevo... ya veo. Volveré cuando sepas.\" Sale sin abrir la puerta.",
				banderas = { rechazaste_palido = true },
			},
		},
	},

	-- ═══════════ CLIENTE 4: condicional + señuelo ═══════════
	-- SOLO aparece si ayudaste al chico (fiar o pagar). Es idéntico al
	-- de antes. "Confrontarlo" solo tiene sentido si ATENDISTE al
	-- primero — el juego premia memoria, no suerte.
	{
		id = "doble_chico",
		nombre = "¿Chico con sudadera?",
		hora = "1:30 AM",
		npc = { tipo = "humano", color = { 90, 90, 120 } },
		dialogo = "Quiero esta sopa instantánea pero me faltan 8 pesos. ¿Me la fías? (Es idéntico al de hace tres horas. MISMA ropa. MISMAS palabras. Pero él ya vino... ¿no?)",
		condicion = function(banderas)
			return banderas.fiaste_sopa == true or banderas.pagaste_sopa == true
		end,
		opciones = {
			{
				id = "fiar_doble",
				texto = "Ayudarle otra vez, sin preguntar",
				respuesta = "Toma la sopa. Al salir, se detiene y dice sin voltear: \"Gracias por no preguntar.\" La puerta no suena al cerrarse.",
				banderas = { fiaste_al_doble = true },
			},
			{
				id = "nombre",
				texto = "Preguntarle su nombre",
				respuesta = "\"Me llamo...\" Se queda quieto. \"Me llamo...\" Lo intenta tres veces. No lo recuerda. Deja la sopa y se va casi corriendo.",
				banderas = { interrogaste_al_doble = true },
			},
			{
				id = "confrontar",
				texto = "\"Tú ya viniste hace rato...\"",
				respuesta = "Se queda inmóvil. \"...No. Ese no era yo.\" Deja la sopa y camina de espaldas hasta la puerta, mirándote todo el tiempo.",
				banderas = { confrontaste_al_doble = true },
			},
		},
	},

	-- ═══════════ EVENTO: las luces parpadean ═══════════
	-- PISTA para el encapuchado: cuando las luces fallan, la cámara
	-- también parpadea. Quien lo nota tiene un argumento perfecto.
	{ tipo = "evento", evento = "luces_parpadean", duracion = 6 },

	-- ═══════════ CLIENTE 5: la cámara (señuelo con pista) ═══════════
	-- "Fingir que está descompuesta" solo es creíble (y seguro) si
	-- viste el parpadeo de las luces. Si no lo viste, es apuesta ciega.
	{
		id = "encapuchado",
		nombre = "Encapuchado",
		hora = "2:45 AM",
		npc = { tipo = "humano", color = { 25, 25, 30 } },
		dialogo = "(Alguien entra con la capucha puesta y señala la cámara de seguridad.) Apágala cinco minutos. Nadie tiene que saber que estuve aquí. Te conviene.",
		opciones = {
			{
				id = "apagar",
				texto = "Apagar la cámara",
				respuesta = "Apagas la cámara. El encapuchado camina al fondo de la tienda... y cuando la enciendes de nuevo, ya no hay nadie. No escuchaste la puerta.",
				banderas = { apagaste_camara = true },
			},
			{
				id = "descompuesta",
				texto = "\"Está descompuesta desde el apagón de hace rato\"",
				respuesta = "Mira la cámara. Las luces todavía tiemblan un poco — tu historia cuadra. \"...Suerte la mía\", gruñe, y se va sin tocar nada. La cámara siguió grabando todo.",
				banderas = { enganaste_encapuchado = true, protegiste_camara = true },
			},
			{
				id = "negarse",
				texto = "Negarte",
				respuesta = "\"Mala decisión, empleado del mes.\" Se va. La cámara ahora te apunta A TI, aunque nadie la movió.",
				banderas = { protegiste_camara = true },
			},
		},
	},

	-- ═══════════ CLIENTE 6: el gato sale de la trastienda ═══════════
	{
		id = "gato",
		nombre = "Un gato blanco",
		hora = "4:00 AM",
		npc = { tipo = "gato" },
		dialogo = "(La puerta de la trastienda se abre sola. El gato blanco sale caminando, salta al mostrador y te mira como si esperara algo. Es, sin duda, el gato de la señora Elvira.)",
		opciones = {
			{
				id = "leche",
				texto = "Darle un plato de leche",
				respuesta = "El gato bebe con calma. Antes de irse, te mira y juras escuchar una voz: \"Ella lo sabrá.\"",
				banderas = { alimentaste_gato = true },
			},
			{
				id = "ignorar",
				texto = "Ignorarlo y seguir acomodando",
				respuesta = "Lo ignoras. Él no te ignora a ti. Cada vez que volteas, está un estante más cerca. Nunca lo ves moverse.",
				banderas = { ignoraste_gato = true },
			},
			{
				id = "sacarlo",
				texto = "Sacarlo de la tienda",
				respuesta = "Lo cargas hacia la puerta. Pesa demasiado para ser un gato. Al soltarlo, ya no está. Solo quedan huellas... que entran, no salen.",
				banderas = { sacaste_gato = true },
			},
		},
	},

	-- ═══════════ CLIENTE 7: el reemplazo (prueba final) ═══════════
	{
		id = "reemplazo",
		nombre = "Tu reemplazo",
		hora = "5:30 AM",
		npc = { tipo = "humano", color = { 120, 220, 160 } },
		dialogo = "Llegué temprano al turno de la mañana. Ya vete a descansar, yo cierro caja. (Levanta la cara. Es idéntico a ti. TU cara. TU uniforme. TU gafete.)",
		opciones = {
			{
				id = "entregar",
				texto = "Entregarle el turno e irte",
				respuesta = "Le das las llaves. Al salir, te ves a ti mismo detrás del mostrador, saludándote con tu propia mano...",
				banderas = { entregaste_turno = true },
			},
			{
				id = "gafete",
				texto = "Exigirle que muestre su gafete",
				respuesta = "Saca el gafete despacio. Tiene TU foto... pero el nombre está borrado, como gastado por mil lavadas. \"El nombre se pierde primero\", dice con tristeza, y se va.",
				banderas = { descubriste_gafete = true },
			},
			{
				id = "quedarse",
				texto = "\"Este es MI turno. Vete.\"",
				respuesta = "Sonríe con tu sonrisa. \"Correcto. Esa era la prueba.\" Se deshace en el aire como vapor. El reloj marca casi las 6.",
				banderas = { defendiste_turno = true },
			},
		},
	},
}

return ClientesData
