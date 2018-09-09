extends Node2D
enum NODE_TYPE {
	meta_block # 0 - Stored at "__META__*****" and contains only metadata in extra_data
	dialogue_block, # 1
	title_block, # 2
	comment_block, # 3
	branch_block, # 4 <RESERVED>
	script_block, # 5 <RESERVED>
	audio_block, # 6 <RESERVED>
	animation_block, # 7 <RESERVED>
	math_block # 8 <RESERVED>
}

# NOTE: Most non-dialogue blocks will use the extra_data dictionary for everything.

export (NODE_TYPE) var node_type := meta_block

# IMPORTS

const ThrowawaySound = preload("res://src/dialogue_editor/throwaway_sound.tscn")

# RESOURCES
const spr_unfilled_circle = preload("res://sprites/icons/unfilled_circle_thick.png")
const spr_filled_circle = preload("res://sprites/icons/filled_circle.png")
const spr_unfilled_triangle = preload("res://sprites/icons/connector_small_unfilled.png")
const spr_filled_triangle = preload("res://sprites/icons/connector_small.png")


const snd_head = preload("res://snd/head.ogg")
const snd_tail = preload("res://snd/tail.ogg")
const snd_delet = preload("res://snd/delet_sound.ogg")


# FIELDS
var id := "" setget set_id, get_id
var dialogue_string := "" setget set_dialogue_string, get_dialogue_string
var character_name := "" setget set_character_name, get_character_name
var choices := [] setget set_choices, get_choices
var tail := "" setget set_tail, get_tail
var salsa_code := ""
var extra_data := {}

# CHILD NODES

onready var nine_patch_rect = get_node("NinePatchRect")
onready var id_label = get_node("NinePatchRect/TitleBar/Id_Label")
onready var draggable_segment = get_node("NinePatchRect/TitleBar/DraggableSegment")
onready var character_line_edit = get_node("NinePatchRect/Dialogue/DialogueBoxSprite/CharacterLineEdit")
onready var dialogue_rich_text_label = get_node("NinePatchRect/Dialogue/DialogueBoxSprite/DialogueRichTextLabel")
onready var dialogue_line_edit = get_node("NinePatchRect/DialogueTextEdit")
onready var anim_player = get_node("AnimationPlayer")
onready var area_2d = get_node("Area2D")

onready var nine_patch_size = nine_patch_rect.rect_size

var hand_placed = false
var just_created : bool = false
var dragging : bool = false
var tail_valid : bool = false
var previous_pos := Vector2(0,0)
var mouse_delta := Vector2(0,0)
var mouse_pos := Vector2(0,0)
var mouse_previous_pos := Vector2(0,0)
var mouse_offset := Vector2(0,0)
var on_screen = false
var title_bar_hovered = false
var in_connecting_mode = false

var force_process_input = false

onready var _head_connector_modulate_default = $NinePatchRect/TitleBar/HeadConnector.modulate
onready var _tail_connector_modulate_default = $NinePatchRect/TailConnector.modulate

# @TODO: Use observer pattern instead of just making all nodes with connections run every frame

# Called when the node enters the scene tree for the first time.
func _ready():
	#nine_patch_rect.visible = false # Disabled for now
	set_process(false)
	set_physics_process(false)
	if !just_created:
		set_process_input(false)

	if node_type == meta_block: # Kill other block if another meta block exists
		if get_parent().has_node("__META__*****"):
			if name != "__META__*****":
				get_parent().get_node("__META__*****").queue_free()
				print("OVERWRITING EXISTING META BLOCK NODE")
		name = "__META__*****"
		set_process(true)

	update()

	dialogue_line_edit.connect("text_changed",self,"update_dialogue_rich_text_label")

	# Play spawn animation
	if hand_placed:
		anim_player.play("spawn")
		nine_patch_rect.visible = true

func set_visibility(boolean):
	#nine_patch_rect.visible = boolean
	# Disabled for now
	on_screen = boolean

func serialize(): # Converts dialogue block fields to a dictionary. Yes, we're using US spelling. Deal with it.
	var dict = {
		key = id,
		node_type = node_type,
		dialogue = get_dialogue_string(),
		character = get_character_name(),
		choices = choices,
		tail = tail,
		salsa_code = salsa_code,
		pos_x = floor(position.x), # JSON does not support Vector2
		pos_y = floor(position.y),
		extra_data = extra_data
	}

	return dict

func update_dialogue_rich_text_label():
	var new_text = dialogue_line_edit.text
	var new_text_formatted = new_text #.replace("\\n","\n")
	dialogue_rich_text_label.set_bbcode(new_text_formatted)
	dialogue_string = dialogue_line_edit.text
	set_process_input(true)


func fill_with_garbage():
	character_line_edit.text = str(randi())
	dialogue_rich_text_label.bbcode_text = str(randi()).sha256_text()
	dialogue_line_edit.text = str(randi()).sha256_text()

func _input(event):
	if MainCamera.scroll_mode != 0:
		mouse_offset.y += MainCamera.scroll_mode*MainCamera.scroll_spd
	if MainCamera.pan_mode or !Input.is_action_pressed("click"):
		dragging = false
		mouse_offset = Vector2()
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if dragging:
			mouse_delta = (mouse_pos - mouse_previous_pos)
			position = previous_pos + mouse_delta  * MainCamera.zoom_level  + mouse_offset
			if just_created:
				position = get_global_mouse_position()
			# Teleport block to cursor if too far away
			if abs(get_global_mouse_position().y - position.y) > 80 or \
			abs(get_global_mouse_position().x - position.x) > 2000:
				just_created = true # Act like just created
			update()

	if (draggable_segment.pressed or just_created) and !dragging and !MainCamera.pan_mode:
		mouse_offset = Vector2()
		previous_pos = position
		mouse_previous_pos = mouse_pos
		dragging = true

	if Input.is_action_just_released("click"):
		just_created = false
		dialogue_string = dialogue_line_edit.text
		character_name = character_line_edit.text
		MainCamera.LAST_MODIFIED_BLOCK = self

	if Input.is_action_just_pressed("x") and (draggable_segment.pressed or just_created):
		_on_DeleteButton_pressed()

func move_to_front():
	# Move to front of Blocks
	var index = get_parent().get_child_count()
	get_parent().move_child(self, index)

func randomise_id():
	var new_id = str(float(OS.get_ticks_usec()) + randf()).sha256_text().substr(0,10)
	if node_type == title_block:
		set_id("Title_" + new_id)
	elif node_type == comment_block:
		new_id = str(float(OS.get_ticks_usec()) + randf()).sha256_text().substr(0,8)
		set_id("c_" + new_id)
	else:
		set_id(new_id)
	return id

func _on_DraggableSegment_pressed():
	#print("hi", character_line_edit.text)
	set_process_input(true)
	mouse_delta = Vector2(0,0)
	previous_pos = position
	mouse_previous_pos = mouse_pos
	dragging = true
	move_to_front()
	nine_patch_rect.grab_focus()
	MainCamera.LAST_MODIFIED_BLOCK = self
	if Input.is_action_pressed("x"):
		_on_DeleteButton_pressed()

func _on_DeleteButton_button_down():
	move_to_front()

func _on_DeleteButton_pressed():
	anim_player.play("kill")
	var death_sound = ThrowawaySound.instance()
	death_sound.pitch_scale = rand_range(0.7,1.3)
	death_sound.stream = snd_delet
	death_sound.volume_db = -6.118
	MainCamera.add_child(death_sound)

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"kill":
			# Tell Camera2D to reset array of last rendered stuff
			# (workaround for null pointer)
			MainCamera.last_blocks_on_screen = []
			self.queue_free() # actually kill


func _on_DraggableSegment_mouse_entered():
	set_process_input(true)
	update()

func _on_DraggableSegment_mouse_exited():
	if !just_created and !dialogue_line_edit.has_focus():
		set_process_input(false)
	update()

func _on_DialogueTextEdit_focus_entered():
	set_process_input(true)
	MainCamera.LAST_MODIFIED_BLOCK = self

func _on_DialogueTextEdit_focus_exited():
	set_process_input(false)

func _on_HeadArea2D_area_entered(area : Area2D):
	if area.name == "CursorArea" and MainCamera.CURRENT_CONNECTION_HEAD_NODE != self:
		title_bar_hovered = true
		MainCamera.CURRENT_CONNECTION_TAIL_NODE = self

		update()

func _on_HeadArea2D_area_exited(area : Area2D):
	if area.name == "CursorArea":
		title_bar_hovered = false
		MainCamera.CURRENT_CONNECTION_TAIL_NODE = null
		update()

func _on_Id_Label_text_changed(new_text):
	pass # Replace with function body.


func _on_CharacterLineEdit_text_changed(new_text):

	set_character_name(new_text)
	MainCamera.LAST_CHAR_NAME = character_line_edit.text
	MainCamera.LAST_MODIFIED_BLOCK = self

# SETTERS AND GETTERS
func set_id(new_id):
	var new_id_original = new_id
	if node_type == meta_block:
		id = "__META__*****"
		name = "__META__*****"
		id_label.text = "__META__*****"
		return

	var old_id = id
	if !is_id_valid(new_id):
		if is_id_valid(old_id):
			new_id = old_id
		else:
			new_id = randomise_id()
		print(new_id_original + " IS INVALID INPUT - ID CHANGED TO: ", new_id)

	id = new_id
	id_label.text = id # Update textfield
	name = id # Update name in tree

func is_id_valid(test_id):
	if test_id == "__META__*****" and node_type != null and node_type != meta_block:
		return false
	if test_id == "":
		return false
	if name != test_id and Editor.blocks.has_node(test_id):
		return false
	if test_id.length() > 100:
		return false
	return true

func get_id():
	if node_type == meta_block:
		return "__META__*****" # Will have meta id NO MATTER WHAT
	return id

func set_dialogue_string(new_dialogue_string):
	dialogue_string = new_dialogue_string
	dialogue_line_edit.text = dialogue_string # Update textfield

func get_dialogue_string():
	return dialogue_line_edit.text

func set_character_name(new_character_name):
	character_name = new_character_name

func get_character_name():
	return character_line_edit.text

func set_choices(new_choices):
	choices = new_choices

func get_choices():
	return choices

func set_tail(new_tail):
	tail = new_tail
	update()

func get_tail():
	return tail

func _on_Id_Label_text_entered(new_text):
	set_id(new_text)
	#anim_player.play("spawn")
	id_label.release_focus()
	MainCamera.LAST_MODIFIED_BLOCK = self
	print(get_id())

func _on_Id_Label_focus_exited():
	if id == id_label.text:
		return
	set_id(id_label.text)
	anim_player.play("spawn")
	print(get_id())

func _on_TailConnector_button_down():
	in_connecting_mode = true
	tail = ""
	MainCamera.CURRENT_CONNECTION_HEAD_NODE = self
	update()
	set_process(true)
	$NinePatchRect/TailConnector.pressed = false
	$NinePatchRect.grab_focus()
	MainCamera.LAST_MODIFIED_BLOCK = self
	
	if Editor.double_click_timer > 0.001:
		# Register double click
		spawn_block_below()

	Editor.double_click_timer = Editor.double_click_timer_time

func _on_TailConnector_button_up():
	pass

func release_connection_mode():
	tail = ""
	if MainCamera.CURRENT_CONNECTION_HEAD_NODE != self:
		return
	if MainCamera.CURRENT_CONNECTION_TAIL_NODE != null and MainCamera.CURRENT_CONNECTION_TAIL_NODE != self:
		tail = MainCamera.CURRENT_CONNECTION_TAIL_NODE.id
		#var sound = ThrowawaySound.instance()
		#sound.stream = snd_tail
		#sound.volume_db = -6.118
		#MainCamera.add_child(sound)
	in_connecting_mode = false
	MainCamera.CURRENT_CONNECTION_HEAD_NODE = null
	update()
	if tail == "":
		set_process(false)

func spawn_block_below():
	release_connection_mode()
	var tail_block = Editor.spawn_block(Editor.DB.dialogue_block, false, position + Vector2(0,600))
	tail_block.randomise_id()
	tail = tail_block.id
	MainCamera.lerp_camera_pos(Vector2(MainCamera.position.x, tail_block.position.y) + Vector2(0, 200), 0.5)
	tail_block.dialogue_line_edit.grab_focus()
	MainCamera.CURRENT_CONNECTION_TAIL_NODE = tail_block
	in_connecting_mode = false
	set_process(true)
	update()

	return tail_block

# DRAWING CODE

func _draw():
	if tail != "" or MainCamera.CURRENT_CONNECTION_HEAD_NODE == self:
		$NinePatchRect/TailConnector.modulate = Color(1,1,1)
		$NinePatchRect/TailConnector.texture_normal = spr_filled_triangle
	else:
		$NinePatchRect/TailConnector.modulate = _tail_connector_modulate_default
		$NinePatchRect/TailConnector.texture_normal = spr_unfilled_triangle

	if MainCamera.CURRENT_CONNECTION_HEAD_NODE != null and title_bar_hovered:
		#$NinePatchRect.modulate = Color(1.3,1.3,1.3)
		$NinePatchRect/TitleBar/HeadConnector.modulate = Color(1,1,1)
	else:
		#$NinePatchRect.modulate = Color(1,1,1)
		$NinePatchRect/TitleBar/HeadConnector.modulate = _head_connector_modulate_default

	$LineDrawNode.update()

func _process(delta):
	if node_type == meta_block:
		if name != "__META__*****": # Do not rest until id is changed
			id = "__META__*****"
			name = "__META__*****"
		else:
			set_process_input(false)
			set_physics_process(false)
			if tail != "":
				set_process(false)
		return

	if in_connecting_mode and Input.is_action_just_released("click"):
		release_connection_mode()

	update()