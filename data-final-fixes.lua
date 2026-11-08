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

--- Obtiene las temperature
--- @param element table # Recipe.results o Recipe.ingredients
--- @return string|number|table # Devuelve el 
function GMOD.get_temperature(element)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Temperartura
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local temperature = element.temperature

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Corrección por maximo y minimo
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if element.minimum_temperature or element.maximum_temperature then
        local Fluid = data.raw.fluid[element.name]
        temperature = {
            min = element.minimum_temperature or Fluid.default_temperature,
            max = element.maximum_temperature or (Fluid.max_temperature or Fluid.default_temperature)
        }
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Devolver el resultado
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    return temperature

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
    --- Crear el subgroup
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    Subgroup.name = new_name
    -- Subgroup.order = Order[1]
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
            local Item = GMOD.item[result.name] or {}
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

            GMOD.fluid[prototype.name] = prototype
            return
        until true

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
        --- Items
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        repeat
            if not prototype.stack_size then break end

            GMOD.item[prototype.name] = prototype
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

            GMOD.equipment[prototype.name] = prototype
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

            GMOD.entity[Item.name] = prototype
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

--- Duplicar un elemento y darle formato a las propiedades
--- @param element table # Elemento a duplicar
--- @return table|nil # Duplicado con formato o nil si no se puede duplicar
function GMOD.copy_with_format(element)
    --- Validación
    if not element then return end
    if type(element) ~= "table" then return element end
    if GMOD.get_length(element) == 0 then return end
    if not element.name then return end

    --- Duplicar el elemento
    local Copy = GMOD.copy(element)

    --- Darle formato a la propiedad "localised_name"
    if not Copy.localised_name then
        Copy.localised_name = GMOD.get_localised(element, "name")
    end

    --- Darle formato a la propiedad "localised_description"
    if not Copy.localised_description then
        Copy.localised_description = GMOD.get_localised(element, "description")
    end

    --- Darle formato a la propiedad "minable"
    GMOD.format_minable(Copy)

    --- Darle formato a la propiedad "icons"
    GMOD.format_icons(Copy)

    --- Devolver el duplicado
    return Copy
end

--- Establecer traducción para todos los elementos
--- @param element table # Elemento a traducir
--- @param localised string # Tipo de traducción a buscar
--- @return table|nil # Traducción encontrada o nil si no se encuentra
function GMOD.get_localised(element, localised)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validación
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not element then return end
    if GMOD.get_length(element) == 0 then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Traducción de los independientes
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    repeat
        --- Indicador de que se encontró el elemento
        local Key

        --- Subgrupos a buscar
        local Subgruops = {
            tile = GMOD.tiles,
            fluid = GMOD.fluid,
            entity = GMOD.entity,
            equipment = GMOD.equipment
        }

        --- Buscar el elemento en los subgrupos
        for key, subgroup in pairs(Subgruops) do
            if GMOD.get_key(subgroup, element) ~= nil then
                Key = key
                break
            end
        end

        --- Validación
        if not Key then break end

        --- Devolver la traducción
        if element["localised_" .. localised] then return element["localised_" .. localised] end
        return { "", { Key .. "-" .. localised .. "." .. element.name } }
    until true

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Traducción de los objetos y las recetas
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Traducción de los objetos
    repeat
        if not GMOD.get_key(GMOD.item, element) then break end
        local Field = "localised_" .. localised
        if element[Field] then return element[Field] end

        --- Traducción por defecto
        local Return = { "", { "item-" .. localised .. "." .. element.name } }

        --- Traducción para una entidad
        if element.place_result then
            local Entiy = GMOD.entity[element.place_result] or {}
            Return = GMOD.get_localised(Entiy, localised) or Return
        end

        --- Traducción para un suelo
        if element.place_as_tile then
            local tile = data.raw.tile[element.place_as_tile.result] or {}
            Return = GMOD.get_localised(tile, localised) or Return
        end

        --- Traducción para un equipamiento
        if element.place_as_equipment_result then
            local result = element.place_as_equipment_result
            local equipment = GMOD.equipment[result] or {}
            Return = GMOD.get_localised(equipment, localised) or Return
        end

        --- Traducción
        return Return
    until true

    --- Traducción de las recetas
    repeat
        if element.type ~= "recipe" then break end
        local Field = "localised_" .. localised
        if element[Field] then return element[Field] end

        --- Traducción por defecto
        local Return = { "", { "recipe-" .. localised .. "." .. element.name } }

        --- Recetas con varios resultados
        if #element.results ~= 1 then
            if not element.main_product or element.main_product == "" then
                --- Traducción por defecto
                Return = { "", { "recipe-" .. Field .. "." .. element.name } }
            else
                --- Usar objeto o fluido de referencia
                local result = element.main_product
                Return = GMOD.get_localised(GMOD.item[result.name] or GMOD.fluid[result.name], localised) or Return
            end
        end

        --- Receta con unico resultado
        if #element.results == 1 then
            local result = element.results[1]
            Return = GMOD.get_localised(GMOD.item[result.name] or GMOD.fluid[result.name], localised) or Return
        end

        --- Traducción
        return Return
    until true

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Traducción de las tecnologias
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    repeat
        if element.type ~= "technology" then break end
        if localised == "description" then return { "", { "technology-description." .. element.name } } end
        if element.localised_name then return element.localised_name end

        --- Renombrar
        local Full_name = element.name

        --- Separar la información
        local Name, Level = Full_name:match("(.+)-(%d+)")
        if Level then Level = " " .. (Level or "") end
        if not Name then Name = Full_name end

        --- Corrección para las tecnologías infinitas
        if element.unit and element.unit.count_formula then
            Level = nil
        end

        --- Traducción
        return { "", { "technology-name." .. Name }, Level }
    until true

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Darle formato a la propiedad "minable"
--- @param element table # Elemento a formatear
function GMOD.get_format_minable(element)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validar
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not element.minable then return end
    if not element.minable.result and not element.minable.results then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Dar el formato deseado
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Devolver los resultados
    if element.minable.results then
        return element.minable.results
    end


    --- Darle formato a la propiedad
    return { {
        type = "item",
        name = element.minable.result,
        amount = element.minable.count or 1
    } }

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Darle formato a la propiedad "minable"
--- @param element table # Elemento a formatear
function GMOD.format_minable(element)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validar
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if not element.minable then return end
    if not element.minable.result then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Dar el formato deseado
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Darle formato a la propiedad
    element.minable.results = { {
        type = "item",
        name = element.minable.result,
        amount = element.minable.count or 1
    } }

    --- Eliminar las propiedades
    element.minable.result = nil
    element.minable.count = nil

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Darle formato a la propiedad "icons"
--- @param element table # Elemento a formatear
function GMOD.format_icons(element)
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Validar
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if element.icons then return end
    if not element.icon then return end
    if type(element.icon) ~= "string" then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Dar el formato deseado
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Darle formato a la propiedad
    element.icons = { {
        icon = element.icon,
        icon_size = element.icon_size ~= 64 and element.icon_size or nil
    } }

    --- Eliminar las propiedades
    element.icon = nil
    element.icon_size = nil

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
    --- GMOD.item
    --- GMOD.tiles
    --- GMOD.fluid
    --- GMOD.recipes
    --- GMOD.entity
    --- GMOD.equipment
    This_MOD.filter_data()

    --- Clasificar la información de settings.startup
    --- GMOD.Setting
    This_MOD.load_setting()

    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Funciones locales ]---
---------------------------------------------------------------------------------------------------

--- Clasificar la información de data.raw
--- GMOD.item
--- GMOD.tiles
--- GMOD.fluid
--- GMOD.entity
--- GMOD.recipes
--- GMOD.equipment
function This_MOD.filter_data()
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Contenedores finales
    --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    GMOD.entity = {}
    GMOD.equipment = {}
    GMOD.fluid = {}
    GMOD.item = {}
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
            if result.type == "item" then GMOD.item[result.name] = true end
            if result.type == "fluid" then GMOD.fluid[result.name] = true end
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Guardar referencia de los ingredientes
        for _, ingredient in pairs(recipe.ingredients or {}) do
            if ingredient.type == "item" then GMOD.item[ingredient.name] = true end
            if ingredient.type == "fluid" then GMOD.fluid[ingredient.name] = true end
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
            if not GMOD.item[result.name] then
                GMOD.item[result.name] = true
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

    --- Agregar el item a GMOD.item
    local function add_item(item)
        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Validación
        if not item.stack_size then return end
        if GMOD.is_hidde(item) then return end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Guardar objeto
        GMOD.item[item.name] = item

        --- Guardar suelo de no estarlo
        if item.place_as_tile and not GMOD.tiles[item.name] then
            local Tile = data.raw.tile[item.place_as_tile.result]
            GMOD.tiles[item.name] = GMOD.tiles[item.name] or {}
            table.insert(GMOD.tiles[item.name], Tile)
        end

        --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

        --- Validar las propiedades
        for index, property in pairs({
            entity = "place_result",
            equipment = "place_as_equipment_result"
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
    for name, _ in pairs(GMOD.fluid) do
        local Fluid = data.raw.fluid[name]
        if Fluid then GMOD.fluid[name] = Fluid end
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
    for _, elements in pairs({ GMOD.entity, GMOD.equipment }) do
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
                        if elements == GMOD.entity then
                            if GMOD.is_hidde(element) then break end
                            if not element.max_health then break end
                        end

                        --- Equipos
                        if elements == GMOD.equipment then
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
        Item = GMOD.item,
        Tile = GMOD.tiles,
        Fluid = GMOD.fluid,
        Entity = GMOD.entity,
        Equipment = GMOD.equipment
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





---------------------------------------------------------------------------------------------------
---[ Iniciar el MOD ]---
---------------------------------------------------------------------------------------------------

This_MOD.start()

---------------------------------------------------------------------------------------------------
