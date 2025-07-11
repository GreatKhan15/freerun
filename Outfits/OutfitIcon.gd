extends Control

signal gear_selected(typein,itemin)

@onready var texture_rect = $TextureRect
var preview_instance: Node = null

@onready var button = $Button
var type = 1
var item = 1
var gridIcon = false
var active = true

func _ready():
	preview_instance = preload("res://Outfits/OutfitPreview.tscn").instantiate()
	add_child(preview_instance)  # Add to self to keep it alive (not to TextureRect)
	texture_rect.texture = preview_instance.get_texture()
	button.pressed.connect(_on_icon_pressed)

func set_cloth_mesh(mesh: Mesh, typein, itemin):
	if active:
		type = typein
		item = itemin
		if preview_instance:
			preview_instance.set_cloth_mesh(mesh)

func load_item(typein,itemin,deffo):
	if active:
		type = typein
		item = itemin
		if preview_instance:
			preview_instance.set_item(typein,itemin)
			fix_color(preview_instance.get_mat().albedo_color)

func fix_color(color):
	find_child("ColorPick").fix_color(color)

func _on_icon_pressed():
	if active:
		emit_signal("gear_selected", type,item)

func get_mesh_material() -> Material:
	if preview_instance:
		return preview_instance.get_mat()
	return null

func turn_off():
	active = false
	visible = false
	
func turn_on():
	active = true
	visible = true
	
