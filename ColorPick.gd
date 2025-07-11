extends ColorPickerButton

@onready var parent_icon = get_parent()

func _ready():
	color = get_material_color()
	color_changed.connect(_on_color_changed)

func _on_color_changed(new_color: Color):
	if parent_icon.gridIcon == true :
		color_changed.disconnect(_on_color_changed)
		return
	set_material_color(new_color)

func get_material_color() -> Color:
	if parent_icon.has_method("get_mesh_material"):
		var mat = parent_icon.get_mesh_material()
		if mat:
			return mat.albedo_color
	return Color.GRAY

func set_material_color(new_color: Color):
	if parent_icon.has_method("get_mesh_material"):
		var mat = parent_icon.get_mesh_material()
		if mat:
			mat.albedo_color = new_color
			if parent_icon.name == "MyHair":
				%DisplayChar.change_mesh(1,1,2,new_color)
			if parent_icon.name == "MyTop":
				%DisplayChar.change_mesh(2,1,2,new_color)
			if parent_icon.name == "MyPants":
				%DisplayChar.change_mesh(3,1,2,new_color)
			if parent_icon.name == "MyShoes":
				%DisplayChar.change_mesh(4,1,2,new_color)

func fix_color(colorin):
	if colorin:
		color = colorin

func reset_color():
	if parent_icon.name == "MyHair":
		%DisplayChar.loadup_part(1)
		%MyHair.load_item(1,PlayerProfile.get_hair(),true)
		%MyHair.fix_color(PlayerProfile.get_hair_color())
	elif parent_icon.name == "MyTop":
		%DisplayChar.loadup_part(2)
		%MyTop.load_item(2,PlayerProfile.get_top(),true)
		%MyTop.fix_color(PlayerProfile.get_top_color())
	elif parent_icon.name == "MyPants":
		%DisplayChar.loadup_part(3)
		%MyPants.load_item(3,PlayerProfile.get_pants(),true)
		%MyPants.fix_color(PlayerProfile.get_pants_color())
	elif parent_icon.name == "MyShoes":
		%DisplayChar.loadup_part(4)
		%DisplayChar.change_mesh(4,1,1,Color.WHITE)
		%MyShoes.load_item(4,PlayerProfile.get_shoes(),true)
		%MyShoes.fix_color(PlayerProfile.get_shoes_color())
