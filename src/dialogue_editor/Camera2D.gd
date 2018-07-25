extends Camera2D

func _ready():
	Engine.target_fps = 200
	camera_previous_pos = position

const drag_spd = 1
const zoom_spd = 1.2
const zoom_level_max = 2
var zoom_level = zoom_level_max
var mouse_pos = Vector2(0,0)
var mouse_previous_pos = Vector2(0,0)
var mouse_delta = Vector2(0,0)
var pan_mode = false
var camera_previous_pos = Vector2(0,0)
func _input(event):
	# Mouse movement stuff
	if event is InputEventMouseMotion:
		mouse_pos = event.position
		if pan_mode:
			mouse_delta = mouse_pos - mouse_previous_pos
			update_pan()
	#yep these are some long ass conditionals	
	if Input.is_action_just_pressed("middle_click") or \
	(Input.is_action_pressed("alt") and Input.is_action_pressed("click")):
		camera_previous_pos = position 
		mouse_previous_pos = mouse_pos
		mouse_delta = Vector2(0,0)
		pan_mode = true
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
	elif Input.is_action_just_released("middle_click") or \
	(Input.is_action_just_released("alt") or (Input.is_action_pressed("alt") and Input.is_action_just_released("click"))):
		mouse_delta = Vector2(0,0)
		pan_mode = false
		Input.set_default_cursor_shape()
	# Scroll to zoom	
	if Input.is_action_just_pressed("scroll_down"):
		zoom_level *= zoom_spd
		camera_previous_pos = position
		mouse_previous_pos = mouse_pos
		mouse_delta = Vector2(0,0)
		update_zoom()
	elif Input.is_action_just_pressed("scroll_up"):
		zoom_level *= 1/zoom_spd
		camera_previous_pos = position
		mouse_previous_pos = mouse_pos
		mouse_delta = Vector2(0,0)
		update_zoom()
	
	


	
func update_zoom():
	zoom_level = clamp(zoom_level, 1,zoom_level_max)
	zoom.x = zoom_level
	zoom.y = zoom_level
	pass
	
func update_pan():
	if pan_mode:
		position = camera_previous_pos - mouse_delta*zoom_level
	pass

var last_unix_time = 0
func _process(delta):
	
	if int(OS.get_unix_time()) != int(last_unix_time):
		OS.set_window_title("Dialogue Editor | FPS: " + str(int(1/delta)))
		last_unix_time = OS.get_unix_time()
