extends Panel

@onready var frame_grid := %FrameGrid
@onready var pic_grid := %PictureGrid
const PICS_FOLDER := "res://Textures/ProfilePics/"
const FRAMES_FOLDER := "res://Textures/ProfileFrames/"

var selected_frame
var selected_pic

func _ready():
	load_profile_frames()
	load_profile_pics()
	
	selected_frame = PlayerProfile.get_profile_frame()
	selected_pic = PlayerProfile.get_profile_pic()
	
	%TestPic.texture = load("res://Textures/ProfilePics/ProfilePic%s.png"%PlayerProfile.get_profile_pic())
	%TestFrame.texture = load("res://Textures/ProfileFrames/Frame%s.png"%PlayerProfile.get_profile_frame())

func load_profile_frames():
	var dir = DirAccess.open(FRAMES_FOLDER)
	if dir == null:
		print("Error: Folder not found!")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension() in ["png", "jpg", "jpeg", "webp"]:
			var image_path = FRAMES_FOLDER + file_name
			var texture = load(image_path)
			var this_image_int = image_path.to_int()

			var pic_button = TextureButton.new()
			pic_button.texture_normal = texture
			pic_button.custom_minimum_size = Vector2(115, 115)
			pic_button.stretch_mode = TextureButton.STRETCH_SCALE
			pic_button.ignore_texture_size = true

			pic_button.pressed.connect(func():
				%TestFrame.texture = load("res://Textures/ProfileFrames/Frame%s.png"%this_image_int)
				selected_frame = this_image_int
			)

			frame_grid.add_child(pic_button)
		
		file_name = dir.get_next()

	dir.list_dir_end()
	
func load_profile_pics():
	var dir = DirAccess.open(PICS_FOLDER)
	if dir == null:
		print("Error: Folder not found!")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension() in ["png", "jpg", "jpeg", "webp"]:
			var image_path = PICS_FOLDER + file_name
			var texture = load(image_path)
			var this_image_int = image_path.to_int()

			var pic_button = TextureButton.new()
			pic_button.texture_normal = texture
			pic_button.custom_minimum_size = Vector2(115, 115)
			pic_button.stretch_mode = TextureButton.STRETCH_SCALE
			pic_button.ignore_texture_size = true
			
			pic_button.pressed.connect(func():
				%TestPic.texture = load("res://Textures/ProfilePics/ProfilePic%s.png"%this_image_int)
				selected_pic = this_image_int
			)

			pic_grid.add_child(pic_button)
		
		file_name = dir.get_next()

	dir.list_dir_end()


func _on_save_button_pressed():
	PlayerProfile.set_profile_pic(selected_pic)
	PlayerProfile.set_profile_frame(selected_frame)
	visible = false
	%TestPic.visible = false
	%TestFrame.visible = false

func _on_cancel_button_pressed():
	visible = false
	%TestPic.visible = false
	%TestFrame.visible = false
