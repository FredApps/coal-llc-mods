class_name IngenitusBugFixesMod
extends Node

const MOD_ID := "ingenitus-bug_fixes_mod"
const MOD_DIR := "ingenitus-bug_fixes_mod"
const LOG_NAME := "ingenitus-bug_fixes_mod:Main"

# Config key -> settings-tab label. Every fix can be switched off on its own.
const FIXES := {
	"fix_quota_overflow": "Coal quota no longer overflows on late days",
	"fix_save_restore": "Restore a missing or corrupt save from its backup",
	"fix_pause_resume": "Resuming with Esc can no longer leave the game paused",
	"fix_negative_cash": "Buying can no longer leave cash below zero",
	"fix_loot_duplication": "Merged or collected loot can no longer be counted twice",
	"fix_loot_burst": "Loot cap holds during one-frame bursts (nukes, earthquakes)",
	"fix_blast_edges": "Explosions reach their bottom and right edges",
	"fix_zero_employee_boxes": "Hide employee boxes that show x0",
}

var mod_dir_path: String
var extensions_dir_path: String


func _init() -> void:
	mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(MOD_DIR)
	extensions_dir_path = mod_dir_path.path_join("extensions")
	install_hooks()


func install_hooks() -> void:
	var hooks := {
		"res://scripts/Gvars.gd": "scripts/Gvars.hooks.gd",
		"res://scripts/PauseMenu.gd": "scripts/PauseMenu.hooks.gd",
		"res://scripts/ItemPickup2.gd": "scripts/ItemPickup2.hooks.gd",
		"res://scripts/loot_drops.gd": "scripts/loot_drops.hooks.gd",
		"res://scenes/tilemaps/tile_map_manager.gd": "scenes/tilemaps/tile_map_manager.hooks.gd",
		"res://scenes/Interfaces/Management/employee_level_icon_2.gd": "scenes/Interfaces/Management/employee_level_icon_2.hooks.gd",
		"res://resources/Employees/Scripts/employee_manager.gd": "resources/Employees/Scripts/employee_manager.hooks.gd",
		# Settings tab.
		"res://scenes/Interfaces/Menus/settings_2.gd": "scenes/Interfaces/Menus/settings_2.hooks.gd",
	}
	for vanilla_path in hooks:
		ModLoaderMod.install_script_hooks(vanilla_path, extensions_dir_path.path_join(hooks[vanilla_path]))


func _ready() -> void:
	var off := []
	for key in FIXES:
		if not bool(get_config().data.get(key, true)):
			off.append(key)
	ModLoaderLog.info("Ready! enabled=%s fixes_off=%s" % [str(get_enabled()), str(off)], LOG_NAME)


# True when the mod is enabled and the given fix is switched on.
static func is_on(key: String) -> bool:
	var data: Dictionary = get_config().data
	return bool(data.get("enabled", true)) and bool(data.get(key, true))


# --- Config ---

static func get_config() -> ModConfig:
	const LABEL := "user"
	if ModLoaderConfig.has_config(MOD_ID, LABEL):
		return ModLoaderConfig.get_config(MOD_ID, LABEL)
	return ModLoaderConfig.create_config(MOD_ID, LABEL, ModLoaderConfig.get_default_config(MOD_ID).data)


static func set_fix(key: String, value: bool) -> void:
	var cfg := get_config()
	cfg.data[key] = value
	ModLoaderConfig.update_config(cfg)


static func get_enabled() -> bool:
	return bool(get_config().data.get("enabled", true))


static func set_enabled(value: bool) -> void:
	var cfg := get_config()
	cfg.data["enabled"] = value
	ModLoaderConfig.update_config(cfg)
