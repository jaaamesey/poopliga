extends Node2D

const DialogueDictionary = preload("res://src/dialogue_editor/dialogue_dictionary.gd")
const DialogueBlock = preload("res://src/dialogue_editor/dialogue_block.tscn")
const TitleBlock = preload("res://src/dialogue_editor/title_block.tscn")
const CommentBlock = preload("res://src/dialogue_editor/comment_block.tscn")
const theme = preload("res://themes/default_theme.tres")
const fnt_noto_sans_16 = preload("res://fonts/NotoSans_16.tres")
#const Lato16 = preload("res://fonts/lato_16.tres")

onready var DialogueBlocks = get_node("Map/DialogueBlocks")
var saveas_dialog

var dialogue_dictionary
var lowest_position = -99999999

var current_path

# Called when the node enters the scene tree for the first time.
func _ready():
	current_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	randomize()
	CAMERA2D.DIALOGUE_EDITOR = self # give reference to self to camera2d
	set_process(true)
	dialogue_dictionary = DialogueDictionary.new()
	dialogue_dictionary.test()
	update_lowest_position()
	saveas_dialog = create_saveas_file_dialog()
	
	#fill_with_garbage_blocks(666)
	fix_popin_bug(10)

var double_click_timer_time = 0.35
var double_click_timer = 0
func _process(delta):
	double_click_timer -= delta
	double_click_timer = clamp(double_click_timer, 0, double_click_timer_time)
	if Input.is_action_just_pressed("refresh"):
		fix_rendering_bug()
		fix_popin_bug()



var _pending_render_bug_fix = false
var _pending_render_bug_fix_timer = 0


func _notification(what):
	
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT \
	or what == MainLoop.NOTIFICATION_WM_UNFOCUS_REQUEST:
		_pending_render_bug_fix = true
		
	
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN and _pending_render_bug_fix:
		#fix_rendering_bug()
		#_pending_render_bug_fix = false
		pass
		


# Fix for weird rendering bug after tab out	(CAN BE SLOW)
func fix_rendering_bug():
	
	var start_time = OS.get_ticks_msec()
	DialogueBlocks.visible = false
	DialogueBlocks.visible = true
	print("Fixing rendering bug in ", OS.get_ticks_msec() - start_time, "ms")
	
	return

func create_saveas_file_dialog():
	var thing = FileDialog.new()
	get_node("FrontWindows").add_child(thing)
	thing.access = FileDialog.ACCESS_FILESYSTEM
	thing.current_dir = current_path
	thing.resizable = true
	thing.theme = theme
	thing.theme.default_font = fnt_noto_sans_16
	thing.add_filter("*.poopliga")
	thing.mode = FileDialog.MODE_SAVE_FILE
	thing.connect("file_selected",self,"save_as")
	thing.connect("popup_hide",self,"_on_popup_hide")
	return thing

# Calculates and updates lowest position of a dialogue block. SOMEWHAT RESOURCE INTENSIVE.
func update_lowest_position():
	#var start_time = OS.get_ticks_msec()
	var lowest = -99999999
	for block in DialogueBlocks.get_children():
		if block.position.y > lowest:
			lowest = block.position.y
	lowest_position = lowest # Update lowest_position - wouldn't want to waste this precious call
	#print("Calculated lowest position in " + str(OS.get_ticks_msec()-start_time) + "ms.")
	return lowest

# Saves blocks to dictionary - NOT file!
func save_blocks_to_dict():
	var dict = {}
	# Clear dictionary
	#dialogue_dictionary.clear_all()
	# Add data of all children of DialogueBlocks to dictionary
	for visual_block in DialogueBlocks.get_children():
		dict[visual_block.id] = visual_block.serialize()
		
		pass
		
	return dict
		# Create actual block
#		var actual_block = { DEPRECATED - USE SERIALIZE INSTEAD
#			key = visual_block.id_Label.text,
#			dialogue = visual_block.DialogueRichTextLabel.text,
#			character = visual_block.CharacterLineEdit.text,
#			choices = [],
#			tail = "",
#			code = "",
#			pos_x = visual_block.position.floor().x, # JSON does not support Vector2
#			pos_y = visual_block.position.floor().y
#		}
#		# Store actual block in dictionary
#		dialogue_dictionary.add(actual_block.key, actual_block)
#		pass
	

func _on_popup_hide():
	CAMERA2D.freeze = false
	pass
func _on_Save_pressed():
	# if not already open (@TODO)
	saveas_dialog.popup_centered(Vector2(1200,600))
	saveas_dialog.current_dir = current_path
	saveas_dialog.rect_position += Vector2(0,10)
	CAMERA2D.freeze = true
	pass # Replace with function body.

func save_as(path):
	var start_time = OS.get_ticks_msec()
	var dict = save_blocks_to_dict()

	var file = File.new()
	var json = to_json(dict)
	var pretty_json = convert_to_multiline_json(json)
	
	file.open(path, File.WRITE)
	file.store_string(pretty_json)
	file.close()
	
	var end_time_str = "Saved " + str(dict.size()) + " blocks in " + str(OS.get_ticks_msec()-start_time) + "ms."
	print(end_time_str)
	current_path = path
	pass

	
	
# @TODO: Make actually pretty print
func convert_to_multiline_json(json : String):
	var output = json
	output = output.replace("{", "{\n")
	output = output.replace("}", "}\n")
	output = output.replace(",", ",\n")
	output = output.replace("[", "[\n")
	output = output.replace("]", "]\n")
	return output
	pass
func convert_from_multiline_json(json : String):
	var output = json
	output = output.replace("{\n", "{")
	output = output.replace("}\n", "}")
	output = output.replace(",\n", ",")
	output = output.replace("[\n", "[")
	output = output.replace("]\n", "]")
	return output
	pass

func fill_with_garbage_blocks(amount):
	for i in range(amount):
		var new_block = DialogueBlock.instance()
		DialogueBlocks.add_child(new_block)
		new_block.randomise_id()
		new_block.position = Vector2(0,rand_range(0,9990))
		new_block.fill_with_garbage()
		
	pass

func spawn_block(block_type = DialogueBlock, hand_placed = false):
	var mouse_pos = get_global_mouse_position()
	var new_block = block_type.instance()
	new_block.just_created = true
	new_block.hand_placed = hand_placed
	DialogueBlocks.add_child(new_block)
	new_block.randomise_id()
	new_block.position = mouse_pos
	new_block.previous_pos = mouse_pos
	return new_block
	
func _on_BackUIButton_pressed():
	
	if Input.is_action_pressed("title_block_button"):
		spawn_block(TitleBlock, true)
	elif Input.is_action_pressed("comment_block_button"):
		spawn_block(CommentBlock, true)
	# Spawn regular block if no modifiers
	elif double_click_timer > 0.001 or Input.is_action_pressed("ctrl"):
		# Register double click
		
		spawn_block(DialogueBlock, true)
		# @TODO: ADD UNDO EQUIVALENT TO BUFFER
		
	
	double_click_timer = double_click_timer_time

var confirm_create_new = null

func _on_New_pressed():
	
	# Create popup if doesn't exist
	if confirm_create_new == null:
		confirm_create_new = ConfirmationDialog.new()
		confirm_create_new.theme = theme
		confirm_create_new.theme.default_font = fnt_noto_sans_16 
		confirm_create_new.dialog_text = "Create a new empty file? \nAny unsaved progress will be lost :("	
		get_node("FrontWindows").add_child(confirm_create_new)
		confirm_create_new.connect("confirmed",self,"reset")
	confirm_create_new.popup_centered()
	
func _on_Find_pressed():
	
	$FrontWindows/FindWindow.popup_centered()
	$FrontWindows/FindWindow/HBoxContainer2/LineEdit.grab_focus()
	
	pass # Replace with function body.


func _on_Open_pressed():
	
	var window = get_node("FrontWindows/OpenFileWindow")
	window.current_dir = current_path
	window.add_filter("*.poopliga")
	window.popup_centered()
	window.rect_position.y += 10

	pass # Replace with function body.


func _on_OpenFileWindow_file_selected(path):
	current_path = path
	var window = get_node("FrontWindows/OpenFileWindow")
	var file = File.new()
	file.open(path, File.READ)
	var json = file.get_as_text()
	json = convert_from_multiline_json(json)
	
	reset() # Kill all existing blocks to make room for new file
	
	load_blocks_from_json(json)
	
	
	
	pass # Replace with function body.

func load_blocks_from_json(json):
	var dict := {}
	dict = parse_json((json))
	
	var DB = DialogueBlock.instance()
	# Loop through individual blocks
	for key in dict.keys():
		var values_dict = dict[key]
		var id = key
		var node_type = int(values_dict["node_type"])
		var pos = Vector2(values_dict["pos_x"], values_dict["pos_y"])
		var node_to_spawn = DialogueBlock
		match node_type:
			DB.dialogue_block:
				node_to_spawn = DialogueBlock
			DB.title_block:
				node_to_spawn = TitleBlock
			DB.comment_block:
				node_to_spawn = CommentBlock
				
		var block = spawn_block(node_to_spawn)
		block.set_id(id)
		block.position = pos
		block.node_type = node_type
		block.set_tail(values_dict["tail"])
		block.character_line_edit.text = values_dict["character"]
		block.dialogue_line_edit.text = values_dict["dialogue"]
		block.set_character_name(values_dict["character"])
		block.set_dialogue_string(values_dict["dialogue"])
		block.set_choices(values_dict["choices"])
		block.salsa_code = values_dict["salsa_code"]
		block.extra_data = values_dict["extra_data"]
		block.update_dialogue_rich_text_label()
		
#		node_type = node_type,
#		dialogue = dialogue_string,
#		character = character_name,
#		choices = choices,
#		tail = tail,
#		salsa_code = salsa_code,
#		pos_x = floor(position.x), # JSON does not support Vector2
#		pos_y = floor(position.y),
#		extra_data = extra_data
	DB.free()
		


func reset():
	# Clear everything on board
	for child in DialogueBlocks.get_children():
		child.queue_free()
	
	CAMERA2D.reset()
	get_node("Map/GridBG").update_grid()
	
	pass

func _on_Options2_focus_exited():
	pass # Replace with function body.



var prev_window_size = Vector2(100,100)
func _on_FindWindow_confirmed():
	var given_id = get_node("FrontWindows/FindWindow/HBoxContainer2/LineEdit").text
	if DialogueBlocks.has_node(given_id) and given_id != "" :

		var dialogue_node = DialogueBlocks.get_node(given_id)
		#CAMERA2D.pan_mode = true
		CAMERA2D.lerp_camera_pos(dialogue_node.position + Vector2(0, 200))
		dialogue_node.set_visibility(true)
		CAMERA2D.update_rendered(true , -1)
		CAMERA2D.update()
		
		#OS.set_window_size(Vector2(100,100))
		fix_popin_bug()
	else:
		$FrontWindows/FindWindow.popup_centered()
		$FrontWindows/FindWindow/HBoxContainer2/LineEdit.grab_focus()
		
var _popin_fix_pending = false
var _popin_fix_pending_timer = -1



func _physics_process(delta):
	# Fix render bug
	_popin_fix_pending_timer -=1
	if _popin_fix_pending and _popin_fix_pending_timer <= 0:
		OS.set_window_size(prev_window_size)
		_popin_fix_pending = false
		

func fix_popin_bug(timer = 2): # TODO: Rename as to not confuse things
	prev_window_size = OS.get_window_safe_area().size
	OS.set_window_size(Vector2(prev_window_size.x+1,prev_window_size.y+1))
	_popin_fix_pending = true
	_popin_fix_pending_timer = timer
	

func force_redraw():
	pass



