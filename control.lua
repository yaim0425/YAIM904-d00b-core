---------------------------------------------------------------------------------------------------
---[ control.lua ]---
---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Validar si se cargó antes ]---
---------------------------------------------------------------------------------------------------

if GMOD and GMOD.name then return end

---------------------------------------------------------------------------------------------------






---------------------------------------------------------------------------------------------------
---[ Cargar las funciones y constantes ]---
---------------------------------------------------------------------------------------------------

require("__CONSTANTS__")
require("__FUNCTIONS__")

---------------------------------------------------------------------------------------------------






---------------------------------------------------------------------------------------------------
---[ Funciones globales ]---
---------------------------------------------------------------------------------------------------

--- Crea un consolidado de variables para usar en tiempo de ejecuión
--- @param event table
--- @param that_mod table
--- @return table
function GMOD.create_data(event, that_mod)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Contenedor de datos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Variable de salida
    local Data = { Event = event }

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Identificar la entidad
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Entidad en el evento
    if event.entity and event.entity.valid then
        Data.Entity = event.entity
    elseif event.created_entity and event.created_entity.valid then
        Data.Entity = event.created_entity
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Identificar al jugador
    if event.Player then
        Data.Player = event.Player
    end

    if event.player_index then
        Data.Player = game.get_player(event.player_index)
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Identificar los forces
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- El force está en el evento dado
    Data.Force = event.force or nil

    --- El force está en el jugador
    if Data.Player and type(Data.Player.force) ~= "string" then
        Data.Force = Data.Player.force
    end

    --- El force se debe buscar busca
    if Data.Player and type(Data.Player.force) == "string" then
        Data.Force = game.forces[Data.Player.force]
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Buscar y crear los forces
    for Key, Value in pairs({ player = Data.Player, entity = Data.Entity }) do
        --- Agregar prefijo
        Key = "Force_" .. Key

        --- Cargar el force de forma directa
        if type(Value.force) ~= "string" then
            Data[Key] = Value.force
        end

        --- Cargar el force usando el nombre o id
        if type(Value.force) == "string" then
            Data[Key] = game.forces[Value.force]
        end
    end

    --- Reducir los forces a uno de ser posible
    if Data.Force_player and Data.Force_player == Data.Force_entity then
        Data.Force = Data.Force_entity
    elseif not Data.Force_player and Data.Force_entity then
        Data.Force = Data.Force_entity
    elseif Data.Force_player and not Data.Force_entity then
        Data.Force = Data.Force_player
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Crear el espacio guardable y NO guardable
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Espacio guardable para TODOS los MODs
    storage[GMOD.name] = storage[GMOD.name] or {}
    Data.gPrefix = storage[GMOD.name]

    --- Espacio guardable para este MOD
    Data.gPrefix[that_mod.id] = Data.gPrefix[that_mod.id] or {}
    Data.gMOD = Data.gPrefix[that_mod.id]

    --- Crear el espacio guardable para los forces
    Data.gMOD.Forces = Data.gMOD.Forces or {}
    Data.gForces = Data.gMOD.Forces

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear el espacio NO guardable para los forces
    that_mod.forces = that_mod.forces or {}
    Data.GForces = that_mod.forces

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Crear el espacio para un forces
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, force in pairs({ Data.Force_entity, Data.Force_player, Data.Force }) do
        --- Espacio guardable
        Data.gForce = Data.gForces
        Data.gForce[force.index] = Data.gForce[force.index] or {}
        Data.gForce = Data.gForce[force.index]

        --- Espacio NO guardable
        Data.GForce = Data.GForces
        Data.GForce[force.index] = Data.GForce[force.index] or {}
        Data.GForce = Data.GForce[force.index]
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Espacio para los jugadores
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Espacio NO guardable para los jugadores
    that_mod.players = that_mod.players or {}
    Data.GPlayers = that_mod.players

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Espacio guardable para los jugadores
    Data.gMOD.Players = Data.gMOD.Players or {}
    Data.gPlayers = Data.gMOD.Players

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- No se tiene un jugador
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not Data.Player then return Data end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Crear el espacio para un jugador
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Identificador del jugador
    local ID_Player = Data.Player.index

    --- Espacio NO guardable del jugador
    Data.GPlayers[ID_Player] = Data.GPlayers[ID_Player] or {}
    Data.GPlayer = Data.GPlayers[ID_Player]

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Espacio guardable del jugador
    Data.gPlayers[ID_Player] = Data.gPlayers[ID_Player] or {}
    Data.gPlayer = Data.gPlayers[ID_Player]

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Espacio para el GUI
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    Data.gPlayer.GUI = Data.gPlayer.GUI or {}
    Data.GUI = Data.gPlayer.GUI

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Devolver el consolidado de los datos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    return Data

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Información del MOD ]---
---------------------------------------------------------------------------------------------------

local This_MOD = GMOD.get_id_and_name()
if not This_MOD then return end
GMOD[This_MOD.id] = This_MOD

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Inicio del MOD ]---
---------------------------------------------------------------------------------------------------

function This_MOD.start()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Clasificar la información de data.raw
    This_MOD.filter_data()

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Funciones locales ]---
---------------------------------------------------------------------------------------------------

--- Crearción de:
--- GMOD.item
--- GMOD.tiles
--- GMOD.fluid
--- GMOD.recipes
--- GMOD.entity
--- GMOD.equipment
function This_MOD.filter_data()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Agregar el suelo a GMOD.Tiles
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function addTitle(tile)
        local results = tile.mineable_properties.products
        if not results then return end

        for _, result in pairs(results) do
            GMOD.tiles[result.name] = GMOD.tiles[result.name] or {}
            table.insert(GMOD.tiles[result.name], tile)
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Agregar la receta a GMOD.recipes
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function addRecipe(recipe)
        local results = recipe.products
        if not results then return end

        for _, result in pairs(results) do
            GMOD.recipes[result.name] = GMOD.tiles[result.name] or {}
            table.insert(GMOD.recipes[result.name], recipe)
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Crear la  estructura
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Renombrar las variables
    GMOD.item = prototypes.item
    GMOD.fluid = prototypes.fluid
    GMOD.entity = prototypes.entity
    GMOD.equipment = prototypes.equipment

    --- Agrupar los suelos
    GMOD.tiles = {}
    for _, tile in pairs(prototypes.tile) do
        addTitle(tile)
    end

    --- Agrupar las recetas
    GMOD.recipes = {}
    for _, recipe in pairs(prototypes.recipe) do
        addRecipe(recipe)
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Iniciar el MOD ]---
---------------------------------------------------------------------------------------------------

This_MOD.start()

---------------------------------------------------------------------------------------------------
