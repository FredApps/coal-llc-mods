extends Object

const LOG_NAME := "ingenitus-bug_fixes_mod:GvarsHook"
# Access mod_main via load() — a mod's class_name is not in GDScript's global
# registry, so referencing IngenitusBugFixesMod here would not compile.
const MOD_MAIN_PATH := "res://mods-unpacked/ingenitus-bug_fixes_mod/mod_main.gd"


# fix_quota_overflow: past the end of COAL_QUOTAS vanilla multiplies the last quota
# by `4 ** (day - len)`, an integer power. It overflows 64 bits 32 days after the
# table ends and the quota collapses to 0 (or goes negative). The same growth is
# computed in floating point instead; before the overflow the values are identical.
func increaseQuota(chain: ModLoaderHookChain, _coalQuota: float, _dayCount: int) -> float:
	var quota: float = chain.execute_next([_coalQuota, _dayCount])
	if not load(MOD_MAIN_PATH).is_on("fix_quota_overflow"):
		return quota
	var gvars = chain.reference_object
	var past_table: int = _dayCount - gvars.COAL_QUOTAS.size()
	if past_table < 0 or gvars.mode == Gconsts.Mode.PEACEFUL:
		return quota
	var grown: float = gvars.COAL_QUOTAS[gvars.COAL_QUOTAS.size() - 1] * pow(4.0, past_table)
	return grown * 0.5 if gvars.mode == Gconsts.Mode.TOUGH_START else grown


# fix_save_restore: every save file has a backup copy, but vanilla only ever reads
# the primary. A missing primary loads defaults and a corrupt one loads nothing, and
# the next save then overwrites the good backup too, so progress is lost for good.
# If the primary cannot be parsed and the backup can, the backup is put back first.
func load_globals(chain: ModLoaderHookChain) -> void:
	_restore_if_needed(Gconsts.SAVE_GLOBALS_FILE_NAME, Gconsts.SAVE_GLOBALS_FILE_NAME_BACKUP)
	chain.execute_next()


func load_records(chain: ModLoaderHookChain) -> void:
	_restore_if_needed(Gconsts.SAVE_RECORDS_FILE_NAME, Gconsts.SAVE_RECORDS_FILE_NAME_BACKUP)
	chain.execute_next()


func load_hard_modifier_records(chain: ModLoaderHookChain) -> void:
	_restore_if_needed(Gconsts.SAVE_MODIFIERS_FILE_NAME, Gconsts.SAVE_MODIFIERS_FILE_NAME_BACKUP)
	chain.execute_next()


static func _restore_if_needed(primary: String, backup: String) -> void:
	if not load(MOD_MAIN_PATH).is_on("fix_save_restore"):
		return
	if _read_json_line(primary) != "" or _read_json_line(backup) == "":
		return
	var line := _read_json_line(backup)
	var temp := primary + ".restore"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		ModLoaderLog.error("Could not write %s to restore %s from its backup" % [temp, primary], LOG_NAME)
		return
	file.store_string(line)
	file.close()
	DirAccess.rename_absolute(temp, primary)
	ModLoaderLog.warning("%s was missing or corrupt; restored it from %s" % [primary, backup], LOG_NAME)


# The file's first line if it parses as a JSON object (how vanilla reads saves), else "".
static func _read_json_line(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var line := file.get_line()
	file.close()
	var json := JSON.new()
	if json.parse(line) != OK or not json.data is Dictionary:
		return ""
	return line
