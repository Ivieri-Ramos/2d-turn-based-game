@tool
extends EditorPlugin

## GDScript Commenter Plugin
## Auto-detects the declaration under the cursor, inserts or updates the comment.

const MENU_ITEM_AUTO    := "Insert comment"
const MENU_ITEM_SECTION := "Insert section separator"

const COMMENT_SHORTCUT_SETTING := "gdscript_commenter/insert_comment_shortcut"
const COMMENT_SHORTCUT_PATH    := "gdscript_commenter/insert_comment"
const SECTION_SHORTCUT_SETTING := "gdscript_commenter/insert_section_separator_shortcut"
const SECTION_SHORTCUT_PATH    := "gdscript_commenter/insert_section_separator"

var _script_editor: ScriptEditor
var _context_menu_handler: Node


func _enter_tree() -> void:
	_script_editor = EditorInterface.get_script_editor()
	_register_shortcut_settings()
	_setup_context_menu()
	print("[GDScript Commenter] Plugin loaded.")


## Registers the two customizable shortcuts. On Godot 4.6+ they are added to
## the native Shortcuts tab of Editor Settings via add_shortcut(); on older
## versions they fall back to regular Shortcut-typed editor settings.
func _register_shortcut_settings() -> void:
	var es := EditorInterface.get_editor_settings()

	if es.has_method("add_shortcut"):
		# Godot 4.6+: appears in Editor Settings → Shortcuts under the
		# "Gdscript Commenter" category as "Insert/Update comment" and
		# "Insert section separator". Re-install the default when missing
		# OR emptied by the user (an event-less Shortcut can never fire
		# and vanishes from the Shortcuts list).
		if not es.has_shortcut(COMMENT_SHORTCUT_PATH) \
				or _shortcut_is_empty(es.get_shortcut(COMMENT_SHORTCUT_PATH)):
			var sc := _make_default_comment_shortcut()
			sc.resource_name = "Insert/Update comment"
			es.add_shortcut(COMMENT_SHORTCUT_PATH, sc)
		if not es.has_shortcut(SECTION_SHORTCUT_PATH) \
				or _shortcut_is_empty(es.get_shortcut(SECTION_SHORTCUT_PATH)):
			var sc2 := _make_default_section_shortcut()
			sc2.resource_name = "Insert section separator"
			es.add_shortcut(SECTION_SHORTCUT_PATH, sc2)
		return

	# Fallback (Godot < 4.6): Shortcut-typed settings in the settings list.
	_register_fallback_setting(es, COMMENT_SHORTCUT_SETTING, _make_default_comment_shortcut())
	_register_fallback_setting(es, SECTION_SHORTCUT_SETTING, _make_default_section_shortcut())


func _register_fallback_setting(es: EditorSettings, setting_name: String, default_sc: Shortcut) -> void:
	if not es.has_setting(setting_name):
		es.set_setting(setting_name, default_sc)
	es.set_initial_value(setting_name, default_sc, false)
	es.add_property_info({
		"name": setting_name,
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shortcut",
	})

## Returns true when [sc] carries no events and therefore can never fire.
## This happens when the user clears all keys for a shortcut in Editor
## Settings, leaving an empty Shortcut object behind.
func _shortcut_is_empty(sc) -> bool:
	return not (sc is Shortcut) or (sc as Shortcut).events.is_empty()


## Default Insert/Update Comment shortcut: Shift+F1.
func _make_default_comment_shortcut() -> Shortcut:
	var ev := InputEventKey.new()
	ev.keycode       = KEY_F1
	ev.shift_pressed = true
	var sc := Shortcut.new()
	sc.events = [ev]
	return sc


## Default Insert Section Separator shortcut: Ctrl+Shift+F1.
func _make_default_section_shortcut() -> Shortcut:
	var ev := InputEventKey.new()
	ev.keycode       = KEY_F1
	ev.shift_pressed = true
	ev.ctrl_pressed  = true
	var sc := Shortcut.new()
	sc.events = [ev]
	return sc


## Returns the currently configured Insert/Update Comment shortcut
## (falls back to the default Shift+F1 if not yet registered).
func get_comment_shortcut() -> Shortcut:
	var es := EditorInterface.get_editor_settings()
	if es.has_method("get_shortcut"):
		var sc = es.get_shortcut(COMMENT_SHORTCUT_PATH)
		if sc is Shortcut:
			return sc
	elif es.has_setting(COMMENT_SHORTCUT_SETTING):
		var sc2 = es.get_setting(COMMENT_SHORTCUT_SETTING)
		if sc2 is Shortcut:
			return sc2
	return _make_default_comment_shortcut()


## Returns the currently configured Insert Section Separator shortcut
## (falls back to the default Ctrl+Shift+F1 if not yet registered).
func get_section_shortcut() -> Shortcut:
	var es := EditorInterface.get_editor_settings()
	if es.has_method("get_shortcut"):
		var sc = es.get_shortcut(SECTION_SHORTCUT_PATH)
		if sc is Shortcut:
			return sc
	elif es.has_setting(SECTION_SHORTCUT_SETTING):
		var sc2 = es.get_setting(SECTION_SHORTCUT_SETTING)
		if sc2 is Shortcut:
			return sc2
	return _make_default_section_shortcut()


func _exit_tree() -> void:
	if _context_menu_handler:
		_context_menu_handler.cleanup()
		_context_menu_handler.queue_free()
		_context_menu_handler = null
	print("[GDScript Commenter] Plugin unloaded.")


func _setup_context_menu() -> void:
	_context_menu_handler = ContextMenuHandler.new()
	_context_menu_handler.plugin = self
	add_child(_context_menu_handler)
	_context_menu_handler.watch_script_editor(_script_editor)


func get_active_code_edit() -> CodeEdit:
	var base := _script_editor.get_current_editor()
	if base == null:
		return null
	return _find_code_edit(base)


func _find_code_edit(node: Node) -> CodeEdit:
	if node is CodeEdit:
		return node as CodeEdit
	for child in node.get_children():
		var result := _find_code_edit(child)
		if result:
			return result
	return null


# ---------------------------------------------------------------------------
# Auto-detection — single public entry point
# ---------------------------------------------------------------------------

func insert_auto_comment() -> void:
	var code_edit := get_active_code_edit()
	if code_edit == null:
		return
	var result    := _detect_declaration_at_cursor(code_edit)
	var decl_line : int    = result[0]
	var kind      : String = result[1]
	match kind:
		"func":         _insert_method_comment(code_edit, decl_line)
		"var":          _insert_variable_comment(code_edit, decl_line)
		"enum":         _insert_enum_comment(code_edit, decl_line)
		"class_header": _insert_class_comment(code_edit)
		_:              _insert_line_comment(code_edit, code_edit.get_caret_line())


func insert_section_separator() -> void:
	var code_edit := get_active_code_edit()
	if code_edit == null:
		return
	var line_index := code_edit.get_caret_line()
	var indent     := _get_indent(code_edit.get_line(line_index))
	_apply_comment(code_edit, line_index, [
		indent + "# ---------------------------------------------------------------------------",
		indent + "# SECTION NAME",
		indent + "# ---------------------------------------------------------------------------",
	], false)  # section separators are never merged


# ---------------------------------------------------------------------------
# Private insertion helpers  (each reads existing comment, merges, applies)
# ---------------------------------------------------------------------------

func _insert_method_comment(code_edit: CodeEdit, func_line: int) -> void:
	var func_text   := _collect_func_signature(code_edit, func_line)
	var indent      := _get_indent(code_edit.get_line(func_line))
	var params      := _parse_params(func_text)
	var return_type := _parse_return_type(func_text)
	var func_name   := _parse_func_name(func_text)

	var existing    := _read_existing_doc_comment(code_edit, func_line)
	var new_lines   := _build_method_comment(indent, func_name, params, return_type)

	if not existing.is_empty():
		new_lines = _merge_method_comment(new_lines, existing, params, return_type)

	_apply_comment(code_edit, func_line, new_lines, not existing.is_empty())


func _insert_variable_comment(code_edit: CodeEdit, var_line: int) -> void:
	var var_text := code_edit.get_line(var_line)
	var indent   := _get_indent(var_text)
	var info     := _parse_variable(var_text)

	var existing  := _read_existing_doc_comment(code_edit, var_line)
	var new_lines := _build_variable_comment(indent, info)

	if not existing.is_empty():
		new_lines = _merge_variable_comment(new_lines, existing)

	_apply_comment(code_edit, var_line, new_lines, not existing.is_empty())


func _insert_enum_comment(code_edit: CodeEdit, enum_line: int) -> void:
	var enum_header := _collect_enum_header(code_edit, enum_line)
	var indent       := _get_indent(code_edit.get_line(enum_line))
	var enum_name    := _parse_enum_name(enum_header)
	var values       := _parse_enum_values(code_edit, enum_line)

	var existing  := _read_existing_doc_comment(code_edit, enum_line)
	var new_lines := _build_enum_comment(indent, enum_name, values)

	if not existing.is_empty():
		new_lines = _merge_enum_comment(new_lines, existing, values)

	_apply_comment(code_edit, enum_line, new_lines, not existing.is_empty())


func _insert_class_comment(code_edit: CodeEdit) -> void:
	var class_name_str := _parse_class_name(code_edit)
	var insert_line    := _find_class_header_first_line(code_edit)
	var existing       := _read_existing_doc_comment(code_edit, insert_line)
	var new_lines      := _build_class_comment(class_name_str)

	if not existing.is_empty():
		new_lines = _merge_class_comment(new_lines, existing, class_name_str)

	_apply_comment(code_edit, insert_line, new_lines, not existing.is_empty())


func _insert_line_comment(code_edit: CodeEdit, line_index: int) -> void:
	var existing := _read_existing_doc_comment(code_edit, line_index)
	if not existing.is_empty():
		return  # A comment already exists — nothing to do.
	var indent := _get_indent(code_edit.get_line(line_index))
	_apply_comment(code_edit, line_index,
			[indent + "# TODO: describe what this line does"], false)


# ---------------------------------------------------------------------------
# Existing comment reader
# ---------------------------------------------------------------------------

## Reads the contiguous block of ## / # lines immediately above [decl_line].
## Returns an Array of raw line strings (without trailing \n), or [] if none.
func _read_existing_doc_comment(code_edit: CodeEdit, decl_line: int) -> Array:
	var result: Array = []
	var i := decl_line - 1
	while i >= 0:
		var text := code_edit.get_line(i)
		var stripped := text.strip_edges()
		if stripped.begins_with("##") or stripped.begins_with("# ") or stripped == "#":
			result.push_front(text)
			i -= 1
		else:
			break
	return result


## Returns the span [first_line, last_line] of the existing comment block
## immediately above [decl_line], or [-1, -1] if there is none.
func _existing_comment_span(code_edit: CodeEdit, decl_line: int) -> Array:
	var block := _read_existing_doc_comment(code_edit, decl_line)
	if block.is_empty():
		return [-1, -1]
	var first := decl_line - block.size()
	var last  := decl_line - 1
	return [first, last]


# ---------------------------------------------------------------------------
# Existing comment parsers  →  extract preserved text fragments
# ---------------------------------------------------------------------------

## Extracts the first ## description line text (after "## " prefix).
func _extract_description(lines: Array) -> String:
	for raw in lines:
		var s: String = raw.strip_edges()
		if s.begins_with("## ") and not s.contains("[param") \
				and not s.contains("[return") and not s.contains("[br]"):
			return s.substr(3).strip_edges()
	return ""


## Extracts the [br]Description: text if present.
func _extract_description_tag(lines: Array) -> String:
	for raw in lines:
		var s: String = raw.strip_edges()
		if s.contains("[br]Description:"):
			var pos: int = s.find("[br]Description:") + len("[br]Description:")
			return s.substr(pos).strip_edges()
	return ""


## Returns { param_name → description_text } from existing comment lines.
func _extract_params(lines: Array) -> Dictionary:
	var result := {}
	var rx := RegEx.new()
	rx.compile(r"\[br\]\[param\s+([a-zA-Z_][a-zA-Z0-9_]*)\]\s*:\s*\([^)]*\)\s*(.*)")
	for raw in lines:
		var m := rx.search(raw.strip_edges())
		if m:
			result[m.get_string(1)] = m.get_string(2).strip_edges()
	return result


## Returns { return_type → description_text } from the existing [return] line.
## Key is the type string so callers can check if the type changed.
func _extract_return(lines: Array) -> Dictionary:
	var rx := RegEx.new()
	rx.compile(r"\[br\]\[return\]\s*\(([^)]+)\)\s*:\s*(.*)")
	for raw in lines:
		var m := rx.search(raw.strip_edges())
		if m:
			return { m.get_string(1): m.get_string(2).strip_edges() }
	return {}


## Returns { member_name → description_text } from existing enum member lines.
func _extract_enum_members(lines: Array) -> Dictionary:
	var result := {}
	var rx := RegEx.new()
	rx.compile(r"-\s*\[b\]([a-zA-Z_][a-zA-Z0-9_]*)\[/b\][^:]*:\s*(.*)")
	for raw in lines:
		var m := rx.search(raw.strip_edges())
		if m:
			result[m.get_string(1)] = m.get_string(2).strip_edges()
	return result


## Extracts the [br]<label> — description text for variable comments.
func _extract_variable_desc(lines: Array) -> String:
	var rx := RegEx.new()
	rx.compile(r"\[br\](?:Variable|Constant|Exported variable|OnReady variable|Static variable)\s*[—-]\s*(.*)")
	for raw in lines:
		var m := rx.search(raw.strip_edges())
		if m:
			return m.get_string(1).strip_edges()
	return ""


# ---------------------------------------------------------------------------
# Comment mergers  (new template + existing text  →  merged lines)
# ---------------------------------------------------------------------------

## Rebuilds the method comment, re-using existing description/param/return texts.
func _merge_method_comment(new_lines: Array, existing: Array,
		params: Array, new_return_type: String) -> Array:
	var old_desc   := _extract_description_tag(existing)
	var old_params := _extract_params(existing)
	var old_return := _extract_return(existing)
	var result: Array = []

	for raw in new_lines:
		var s: String = raw.strip_edges()

		# Description line
		if s.contains("[br]Description:"):
			var text := old_desc if old_desc != "" and old_desc != "TODO" else "TODO"
			result.append(raw.substr(0, raw.find("##")) + "## [br]Description: " + text)

		# Param line
		elif s.contains("[br][param "):
			var rx := RegEx.new()
			rx.compile(r"\[br\]\[param\s+([a-zA-Z_][a-zA-Z0-9_]*)\]\s*:\s*\(([^)]*)\)")
			var m := rx.search(s)
			if m:
				var pname := m.get_string(1)
				var ptype := m.get_string(2)
				var desc  := old_params.get(pname, "TODO")
				if desc == "":
					desc = "TODO"
				result.append(raw.substr(0, raw.find("##")) +
						"## [br][param " + pname + "]: (" + ptype + ") " + desc)
			else:
				result.append(raw)

		# Return line
		elif s.contains("[br][return]"):
			var rx := RegEx.new()
			rx.compile(r"\[br\]\[return\]\s*\(([^)]*)\)")
			var m := rx.search(s)
			if m:
				var rtype := m.get_string(1)
				# Keep existing description only if the return type is unchanged
				var desc := "TODO"
				if not old_return.is_empty():
					var old_type: String = old_return.keys()[0]
					if old_type == rtype:
						desc = old_return[old_type]
						if desc == "":
							desc = "TODO"
				result.append(raw.substr(0, raw.find("##")) +
						"## [br][return] (" + rtype + "): " + desc)
			else:
				result.append(raw)

		else:
			result.append(raw)

	return result


## Rebuilds the variable comment, re-using existing description text.
func _merge_variable_comment(new_lines: Array, existing: Array) -> Array:
	var old_desc := _extract_variable_desc(existing)
	var result: Array = []
	for raw in new_lines:
		var s: String = raw.strip_edges()
		var rx := RegEx.new()
		rx.compile(r"\[br\](?:Variable|Constant|Exported variable|OnReady variable|Static variable)\s*[—-]\s*(.*)")
		var m := rx.search(s)
		if m:
			var text := old_desc if old_desc != "" and old_desc != "TODO: description." else "TODO: description."
			var prefix: String = raw.substr(0, raw.find("##"))
			var label_end: int = raw.find(" — ")
			if label_end == -1:
				label_end = raw.find(" - ")
			var label_part: String = raw.substr(raw.find("[br]"), label_end - raw.find("[br]") + 3)
			result.append(prefix + "## " + label_part + text)
		else:
			result.append(raw)
	return result


## Rebuilds the enum comment, re-using description + per-member texts.
func _merge_enum_comment(new_lines: Array, existing: Array, values: Array) -> Array:
	var old_desc    := _extract_description_tag(existing)
	var old_members := _extract_enum_members(existing)
	var result: Array = []

	for raw in new_lines:
		var s: String = raw.strip_edges()

		if s.contains("[br]Description:"):
			var text := old_desc if old_desc != "" and old_desc != "TODO" else "TODO"
			result.append(raw.substr(0, raw.find("##")) + "## [br]Description: " + text)

		elif s.contains("- [b]"):
			var rx := RegEx.new()
			rx.compile(r"-\s*\[b\]([A-Z_][A-Z0-9_]*)\[/b\]")
			var m := rx.search(s)
			if m:
				var mname := m.get_string(1)
				var desc  := old_members.get(mname, "TODO")
				if desc == "":
					desc = "TODO"
				# Rebuild the member line keeping the value annotation
				var suffix_rx := RegEx.new()
				suffix_rx.compile(r"(\[code\][^[]*\[/code\])")
				var sm := suffix_rx.search(s)
				var suffix := (" " + sm.get_string(1)) if sm else ""
				result.append(raw.substr(0, raw.find("##")) +
						"## - [b]" + mname + "[/b]" + suffix + ": " + desc)
			else:
				result.append(raw)
		else:
			result.append(raw)

	return result


## Rebuilds the class comment, re-using the title and description.
func _merge_class_comment(new_lines: Array, existing: Array,
		class_name_str: String = "ClassName") -> Array:
	var real_name := class_name_str if class_name_str != "" else "ClassName"
	var old_title := _extract_description(existing)
	var old_desc  := _extract_description_tag(existing)
	var result: Array = []
	var in_codeblock := false
	for raw in new_lines:
		var s: String = raw.strip_edges()
		if s.contains("[codeblock]"):
			in_codeblock = true
		elif s.contains("[/codeblock]"):
			in_codeblock = false
		if not in_codeblock and s.begins_with("## ") and not s.contains("[") and s != "##":
			# Title line — always use the real class name (may have been renamed)
			result.append("## " + real_name + ".")
		elif s.contains("[br]Description:"):
			var text := old_desc if old_desc != "" and old_desc != "TODO" else "TODO"
			result.append("## [br]Description: " + text)
		elif s.contains(".new()"):
			result.append("## var obj = " + real_name + ".new()")
		else:
			result.append(raw)
	return result


# ---------------------------------------------------------------------------
# Apply comment: insert fresh or replace existing block
# ---------------------------------------------------------------------------

## Inserts [lines] before [decl_line].
## If [replace_existing] is true, the existing comment block is removed first.
func _apply_comment(code_edit: CodeEdit, decl_line: int,
		lines: Array, replace_existing: bool) -> void:
	if replace_existing:
		var span := _existing_comment_span(code_edit, decl_line)
		if span[0] >= 0:
			_delete_lines(code_edit, span[0], span[1])
			# After deletion, decl_line has shifted up by the number of removed lines
			decl_line -= (span[1] - span[0] + 1)

	_insert_lines_before(code_edit, decl_line, lines)


## Deletes lines [first..last] inclusive.
func _delete_lines(code_edit: CodeEdit, first: int, last: int) -> void:
	code_edit.set_caret_line(first)
	code_edit.set_caret_column(0)
	# Select from start of first line to start of line after last
	var after := last + 1
	if after < code_edit.get_line_count():
		code_edit.select(first, 0, after, 0)
	else:
		# Last lines of file: select to end of last line
		code_edit.select(first, 0, last, code_edit.get_line(last).length())
		code_edit.insert_text_at_caret("")
		return
	code_edit.insert_text_at_caret("")


# ---------------------------------------------------------------------------
# Comment builders
# ---------------------------------------------------------------------------

func _build_method_comment(indent: String, func_name: String,
		params: Array, return_type: String) -> Array:
	var lines: Array = []
	lines.append(indent + "## " + _humanize(func_name) + ".")
	lines.append(indent + "##")
	lines.append(indent + "## [br]Description: TODO")
	if params.size() > 0:
		lines.append(indent + "##")
		for p in params:
			var pname: String = p[0]
			var ptype: String = p[1] if p[1] != "" else "Variant"
			lines.append(indent + "## [br][param " + pname + "]: (" + ptype + ") TODO")
	if return_type != "" and return_type != "void":
		lines.append(indent + "##")
		lines.append(indent + "## [br][return] (" + return_type + "): TODO")
	return lines


func _build_variable_comment(indent: String, info: Dictionary) -> Array:
	var lines: Array = []
	var label: String
	match info.get("kind", "var"):
		"const":   label = "Constant"
		"export":  label = "Exported variable"
		"onready": label = "OnReady variable"
		"static":  label = "Static variable"
		_:         label = "Variable"
	lines.append(indent + "## " + _humanize(info.get("name", "variable")) + ".")
	lines.append(indent + "##")
	lines.append(indent + "## [br]" + label + " — TODO: description.")
	var vtype: String = info.get("type", "")
	if vtype != "":
		lines.append(indent + "## [br]Type: [" + vtype + "]")
	var defval: String = info.get("default_value", "")
	if defval != "":
		lines.append(indent + "## [br]Default: [code]" + defval + "[/code]")
	return lines


func _build_enum_comment(indent: String, enum_name: String, values: Array) -> Array:
	var lines: Array = []
	lines.append(indent + "## " + enum_name + ".")
	lines.append(indent + "##")
	lines.append(indent + "## [br]Description: TODO")
	if values.size() > 0:
		lines.append(indent + "##")
		lines.append(indent + "## [br]Members:")
		for v in values:
			var vname: String   = v[0]
			var vassign: String = v[1]
			var suffix := (" [code]" + vassign + "[/code]") if vassign != "" else ""
			lines.append(indent + "## - [b]" + vname + "[/b]" + suffix + ": TODO")
	return lines


func _build_class_comment(class_name_str: String = "ClassName") -> Array:
	var name := class_name_str if class_name_str != "" else "ClassName"
	return [
		"## " + name + ".",
		"##",
		"## [br]Description: TODO",
		"##",
		"## [br]Usage:",
		"## [codeblock]",
		"## var obj = " + name + ".new()",
		"## [/codeblock]",
	]


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

func _get_indent(line: String) -> String:
	var result := ""
	for ch in line:
		if ch == "\t" or ch == " ":
			result += ch
		else:
			break
	return result


func _humanize(name: String) -> String:
	return name.replace("_", " ").capitalize()


## Collects a potentially multi-line func signature into a single string.
## Starts at [func_line] and keeps appending lines until the closing ')' of
## the parameter list (and the optional '-> ReturnType:' that follows) is found.
## Lines are joined with a single space so all existing parsers work unchanged.
func _collect_func_signature(code_edit: CodeEdit, func_line: int) -> String:
	var total := code_edit.get_line_count()
	var parts: Array = []
	var open_parens := 0
	var found_open  := false
	var closed      := false

	for i in range(func_line, min(func_line + 30, total)):
		var line := code_edit.get_line(i).strip_edges()
		parts.append(line)
		for ch in line:
			if ch == "(":
				open_parens += 1
				found_open   = true
			elif ch == ")":
				open_parens -= 1
				if found_open and open_parens <= 0:
					closed = true
		if closed:
			# Also consume a continuation line that only carries '-> Type:'
			# if the closing ')' was the last non-space character on this line.
			var trimmed := line.rstrip(" \t")
			if trimmed.ends_with(")") and i + 1 < total:
				var next := code_edit.get_line(i + 1).strip_edges()
				if next.begins_with("->"):
					parts.append(next)
			break

	return " ".join(parts)


func _parse_func_name(line: String) -> String:
	var rx := RegEx.new()
	rx.compile(r"func\s+([a-zA-Z_][a-zA-Z0-9_]*)")
	var m := rx.search(line)
	return m.get_string(1) if m else "function"


func _parse_params(line: String) -> Array:
	var rx := RegEx.new()
	rx.compile(r"func\s+\w+\s*\(([^)]*)\)")
	var m := rx.search(line)
	if not m:
		return []
	var raw: String = m.get_string(1).strip_edges()
	if raw == "":
		return []
	var result: Array = []
	for part in raw.split(","):
		part = part.strip_edges()
		if part == "":
			continue
		var colon_pos := part.find(":")
		var eq_pos    := part.find("=")
		var name_part := part
		var type_part := ""
		if colon_pos != -1:
			name_part = part.substr(0, colon_pos).strip_edges()
			var after_colon := part.substr(colon_pos + 1).strip_edges()
			if eq_pos != -1 and eq_pos > colon_pos:
				type_part = after_colon.substr(0, after_colon.find("=")).strip_edges()
			else:
				type_part = after_colon
		elif eq_pos != -1:
			name_part = part.substr(0, eq_pos).strip_edges()
		result.append([name_part, type_part])
	return result


func _parse_return_type(line: String) -> String:
	var rx := RegEx.new()
	rx.compile(r"\)\s*->\s*([a-zA-Z_][a-zA-Z0-9_\[\]]*)")
	var m := rx.search(line)
	return m.get_string(1) if m else ""


func _parse_variable(line: String) -> Dictionary:
	var info := { "kind": "var", "name": "", "type": "", "default_value": "" }
	if line.find("const ") != -1:
		info["kind"] = "const"
	elif line.find("@onready") != -1:
		info["kind"] = "onready"
	elif line.find("@export") != -1:
		info["kind"] = "export"
	elif line.find("static ") != -1:
		info["kind"] = "static"
	var rx_name := RegEx.new()
	rx_name.compile(r"(?:var|const)\s+([a-zA-Z_][a-zA-Z0-9_]*)")
	var m_name := rx_name.search(line)
	if m_name:
		info["name"] = m_name.get_string(1)
	var rx_type := RegEx.new()
	rx_type.compile(r"(?:var|const)\s+\w+\s*:\s*([a-zA-Z_][a-zA-Z0-9_\[\]]*)")
	var m_type := rx_type.search(line)
	if m_type:
		info["type"] = m_type.get_string(1)
	var rx_val := RegEx.new()
	rx_val.compile(r":?=\s*(.+)$")
	var m_val := rx_val.search(line.strip_edges())
	if m_val:
		info["default_value"] = m_val.get_string(1).strip_edges()
	return info


## Collects the enum declaration line(s) into a single string, stopping as
## soon as the opening '{' is found (or up to 10 lines as a safety limit).
## This lets _parse_enum_name work even when the brace is on a separate line.
func _collect_enum_header(code_edit: CodeEdit, enum_line: int) -> String:
	var total := code_edit.get_line_count()
	var parts: Array = []
	for i in range(enum_line, min(enum_line + 10, total)):
		var line := code_edit.get_line(i).strip_edges()
		parts.append(line)
		if line.contains("{"):
			break
	return " ".join(parts)


func _parse_enum_name(line: String) -> String:
	var rx := RegEx.new()
	rx.compile(r"enum\s+([a-zA-Z_][a-zA-Z0-9_]*)")
	var m := rx.search(line)
	return m.get_string(1) if m else "Enum"


## Collects all enum member names and optional explicit values.
## Handles any layout: single-line, multi-line, brace on a separate line.
func _parse_enum_values(code_edit: CodeEdit, from_line: int) -> Array:
	var result: Array = []
	var rx_member := RegEx.new()
	rx_member.compile(r"([a-zA-Z_][a-zA-Z0-9_]*)\s*(=\s*[^,}\n]+)?")
	var total_lines := code_edit.get_line_count()
	var found_open  := false

	for i in range(from_line, min(from_line + 120, total_lines)):
		var text := code_edit.get_line(i)

		if not found_open:
			var brace_pos := text.find("{")
			if brace_pos == -1:
				continue
			found_open = true
			# Parse members on the same line as '{'
			text = text.substr(brace_pos + 1)

		# Parse members on this line (works whether we just trimmed or not)
		for m in rx_member.search_all(text):
			result.append([m.get_string(1), m.get_string(2).strip_edges()])

		if text.contains("}"):
			break

	return result


# ---------------------------------------------------------------------------
# Declaration detection
# ---------------------------------------------------------------------------

## Patterns that identify the start of each declaration kind.
const DECL_PATTERNS := {
	"func":         r"^\s*(static\s+)?func\s+[a-zA-Z_]",
	"var":          r"^\s*(@export[^\n]*)?\s*(static\s+)?(var|const|@onready\s+var)\s+[a-zA-Z_]",
	"enum":         r"^\s*enum\s+[a-zA-Z_]",
	"class_header": r"^\s*(@tool|class_name\s|extends\s)",
}

## Returns [decl_line, kind] by inspecting only the cursor line.
## For multi-line blocks (func, enum), if the cursor is inside the body the
## function walks upward to find the opening keyword line.
## Falls back to [-1, ""] when no declaration is recognised.
func _detect_declaration_at_cursor(code_edit: CodeEdit) -> Array:
	var caret := code_edit.get_caret_line()

	# Direct match on the cursor line
	for kind in DECL_PATTERNS:
		var rx := RegEx.new()
		rx.compile(DECL_PATTERNS[kind])
		if rx.search(code_edit.get_line(caret)):
			return [caret, kind]

	# Cursor may be inside a multi-line signature or an enum body — walk upward
	# until we hit the opening keyword or a line that clearly ends the block.
	var depth := 0
	var rx_enum := RegEx.new()
	rx_enum.compile(DECL_PATTERNS["enum"])
	var rx_func := RegEx.new()
	rx_func.compile(DECL_PATTERNS["func"])

	for i in range(caret - 1, -1, -1):
		var line := code_edit.get_line(i)
		var stripped := line.strip_edges()

		# Track brace / colon depth to skip nested blocks
		depth += line.count("}") - line.count("{")

		# Enum: anywhere inside the enum body documents the enum itself.
		if rx_enum.search(line):
			return [i, "enum"]

		# Func: only treat the cursor as being on a function declaration when it
		# sits on one of the (possibly multi-line) signature lines. If the cursor
		# is inside the function *body*, fall back to a plain line comment.
		if rx_func.search(line):
			if caret <= _func_signature_last_line(code_edit, i):
				return [i, "func"]
			break

		# Stop if we've left any indented block entirely (back to top level non-blank)
		if stripped != "" and not stripped.begins_with("#") and depth < 0:
			break

	return [-1, ""]


## Returns the last line index of the func signature that starts at [func_line].
## Handles multi-line parameter lists and a trailing '-> Type:' on its own line,
## so the caller can tell whether the cursor is on the signature or in the body.
func _func_signature_last_line(code_edit: CodeEdit, func_line: int) -> int:
	var total := code_edit.get_line_count()
	var open_parens := 0
	var found_open  := false

	for i in range(func_line, min(func_line + 30, total)):
		var line := code_edit.get_line(i).strip_edges()
		for ch in line:
			if ch == "(":
				open_parens += 1
				found_open   = true
			elif ch == ")":
				open_parens -= 1
		if found_open and open_parens <= 0:
			# Parameter list closed on this line. A continuation line that only
			# carries '-> Type:' extends the signature by one more line.
			if line.rstrip(" \t").ends_with(")") and i + 1 < total:
				if code_edit.get_line(i + 1).strip_edges().begins_with("->"):
					return i + 1
			return i

	return func_line


## Returns the line index of the FIRST header line (@tool / class_name / extends).
## The comment is inserted above this line, not after the last header.
func _find_class_header_first_line(code_edit: CodeEdit) -> int:
	var rx := RegEx.new()
	rx.compile(r"^\s*(@tool|class_name\s|extends\s)")
	for i in range(code_edit.get_line_count()):
		if rx.search(code_edit.get_line(i)):
			return i
	return 0


## Extracts the identifier after `class_name` if present, otherwise uses the
## script file name (without extension) as a fallback.
func _parse_class_name(code_edit: CodeEdit) -> String:
	var rx := RegEx.new()
	rx.compile(r"^\s*class_name\s+([a-zA-Z_][a-zA-Z0-9_]*)")
	for i in range(code_edit.get_line_count()):
		var m := rx.search(code_edit.get_line(i))
		if m:
			return m.get_string(1)
	# Fallback: derive from the script path
	var path := EditorInterface.get_script_editor().get_current_script()
	if path != null:
		var fname := path.resource_path.get_file().get_basename()
		if fname != "":
			return fname.to_pascal_case()
	return ""


# ---------------------------------------------------------------------------
# Code edit manipulation
# ---------------------------------------------------------------------------

func _insert_lines_before(code_edit: CodeEdit, line_index: int, lines: Array) -> void:
	var col  := code_edit.get_caret_column()
	var text := "\n".join(lines) + "\n"
	code_edit.set_caret_line(line_index)
	code_edit.set_caret_column(0)
	code_edit.insert_text_at_caret(text)
	code_edit.set_caret_line(line_index)
	code_edit.set_caret_column(col)


# ---------------------------------------------------------------------------
# Inner class: context-menu watcher
# ---------------------------------------------------------------------------

class ContextMenuHandler extends Node:
	var plugin: EditorPlugin
	var _hooked_popup: PopupMenu  = null
	var _hooked_code_edits: Array = []


	func watch_script_editor(se: ScriptEditor) -> void:
		if not se.editor_script_changed.is_connected(_on_script_changed):
			se.editor_script_changed.connect(_on_script_changed)
		_hook_current_editor()


	func cleanup() -> void:
		_hooked_popup = null
		_hooked_code_edits.clear()


	func _on_script_changed(_script) -> void:
		_hook_current_editor()


	func _hook_current_editor() -> void:
		await get_tree().process_frame
		var code_edit: CodeEdit = plugin.get_active_code_edit()
		if code_edit == null or code_edit in _hooked_code_edits:
			return
		_hooked_code_edits.append(code_edit)
		code_edit.tree_exited.connect(_hooked_code_edits.erase.bind(code_edit), CONNECT_ONE_SHOT)
		code_edit.gui_input.connect(_on_code_edit_gui_input.bind(code_edit))


	func _on_code_edit_gui_input(event: InputEvent, code_edit: CodeEdit) -> void:
		if event is InputEventKey:
			var key := event as InputEventKey
			if key.pressed and not key.echo:
				var comment_sc: Shortcut = plugin.get_comment_shortcut()
				if comment_sc and comment_sc.matches_event(event):
					plugin.insert_auto_comment()
					code_edit.accept_event()
					return
				var section_sc: Shortcut = plugin.get_section_shortcut()
				if section_sc and section_sc.matches_event(event):
					plugin.insert_section_separator()
					code_edit.accept_event()
					return
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				call_deferred("_inject_menu_items", code_edit)


	func _inject_menu_items(code_edit: CodeEdit) -> void:
		var popup := _find_context_popup(code_edit)
		if popup == null:
			return
		if popup != _hooked_popup:
			_hooked_popup = popup
			popup.about_to_popup.connect(_on_popup_about_to_show.bind(popup))
			popup.id_pressed.connect(_on_menu_id_pressed)
		_add_our_items(popup, code_edit)


	func _on_popup_about_to_show(popup: PopupMenu) -> void:
		var code_edit: CodeEdit = plugin.get_active_code_edit()
		call_deferred("_add_our_items", popup, code_edit)


	func _add_our_items(popup: PopupMenu, code_edit: CodeEdit) -> void:
		for i in range(popup.item_count):
			if popup.get_item_id(i) == 1000:
				return

		var kind := ""
		var has_existing := false
		if code_edit != null:
			var decl: Array = plugin._detect_declaration_at_cursor(code_edit)
			kind = decl[1]
			var decl_line: int = decl[0]
			if decl_line >= 0:
				has_existing = not plugin._read_existing_doc_comment(code_edit, decl_line).is_empty()

		var action := "Update" if has_existing else "Insert"
		var label  := action + " comment"
		match kind:
			"func":         label += "  [func]"
			"var":          label += "  [var / const]"
			"enum":         label += "  [enum]"
			"class_header": label += "  [class]"
			_:              label += "  [line]"

		popup.add_separator("GDScript Commenter")
		var idx: int
		idx = popup.item_count
		popup.add_item(label, 1000)
		popup.set_item_icon(idx, _get_icon("GDScript"))
		popup.set_item_shortcut(idx, plugin.get_comment_shortcut(), false)
		idx = popup.item_count
		popup.add_item(plugin.MENU_ITEM_SECTION, 1001)
		popup.set_item_icon(idx, _get_icon("GuiTabMenuHl"))
		popup.set_item_shortcut(idx, plugin.get_section_shortcut(), false)


	func _on_menu_id_pressed(id: int) -> void:
		match id:
			1000: plugin.insert_auto_comment()
			1001: plugin.insert_section_separator()


	func _find_context_popup(code_edit: CodeEdit) -> PopupMenu:
		for child in code_edit.get_children():
			if child is PopupMenu:
				return child as PopupMenu
		return _find_visible_popup(plugin.get_tree().root)


	func _find_visible_popup(node: Node) -> PopupMenu:
		if node is PopupMenu and (node as PopupMenu).visible:
			return node as PopupMenu
		for child in node.get_children():
			var result := _find_visible_popup(child)
			if result:
				return result
		return null


	func _get_icon(name: String) -> Texture2D:
		var base := plugin.get_editor_interface().get_base_control()
		if base.has_theme_icon(name, "EditorIcons"):
			return base.get_theme_icon(name, "EditorIcons")
		return null
