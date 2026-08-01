---------------------------------------------------------------------------------------------------
---[ __CONSTANTS__.lua ]---
---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Valiación ]---
---------------------------------------------------------------------------------------------------

--- Validar si se cargó antes
if _G.GMOD then return end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Inicializar el contenedor ]---
---------------------------------------------------------------------------------------------------

--- Contenedor global para TODOS los MODs de YAIM904
_G.GMOD = _G.GMOD or {}

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Constantes globales ]---
---------------------------------------------------------------------------------------------------

--- Prefijo a usar en los MODs
GMOD.name = "YAIM904"

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------
---[ Constantes adicionales ]---
---------------------------------------------------------------------------------------------------

--- Validación
if not data then return end
if not data.raw then return end
if not data.raw["item-subgroup"] then return end
if not data.raw["virtual-signal"] then return end

--- Para que Visual Studio Code no moleste
_G.log = _G.log or nil
_G.prototypes = _G.prototypes or nil
_G.settings = _G.settings or nil
_G.defines = _G.defines or nil
_G.helpers = _G.helpers or nil
_G.script = _G.script or nil
_G.game = _G.game or nil
_G.mods = _G.mods or nil

--- Subgrupos existentes, se usa con frecuencia
GMOD.subgroups = data.raw["item-subgroup"]

--- Señales virtuales existentes, se usa con frecuencia
GMOD.signal = {}
for key, value in pairs(data.raw["virtual-signal"]) do
    key = key:gsub("signal%-", "")
    key = key:gsub("shape%-", "")
    GMOD.signal[key] = value.icon
end

---------------------------------------------------------------------------------------------------

--- Parametros para las funciones
GMOD.parameter = {}
GMOD.parameter.get_item_create = {}
GMOD.parameter.get_item_create.place_result = "place_result"
GMOD.parameter.get_item_create.place_as_tile = "place_as_tile"

---------------------------------------------------------------------------------------------------
