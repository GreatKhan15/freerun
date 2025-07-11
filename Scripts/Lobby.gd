extends Node3D

@onready var  camera = $Camera3D
var CAMERASTARTPOS = Vector3(-4.0,1.2,-1.5)
var CAMERACHARPOS = Vector3(-4.0,1.0,-0.5)

@onready var normal_size_top = $LobbyMenu/TopCenter/Panel/TopMenuList/CharactersButton.size
@onready var hover_size_top = normal_size_top * 1.2
@onready var normal_size_char = $LobbyMenu/CharactersPanel/Control/Panel/CharacterList/Tina.size
@onready var hover_size_char = normal_size_char * 1.2

const CLOTH_ICON_SCENE = preload("res://Outfits/OutfitIcon.tscn")
const OUTFIT_ROOT = "res://Outfits/"

var DURATION = 0.2

var cameraTargetPos = CAMERASTARTPOS

@onready var display_character = $DisplayChar
var rotating = false
var last_mouse_pos = Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_in_center(event.position):
				rotating = true
				last_mouse_pos = event.position
			else:
				rotating = false
	elif event is InputEventMouseMotion and rotating:
		var delta = event.position.x - last_mouse_pos.x
		last_mouse_pos = event.position
		display_character.rotate_y(deg_to_rad(delta * 0.3))

func is_in_center(pos: Vector2) -> bool:
	var screen_center = get_viewport().size / 2
	return pos.distance_to(screen_center) < 450 
	
func _ready():
	
	cameraTargetPos = CAMERASTARTPOS
	
	var buttons_parent = $LobbyMenu/TopCenter/Panel/TopMenuList
	for button in buttons_parent.get_children():
		if button is Button or button is TextureButton:
			button.connect("mouse_entered", Callable(self, "_on_button_mouse_entered").bind(button,hover_size_top))
			button.connect("mouse_exited", Callable(self, "_on_button_mouse_exited").bind(button,normal_size_top))

	buttons_parent = $LobbyMenu/CharactersPanel/Control/Panel/CharacterList
	for button in buttons_parent.get_children():
		if button is Button or button is TextureButton:
			button.connect("mouse_entered", Callable(self, "_on_button_mouse_entered").bind(button,hover_size_char))
			button.connect("mouse_exited", Callable(self, "_on_button_mouse_exited").bind(button,normal_size_char))

	fill_up_outfit_grid()
	
	%MyHair.load_item(1,PlayerProfile.get_hair(),true)
	%MyTop.load_item(2,PlayerProfile.get_top(),true)
	%MyPants.load_item(3,PlayerProfile.get_pants(),true)
	%MyShoes.load_item(4,PlayerProfile.get_shoes(),true)
	
	%MyHair.fix_color(PlayerProfile.get_hair_color())
	%MyTop.fix_color(PlayerProfile.get_top_color())
	%MyPants.fix_color(PlayerProfile.get_pants_color())
	%MyShoes.fix_color(PlayerProfile.get_shoes_color())
	
	
	
func fill_up_outfit_grid():
	for grid in [%HairGrid, %TopsGrid, %PantsGrid, %ShoesGrid]:
		for child in grid.get_children():
			child.queue_free()

	var outfit_dirs = DirAccess.get_directories_at(OUTFIT_ROOT)
	for category in outfit_dirs:
		var category_path = OUTFIT_ROOT + category + "/"
		var outfit_files = DirAccess.get_files_at(category_path)
		
		for file in outfit_files:
			if file.get_extension() != "tres":
				continue
			
			var mesh_path = category_path + file
			var mesh = load(mesh_path)
			
			if mesh is Mesh:
				var icon_instance = CLOTH_ICON_SCENE.instantiate()
				var type = 0
				var target_grid

				match category:
					"Hair":
						type = 1
						target_grid = %HairGrid
					"Tops":
						type = 2
						target_grid = %TopsGrid
					"Pants":
						type = 3
						target_grid = %PantsGrid
					"Shoes":
						type = 4
						target_grid = %ShoesGrid
						
				if target_grid:
					target_grid.add_child(icon_instance)
				
				if type == 0:
					continue
					
				var item = mesh_path.to_int()
				icon_instance.set_cloth_mesh(mesh, type, item)
				icon_instance.gear_selected.connect(_on_gear_selected)
				icon_instance.gridIcon = true


func _on_gear_selected(type,item):
	if not %DisplayChar.editableChar:
		return
	%DisplayChar.change_mesh(type,item,1,Color.WHITE)
	match type:
		1:
			%MyHair.load_item(1,item,false)
		2:
			%MyTop.load_item(2,item,false)
		3:
			%MyPants.load_item(3,item,false)
		4:
			%MyShoes.load_item(4,item,false)
			
		
	
func _on_button_mouse_entered(button,size):
	if button.has_meta("tween"):
		button.get_meta("tween").kill()
	var tween = button.create_tween()
	tween.tween_property(button, "custom_minimum_size", size, 0.09)

func _on_button_mouse_exited(button,size):
	if button.has_meta("tween"):
		button.get_meta("tween").kill()
	var tween = button.create_tween()
	tween.tween_property(button, "custom_minimum_size", size, 0.09)
	
func _process(delta):
	camera.global_position = lerp(camera.global_position,cameraTargetPos,delta*4.0)

func _on_characters_button_pressed():
	%CharactersPanel.modulate.a = 0
	%CharactersPanel.show()
	%CharactersPanel.create_tween().tween_property(%CharactersPanel, "modulate:a", 1.0, 0.15)
	cameraTargetPos = CAMERACHARPOS


func _on_cancel_char_pressed():
	var tweeny = %CharactersPanel.create_tween()
	tweeny.tween_property(%CharactersPanel, "modulate:a", 0.0, 0.15)
	tweeny.tween_callback(%CharactersPanel.hide)
	tweeny.tween_callback(%OutfitsPanel.hide)
	tweeny.tween_callback(%MyCharOutfit.hide)
	cameraTargetPos = CAMERASTARTPOS
	
	%DisplayChar.loadup_character()
	%MyHair.load_item(1,PlayerProfile.get_hair(),true)
	%MyTop.load_item(2,PlayerProfile.get_top(),true)
	%MyPants.load_item(3,PlayerProfile.get_pants(),true)
	%MyShoes.load_item(4,PlayerProfile.get_shoes(),true)
	
	%MyHair.fix_color(PlayerProfile.get_hair_color())
	%MyTop.fix_color(PlayerProfile.get_top_color())
	%MyPants.fix_color(PlayerProfile.get_pants_color())
	%MyShoes.fix_color(PlayerProfile.get_shoes_color())
	


func _on_accept_char_pressed():
	var tweeny = %CharactersPanel.create_tween()
	tweeny.tween_property(%CharactersPanel, "modulate:a", 0.0, 0.15)
	tweeny.tween_callback(%CharactersPanel.hide)
	tweeny.tween_callback(%OutfitsPanel.hide)
	tweeny.tween_callback(%MyCharOutfit.hide)
	
	cameraTargetPos = CAMERASTARTPOS
	%DisplayChar.save_outfit()


func _on_customize_char_pressed():
	%OutfitsPanel.show()
	%MyCharOutfit.show()
	


func _on_tina_pressed():
	%DisplayChar.change_char(1)

func _on_catty_pressed():
	%DisplayChar.change_char(2)

func _on_jinzo_pressed():
	%DisplayChar.change_char(3)
