---------------------------------------------------------------------------------------------------
---[ data-final-fixes.lua ]---
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

--- Validar si está oculta
--- @param element table
--- @return boolean
function GMOD.is_hidde(element)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Validar los valores
    local Hidden = false
    Hidden = Hidden or element.hidden
    Hidden = Hidden or element.parameter
    Hidden = Hidden or GMOD.get_key(element.flags or {}, "hidden")

    --- Devolver el resultado
    return Hidden

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Crea un subgroup despues del dado
--- @param old_name string # Nombre del subgrupo a duplicar
--- @param new_name string # Nombre a asignar al duplicado
--- @return any # Devuelve el duplicado
--- o una tabla vacio si se poduce un error
function GMOD.duplicate_subgroup(old_name, new_name)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if type(old_name) ~= "string" then return end
    if type(new_name) ~= "string" then return end
    if GMOD.subgroups[new_name] then return end
    local Subgroup = GMOD.copy(GMOD.subgroups[old_name])
    if not Subgroup then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Buscar un order disponible
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Order de referencia
    local Order = {}
    Order[1] = Subgroup.order
    Order[2] = math.floor(tonumber(Order[1]) / 10) * 10
    Order[3] = Order[2]

    --- Buscar el siguiente order
    while true do
        Order[2] = Order[2] + 1
        if Order[2] - Order[3] > 9 then return end
        Order[1] = GMOD.pad_left_zeros(#Order[1], Order[2])

        for _, subgroup in pairs(GMOD.subgroups) do
            if subgroup.group == Subgroup.group then
                Order[4] = subgroup.order == Order[1]
                if Order[4] then break end
            end
        end
        if not Order[4] then break end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Crear el subgroup
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    Subgroup.name = new_name
    Subgroup.order = Order[1]
    data:extend({ Subgroup })
    return Subgroup

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Obtiene el objeto que crea la entidad dada
--- @param element table
--- @return any
function GMOD.get_item_create(element, propiety)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not element.minable then return end
    if not element.minable.results then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Buscar el objeto
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, result in pairs(element.minable.results) do
        if result.type == "item" then
            local Item = GMOD.items[result.name] or {}
            local Value = Item[propiety]
            if propiety == "place_as_tile" then
                Value = Value and Value.result or nil
            end
            if Value and Value == element.name then
                return Item
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Devuelve la tecnología que desbloquea una o varias recetas
--- @param value table # receta (tabla con .name) o lista de recetas
--- @return table|nil # Tecnología que desbloquea la receta o recetas
function GMOD.get_technology(value, only_result)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Lista de nombres de recetas
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Validación
    if type(value) == "nil" then return end

    --- Enlistar las recetas
    local Recipe_list = {}
    if type(value) == "string" then
        table.insert(Recipe_list, value)
    elseif value.name then
        table.insert(Recipe_list, value.name)
    elseif type(value) == "table" then
        for _, r in pairs(value) do
            if type(r) == "string" then
                table.insert(Recipe_list, r)
            elseif type(r) == "table" and r.name then
                table.insert(Recipe_list, r.name)
            end
        end
    end

    --- Validación
    if #Recipe_list == 0 then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Función auxiliar para comparar dos tecnologías
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function compare(old, new, expensive)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        if not old then return new end
        if not new then return old end

        local Old_unit = old.unit or {}
        local New_unit = new.unit or {}

        local Old_count = Old_unit.count or (Old_unit.count_formula and math.huge) or 0
        local New_count = New_unit.count or (New_unit.count_formula and math.huge) or 0

        local Old_ingredients = Old_unit.ingredients and #Old_unit.ingredients or 0
        local New_ingredients = New_unit.ingredients and #New_unit.ingredients or 0

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        -- Si buscamos la más barata
        if not expensive then
            if Old_ingredients ~= New_ingredients then
                return (Old_ingredients > New_ingredients) and new or old
            elseif Old_count ~= New_count then
                return (Old_count > New_count) and new or old
            else
                return (new.name < old.name) and new or old -- desempate por nombre
            end
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        -- Si buscamos la más cara
        if Old_ingredients ~= New_ingredients then
            return (Old_ingredients < New_ingredients) and new or old
        elseif Old_count ~= New_count then
            return (Old_count < New_count) and new or old
        else
            return (new.name > old.name) and new or old -- desempate por nombre
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Buscar tecnologías que desbloquean las recetas
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function find_techs_for_recipes(recipes)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        local Techs = {}
        for _, tech in pairs(data.raw.technology) do
            for _, effect in pairs(tech.effects or {}) do
                if effect.type == "unlock-recipe" then
                    for _, recipe_name in ipairs(recipes) do
                        if effect.recipe == recipe_name then
                            Techs[tech.name] = tech
                        end
                    end
                end
            end
        end
        return Techs

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Buscar tecnologías directas
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Recipe_techs = find_techs_for_recipes(Recipe_list)

    if next(Recipe_techs) then
        local Key = next(Recipe_techs)
        local Selected = Recipe_techs[Key]
        for _, tech in pairs(Recipe_techs) do
            Selected = compare(Selected, tech, false)
        end
        return Selected
    end

    if only_result then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Si no hay directas, buscar por los ingredientes
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Ingredient_recipes = {}
    for _, recipe_name in ipairs(Recipe_list) do
        local Recipe = data.raw.recipe[recipe_name]
        for _, ingredient in pairs(Recipe.ingredients) do
            local Name = ingredient.name or ingredient[1]
            for _, recipe in pairs(GMOD.recipes[Name] or {}) do
                table.insert(Ingredient_recipes, recipe.name)
            end
        end
    end

    local Ingredient_techs = find_techs_for_recipes(Ingredient_recipes)

    if next(Ingredient_techs) then
        local Key = next(Ingredient_techs)
        local Selected = Ingredient_techs[Key]
        for _, tech in pairs(Ingredient_techs) do
            Selected = compare(Selected, tech, true)
        end
        return Selected
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Elimina el indicador del nombre dado
--- @param name string # __Ejemplo:__ prefix-i0MOD00-i0MOD20-name
--- @return string # __Ejemplo:__ # i0MOD00-i0MOD20-name
---- __ids-name,__ si se cumple el patron
---- o el nombre dado si no es así
function GMOD.delete_prefix(name)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    return name:gsub(GMOD.name .. "%-", "") or name

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Cargar los prototipos al juego
--- @param ... any
function GMOD.extend(...)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Renombrar los parametros dados
    local Prototypes = { ... }
    if #Prototypes == 0 then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Clasificar y guardar el prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function extend(prototype)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Recipes
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if prototype.type ~= "recipe" then break end

            for _, result in pairs(prototype.results) do
                if result.type == "item" then
                    GMOD.recipes[result.name] = GMOD.recipes[result.name] or {}
                    table.insert(GMOD.recipes[result.name], prototype)
                end
            end
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Fluids
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if prototype.type ~= "fluid" then break end

            GMOD.fluids[prototype.name] = prototype
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Items
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if not prototype.stack_size then break end

            GMOD.items[prototype.name] = prototype
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Tiles
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if prototype.type ~= "tile" then break end
            local Item = GMOD.get_item_create(prototype, "place_as_tile")
            if not Item then break end

            GMOD.tiles[Item.name] = GMOD.tiles[Item.name] or {}
            table.insert(GMOD.tiles[Item.name], prototype)
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Equipments
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if not prototype.shape then break end

            GMOD.equipments[prototype.name] = prototype
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Entities
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if not prototype.max_health then break end
            if GMOD.is_hidde(prototype) then break end
            local Item = GMOD.get_item_create(prototype, "place_result")
            if not Item then break end

            GMOD.entities[Item.name] = prototype
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Guardar el nuevo prototipo
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, arg in pairs(Prototypes) do
        data:extend({ arg })
        extend(arg)
    end

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

    --- Darle formato a las propiedades
    This_MOD.format_minable()
    This_MOD.format_icons()

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Clasificar la información de data.raw
    --- GMOD.items
    --- GMOD.tiles
    --- GMOD.fluids
    --- GMOD.recipes
    --- GMOD.entities
    --- GMOD.equipments
    This_MOD.filter_data()

    --- Clasificar la información de settings.startup
    --- GMOD.Setting
    This_MOD.load_setting()

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Cambiar los orders de los elementos
    This_MOD.change_orders(true)

    --- Establecer traducción en todos los elementos
    This_MOD.set_localised()

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Funciones locales ]---
---------------------------------------------------------------------------------------------------

--- Darle formato a la propiedad "minable"
function This_MOD.format_minable()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Hacer el cambio
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function format(element)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Validar
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        if not element.minable then return end
        if not element.minable.result then return end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Dar el formato deseado
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        element.minable.results = { {
            type = "item",
            name = element.minable.result,
            amount = element.minable.count or 1
        } }

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Hacer el cambio
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, elements in pairs(data.raw) do
        for _, element in pairs(elements) do
            format(element)
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Darle formato a la propiedad "icons"
function This_MOD.format_icons()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Hacer el cambio
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local function format(element)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Validar
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        if element.icons then return end
        if not element.icon then return end
        if type(element.icon) ~= "string" then return end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Dar el formato deseado
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        element.icons = { {
            icon = element.icon,
            icon_size = element.icon_size ~= 64 and element.icon_size or nil
        } }

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Hacer el cambio
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, elements in pairs(data.raw) do
        for _, element in pairs(elements) do
            format(element)
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

--- Clasificar la información de data.raw
--- GMOD.items
--- GMOD.tiles
--- GMOD.fluids
--- GMOD.recipes
--- GMOD.entities
--- GMOD.equipments
function This_MOD.filter_data()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Contenedores finales
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    GMOD.entities = {}
    GMOD.equipments = {}
    GMOD.fluids = {}
    GMOD.items = {}
    GMOD.recipes = {}
    GMOD.tiles = {}

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Agrega las Recetas, Suelos y Objetos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Agregar la receta a GMOD.recipes
    local function add_recipe(recipe)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Vaidación
        if GMOD.is_hidde(recipe) then return end
        recipe.energy_required = recipe.energy_required or 0.5

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Recorrer los resultados
        for _, result in pairs(recipe.results or {}) do
            --- Espacio a usar
            local Recipes = GMOD.recipes[result.name] or {}
            GMOD.recipes[result.name] = Recipes

            --- Agregar la receta si no se encuentra
            local Found = GMOD.get_key(Recipes, recipe)
            if not Found then table.insert(Recipes, recipe) end

            --- Guardar referencia del resultado
            if result.type == "item" then GMOD.items[result.name] = true end
            if result.type == "fluid" then GMOD.fluids[result.name] = true end
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Guardar referencia de los ingredientes
        for _, ingredient in pairs(recipe.ingredients or {}) do
            if ingredient.type == "item" then GMOD.items[ingredient.name] = true end
            if ingredient.type == "fluid" then GMOD.fluids[ingredient.name] = true end
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- Agregar el suelo a GMOD.tiles
    local function add_tile(tile)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Validación
        if not tile.minable then return end
        if not tile.minable.results then return end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Verificar cada resultado
        for _, result in pairs(tile.minable.results) do
            --- El suelo no tiene receta
            if not GMOD.items[result.name] then
                GMOD.items[result.name] = true
            end

            --- Espacio a usar
            local Titles = GMOD.tiles[result.name] or {}
            GMOD.tiles[result.name] = Titles

            --- Agregar el suelo si no se encuentra
            local Found = GMOD.get_key(Titles, tile)
            if not Found then table.insert(Titles, tile) end
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- Agregar el item a GMOD.items
    local function add_item(item)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Validación
        if not item.stack_size then return end
        if GMOD.is_hidde(item) then return end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Guardar objeto
        GMOD.items[item.name] = item

        --- Guardar suelo de no estarlo
        if item.place_as_tile and not GMOD.tiles[item.name] then
            local Tile = data.raw.tile[item.place_as_tile.result]
            GMOD.tiles[item.name] = GMOD.tiles[item.name] or {}
            table.insert(GMOD.tiles[item.name], Tile)
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Validar las propiedades
        for index, property in pairs({
            entities = "place_result",
            equipments = "place_as_equipment_result"
        }) do
            if item[property] then
                --- Objeto de igual nombre que el resultado
                if item[property] == item.name then
                    GMOD[index][item.name] = true
                end

                --- Objeto de distinto nombre que el resultado
                if item[property] ~= item.name then
                    GMOD[index][item[property]] = true
                    GMOD[index][item.name] = item[property]
                end
            end
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cargar las Recetas, Suelos, Fluidos y Objetos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Recorrer las recetas
    for _, recipe in pairs(data.raw.recipe) do
        add_recipe(recipe)
    end

    --- Cargar los fluidos
    for name, _ in pairs(GMOD.fluids) do
        local Fluid = data.raw.fluid[name]
        if Fluid then GMOD.fluids[name] = Fluid end
    end

    --- Cargar los suelos
    for _, tile in pairs(data.raw.tile) do
        add_tile(tile)
    end

    --- Cargar los objetos
    for _, array in pairs(data.raw) do
        for _, item in pairs(array) do
            add_item(item)
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Buscar y cargar las Entidades y los Equipos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Evitar estos tipos
    local Ignore_types = {
        tile = true,
        fluid = true,
        recipe = true
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Recorrer los elementos
    for _, elements in pairs({ GMOD.entities, GMOD.equipments }) do
        --- Cargar de forma directa
        for name, value in pairs(elements) do
            if type(value) == "boolean" then
                for _, element in pairs(data.raw) do
                    --- Buscar la entidad
                    element = element[name]

                    --- El ciclo es solo para saltar
                    --- elementos no deseados
                    repeat
                        --- Validación
                        if not element then break end
                        if Ignore_types[element.type] then break end

                        --- Entidades
                        if elements == GMOD.entities then
                            if GMOD.is_hidde(element) then break end
                            if not element.max_health then break end
                        end

                        --- Equipos
                        if elements == GMOD.equipments then
                            if not element.shape then break end
                            if not element.sprite then break end
                        end

                        --- Guardar
                        elements[name] = element
                    until true
                end
            end
        end

        --- Cargar de forma indirecta
        for name, value in pairs(elements) do
            if type(value) == "string" then
                elements[name] = elements[value]
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Eliminar los elementos que no se pudieron cargar
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Variable contenedora
    local Info = ""
    local Delete = {}
    local Array = {
        Item = GMOD.items,
        Tile = GMOD.tiles,
        Fluid = GMOD.fluids,
        Entity = GMOD.entities,
        Equipment = GMOD.equipments
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Identificar valores vacios
    for iKey, elemnts in pairs(Array) do
        for jKey, elemnt in pairs(elemnts) do
            if type(elemnt) == "boolean" then
                Info = Info .. "\n\t\t"
                Info = Info .. iKey .. " not found or hidden: " .. jKey
                table.insert(Delete, { elemnts, jKey })
            end
        end
    end

    --- Eliminar valores vacios
    for _, value in pairs(Delete) do
        value[1][value[2]] = nil
    end

    --- Imprimir un informe de lo eliminados
    if #Delete >= 1 then log(Info) end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Clasificar la información de settings.startup
--- GMOD.Setting
function This_MOD.load_setting()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if GMOD.setting then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Cargar las opciones de configuración
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicializar el contenedor
    GMOD.setting = {}

    --- Recorrer las opciones de configuración
    for option, value in pairs(settings.startup) do
        --- Separar los datos esperados
        local That_MOD = GMOD.get_id_and_name(option)

        --- Validar los datos obtenidos
        if That_MOD then
            GMOD.setting[That_MOD.id] = GMOD.setting[That_MOD.id] or {}
            GMOD.setting[That_MOD.id][That_MOD.name] = value.value
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

--- Cambiar los orders de los elementos
function This_MOD.change_orders(agroup_recipe)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Inicializar las vaiables
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Orders = {}
    local Source = {}
    local N = 0

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Grupos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicializar las vaiables
    Orders = {}
    Source = {}

    --- Agrupar los Grupos
    for _, element in pairs(data.raw["item-group"]) do
        if element.order then
            table.insert(Source, element)
            table.insert(Orders, element.order)
        end
    end

    --- Cantidad de afectados
    N = GMOD.get_length(data.raw["item-group"])
    N = GMOD.digit_count(N)

    --- Ordenear los orders
    table.sort(Orders)

    --- Cambiar el order de los subgrupos
    for iKey, order in pairs(Orders) do
        for jKey, element in pairs(Source) do
            if element.order == order then
                element.order = 5 .. GMOD.pad_left_zeros(N, iKey) .. 0
                table.remove(Source, jKey)
                break
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Subgrupos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicializar las vaiables
    Orders = {}
    Source = {}

    --- Agrupar los subgroups
    for _, element in pairs(GMOD.subgroups) do
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        Source[element.group] = Source[element.group] or {}
        table.insert(Source[element.group], element)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        Orders[element.group] = Orders[element.group] or {}
        table.insert(Orders[element.group], element.order or element.name)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    end

    --- Cambiar el order de los subgrupos
    for subgroup, orders in pairs(Orders) do
        --- Ordenear los orders
        table.sort(orders)

        --- Cantidad de afectados
        N = GMOD.get_length(orders)
        N = GMOD.digit_count(N)

        --- Remplazar los orders
        for iKey, order in pairs(orders) do
            for jKey, element in pairs(Source[subgroup]) do
                if element.order == order then
                    element.order = 5 .. GMOD.pad_left_zeros(N, iKey) .. 0
                    table.remove(Source[subgroup], jKey)
                    break
                end
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Agrupar los objetos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicializar las vaiables
    local Items = {}

    --- Agrupar los objetos
    for _, values in pairs(data.raw) do
        for _, value in pairs(values) do
            if value.stack_size then
                table.insert(Items, value)
                if not value.subgroup then
                    value.subgroup = "other"
                end
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Objetos, recetas y fluidos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicializar las vaiables
    Orders = {}
    Source = {}

    --- Posicionar los objetos y fluidos
    for _, elements in pairs({ Items, GMOD.fluids }) do
        for _, element in pairs(elements) do
            if element.subgroup then
                --- Elementos a agrupar
                Source[element.subgroup] = Source[element.subgroup] or {}
                table.insert(Source[element.subgroup], element)

                --- Elementos a ordenar
                element.order = element.order or element.name
                Orders[element.subgroup] = Orders[element.subgroup] or {}
                table.insert(Orders[element.subgroup], element.order)
            end
        end
    end

    for _, recipe in pairs(
        agroup_recipe and
        data.raw.recipe or
        {}
    ) do
        repeat
            --- Validación
            if not recipe.subgroup then break end
            if not recipe.results then break end
            if #recipe.results == 0 then break end

            --- Elementos a agrupar
            Source[recipe.subgroup] = Source[recipe.subgroup] or {}
            table.insert(Source[recipe.subgroup], recipe)

            --- Elementos a ordenar
            Orders[recipe.subgroup] = Orders[recipe.subgroup] or {}
            table.insert(Orders[recipe.subgroup], recipe.order)
        until true
    end

    --- Cambiar el order de los subgrupos
    for subgroup, orders in pairs(Orders) do
        --- Ordenear los orders
        table.sort(orders)

        --- Cantidad de afectados
        N = GMOD.get_length(orders)
        N = GMOD.digit_count(N)

        --- Remplazar los orders
        for iKey, order in pairs(orders) do
            for jKey, element in pairs(Source[subgroup]) do
                if element.order == order then
                    element.order = 5 .. GMOD.pad_left_zeros(N, iKey) .. 0
                    table.remove(Source[subgroup], jKey)
                    break
                end
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Agrupar las recetas con los objetos o fluidos
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicializar las vaiables
    Orders = {}

    --- Recorrer las recetas
    for _, recipe in pairs(
        agroup_recipe and
        data.raw.recipe or
        {}
    ) do
        repeat
            --- Validación
            if recipe.subgroup then break end
            if not recipe.results then break end
            if #recipe.results == 0 then break end
            if recipe.results[1].type ~= "item" then break end
            local Item = GMOD.items[recipe.results[1].name]
            if not Item then break end

            --- Posición actual
            Orders[Item.name] =
                Orders[Item.name] or
                tonumber(Item.order:sub(2))

            --- Igualar subgrupo
            recipe.subgroup = Item.subgroup

            --- Cambiar la posición
            recipe.order = 5 .. GMOD.pad_left_zeros(
                #Item.order - 1,
                Orders[Item.name]
            )

            --- Preparar la siguiente posición
            Orders[Item.name] = Orders[Item.name] + 1
        until true
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Establecer traducción en todos los elementos
function This_MOD.set_localised()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Traducir estas secciones
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Establecer la traducción
    for name, subgroup in pairs({
        tile = GMOD.tiles,
        fluid = GMOD.fluids,
        entity = GMOD.entities,
        equipment = GMOD.equipments
    }) do
        if name ~= "tile" then subgroup = { subgroup } end
        for _, elements in pairs(subgroup) do
            for _, element in pairs(elements) do
                if element.localised_name then
                    if type(element.localised_name) == "table" and element.localised_name[1] ~= "" then
                        element.localised_name = { "", element.localised_name }
                    end
                end
                if not element.localised_name then
                    element.localised_name = { "", { name .. "-name." .. element.name } }
                end
                if not element.localised_description then
                    element.localised_description = { "", { name .. "-description." .. element.name } }
                end
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Funciones a usar
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Establece el nombre de la receta
    local function set_localised(name, recipe, field)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Valores a usar
        local Field = "localised_" .. field
        local Fluid = GMOD.fluids[name]
        local Item = GMOD.items[name]

        --- El resultado es un objeto
        if Item then
            --- Nombre del objeto por defecto
            recipe[Field] = Item[Field]

            --- Traducción para una entidad
            if Item.place_result then
                local Entiy = GMOD.entities[Item.place_result] or {}
                Item[Field] = Entiy[Field]
                recipe[Field] = Entiy[Field]
            end

            --- Traducción para un suelo
            if Item.place_as_tile then
                local tile = data.raw.tile[Item.place_as_tile.result] or {}
                Item[Field] = tile[Field]
                recipe[Field] = tile[Field]
            end

            --- Traducción para un equipamiento
            if Item.place_as_equipment_result then
                local result = Item.place_as_equipment_result
                local equipment = GMOD.equipments[result] or {}
                Item[Field] = equipment[Field]
                recipe[Field] = equipment[Field]
            end
        end

        --- El resultado es un liquido
        if Fluid then recipe[Field] = Fluid[Field] end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Traducción de los objetos y las recetas
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Establecer la traducción de los objetos
    for _, item in pairs(GMOD.items) do
        if item.localised_name then
            if type(item.localised_name) == "table" and item.localised_name[1] ~= "" then
                item.localised_name = { "", item.localised_name }
            end
        end
        for _, field in pairs({ "name", "description" }) do
            local Field = "localised_" .. field
            if not item[Field] then
                item[Field] = { "", { "item-" .. field .. "." .. item.name } }
                set_localised(item.name, {}, field)
            end
        end
    end

    --- Establecer la traducción en la receta
    for _, recipes in pairs(GMOD.recipes) do
        if recipes.localised_name then
            if type(recipes.localised_name) == "table" and recipes.localised_name[1] ~= "" then
                recipes.localised_name = { "", recipes.localised_name }
            end
        end

        for _, recipe in pairs(recipes) do
            for _, field in pairs({ "name", "description" }) do
                local Field = "localised_" .. field
                --- Establece el nombre de la receta
                if not recipe[Field] then
                    --- Recetas con varios resultados
                    if #recipe.results ~= 1 then
                        if not recipe.main_product or recipe.main_product == "" then
                            --- Traducción por defecto
                            recipe[Field] = { "", { "recipe-" .. field .. "." .. recipe.name } }
                        else
                            --- Usar objeto o fluido de referencia
                            set_localised(recipe.main_product, recipe, field)
                        end
                    end

                    --- Receta con unico resultado
                    if #recipe.results == 1 then
                        local result = recipe.results[1]
                        set_localised(result.name, recipe, field)
                    end
                end
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Traducción de las tecnologias
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Actualizar el apodo del nombre
    for _, tech in pairs(data.raw.technology) do
        --- Renombrar
        local Full_name = tech.name

        --- Separar la información
        local Name, Level = Full_name:match("(.+)-(%d+)")
        if Level then Level = " " .. (Level or "") end
        if not Name then Name = Full_name end

        --- Corrección para las tecnologías infinitas
        if tech.unit and tech.unit.count_formula then
            Level = nil
        end

        --- Construir el apodo
        if tech.localised_name then
            if tech.localised_name[1] ~= "" then
                tech.localised_name = { "", tech.localised_name }
            end
        else
            tech.localised_name = { "", { "technology-name." .. Name }, Level }
        end
        tech.localised_description = { "", { "technology-description." .. Name } }
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Iniciar el MOD ]---
---------------------------------------------------------------------------------------------------

This_MOD.start()

---------------------------------------------------------------------------------------------------
