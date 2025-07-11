extends Node3D

#1. Hair
#2. Tops
#3. Pants
#4. Shoes

@export var type = 1
@export var item = 1
var chosen = false
@onready var mesh_instance = $SubViewport/MeshInstance3D
var gridIcon = false
var original_mat

func _ready():
	if not chosen:
		if type == 1:
			mesh_instance.mesh = load("res://Outfits/Hair/Hair%s.tres"%item)
		elif type == 2:
			mesh_instance.mesh = load("res://Outfits/Tops/Shirt%s.tres"%item)
		elif type == 3:
			mesh_instance.mesh = load("res://Outfits/Pants/Pants%s.tres"%item)
		elif type == 4:
			mesh_instance.mesh = load("res://Outfits/Shoes/Shoes%s.tres"%item)
	if get_parent().gridIcon:
		gridIcon = true

func _process(delta):
	mesh_instance.rotate_y(0.5 * delta)

func set_cloth_mesh(mesh: Mesh):
	if not mesh:
		return

	mesh_instance.mesh = mesh
	mesh_instance.transform = Transform3D.IDENTITY

	var aabb = mesh.get_aabb()
	var center = aabb.position + aabb.size * 0.5

	var t = mesh_instance.transform
	t.origin = -center
	mesh_instance.transform = t

	var max_dim = max(aabb.size.x, aabb.size.y, aabb.size.z)
	if max_dim > 1.0:
		mesh_instance.scale = Vector3.ONE * (1.0 / max_dim)
	else:
		mesh_instance.scale = Vector3.ONE

	var cam = $SubViewport/Camera3D
	cam.transform.origin = Vector3(0, 0, max_dim * 2.0)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	
	original_mat = mesh_instance.get_active_material(0)
	var duped_mat = original_mat.duplicate()
	mesh_instance.set_surface_override_material(0, duped_mat)


func set_item(typein,itemin):
	mesh_instance.set_surface_override_material(0, null)
	if typein == 1:
		mesh_instance.mesh = load("res://Outfits/Hair/Hair%s.tres"%itemin)
	elif typein == 2:
		mesh_instance.mesh = load("res://Outfits/Tops/Shirt%s.tres"%itemin)
	elif typein == 3:
		mesh_instance.mesh = load("res://Outfits/Pants/Pants%s.tres"%itemin)
	elif typein == 4:
		mesh_instance.mesh = load("res://Outfits/Shoes/Shoes%s.tres"%itemin)
	
	
	mesh_instance.transform = Transform3D.IDENTITY

	var aabb = mesh_instance.mesh.get_aabb()
	var center = aabb.position + aabb.size * 0.5

	var t = mesh_instance.transform
	t.origin = -center
	mesh_instance.transform = t

	var max_dim = max(aabb.size.x, aabb.size.y, aabb.size.z)
	if max_dim > 1.0:
		mesh_instance.scale = Vector3.ONE * (1.0 / max_dim)
	else:
		mesh_instance.scale = Vector3.ONE

	var cam = $SubViewport/Camera3D
	cam.transform.origin = Vector3(0, 0, max_dim * 2.0)
	cam.look_at(Vector3.ZERO, Vector3.UP)


func get_texture() -> Texture2D:
	return $SubViewport.get_texture()

func get_mat() -> Material:
	var mat = mesh_instance.get_active_material(0)
	if mat and not mat.resource_local_to_scene:
		mat = mat.duplicate()
		mat.resource_local_to_scene = true
		if not gridIcon:
			mesh_instance.set_surface_override_material(0, mat)
	return mat
