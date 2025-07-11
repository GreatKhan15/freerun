extends CharacterBody3D

@export var character_int = 1
@export var hair_int = 1
@export var tops_int = 1
@export var pants_int = 1

var current_hair = 1
var current_top = 1
var current_pants = 1
var current_shoes = 1

var hair_color = null
var top_color = null
var pants_color = null
var shoes_color = null


const TIANA_MESH = preload("res://Characters/Tiana/TianaBase.tres")
const TIANA_SKIN = preload("res://Characters/Tiana/TianaSkin.tres")

const CATTY_MESH = preload("res://Characters/Catty/CattyBase.tres")
const CATTY_SKIN = preload("res://Characters/Catty/CattySkin.tres")

const JINZO_MESH = preload("res://Characters/Jinzo/Jinzo.tres")
const JINZO_SKIN = preload("res://Characters/Jinzo/JinzoSkin.tres")

var editableChar = true

@onready var animTree = $AnimationPlayer/AnimationTree

var inspect = false
var animtype = 1

func _ready():
	
	loadup_character()
	current_hair = PlayerProfile.get_hair()
	current_top = PlayerProfile.get_top()
	current_pants = PlayerProfile.get_pants()
	current_shoes = PlayerProfile.get_shoes()
func loadup_character():
	var selection = PlayerProfile.get_character()
	change_char(selection)
	loadup_outfit()
	
func change_char(selection):
	if selection == 1:
		character_int = 1
		$Armature/Skeleton3D/Character_001.mesh = TIANA_MESH
		$Armature/Skeleton3D/Character_001.skin = TIANA_SKIN
	if selection == 2:
		character_int = 2
		$Armature/Skeleton3D/Character_001.mesh = CATTY_MESH
		$Armature/Skeleton3D/Character_001.skin = CATTY_SKIN
		
	if selection == 3:
		character_int = 3
		$Armature/Skeleton3D/Character_001.mesh = JINZO_MESH
		$Armature/Skeleton3D/Character_001.skin = JINZO_SKIN
		
	
	if selection == 2:
		$Armature/Skeleton3D/Hair.mesh = null
		$Armature/Skeleton3D/Top.mesh = null
		$Armature/Skeleton3D/Pants.mesh = null
		$Armature/Skeleton3D/Shoes.mesh = null
		%MyHair.turn_off()
		%MyTop.turn_off()
		%MyPants.turn_off()
		%MyShoes.turn_off()
		editableChar = false
	else:
		%MyHair.turn_on()
		%MyTop.turn_on()
		%MyPants.turn_on()
		%MyShoes.turn_on()
		editableChar = true
		loadup_outfit()
		
		
	
func loadup_outfit():
	if not character_int == 2:
		if PlayerProfile.get_character() == character_int:
			$Armature/Skeleton3D/Hair.mesh = load("res://Outfits/Hair/Hair%s.tres"%PlayerProfile.get_hair())
			$Armature/Skeleton3D/Top.mesh = load("res://Outfits/Tops/Shirt%s.tres"%PlayerProfile.get_top())
			$Armature/Skeleton3D/Pants.mesh = load("res://Outfits/Pants/Pants%s.tres"%PlayerProfile.get_pants())
			$Armature/Skeleton3D/Shoes.mesh = load("res://Outfits/Shoes/Shoes%s.tres"%PlayerProfile.get_shoes())
			
			hair_color = PlayerProfile.get_hair_color()
			top_color = PlayerProfile.get_top_color()
			pants_color = PlayerProfile.get_pants_color()
			shoes_color = PlayerProfile.get_shoes_color()
			
			if not hair_color:
				hair_color = extract_mat($Armature/Skeleton3D/Hair)
			if not top_color:
				top_color = extract_mat($Armature/Skeleton3D/Top)
			if not pants_color:
				pants_color = extract_mat($Armature/Skeleton3D/Pants)
			if not shoes_color:
				shoes_color = extract_mat($Armature/Skeleton3D/Shoes)
			
			$Armature/Skeleton3D/Hair.get_active_material(0).albedo_color = hair_color
			$Armature/Skeleton3D/Top.get_active_material(0).albedo_color = top_color
			$Armature/Skeleton3D/Pants.get_active_material(0).albedo_color = pants_color
			$Armature/Skeleton3D/Shoes.get_active_material(0).albedo_color = shoes_color
		else:
			$Armature/Skeleton3D/Hair.mesh = load("res://Outfits/Hair/Hair1.tres")
			$Armature/Skeleton3D/Top.mesh = load("res://Outfits/Tops/Shirt1.tres")
			$Armature/Skeleton3D/Pants.mesh = load("res://Outfits/Pants/Pants1.tres")
			$Armature/Skeleton3D/Shoes.mesh = load("res://Outfits/Shoes/Shoes1.tres")
			
			hair_color = extract_mat($Armature/Skeleton3D/Hair)
			top_color = extract_mat($Armature/Skeleton3D/Top)
			pants_color = extract_mat($Armature/Skeleton3D/Pants)
			shoes_color = extract_mat($Armature/Skeleton3D/Shoes)
			
			current_hair = 1
			current_top = 1
			current_pants = 1
			current_shoes = 1

func loadup_part(typein):

	if typein == 1:
		$Armature/Skeleton3D/Hair.mesh = load("res://Outfits/Hair/Hair%s.tres"%PlayerProfile.get_hair())
		current_hair = PlayerProfile.get_hair()
		hair_color = PlayerProfile.get_hair_color()
		if not hair_color:
			hair_color = extract_mat($Armature/Skeleton3D/Hair)
		$Armature/Skeleton3D/Hair.get_active_material(0).albedo_color = hair_color
	elif typein == 2:
		$Armature/Skeleton3D/Top.mesh = load("res://Outfits/Tops/Shirt%s.tres"%PlayerProfile.get_top())
		current_top = PlayerProfile.get_top()
		if not top_color:
			top_color = extract_mat($Armature/Skeleton3D/Top)
		$Armature/Skeleton3D/Top.get_active_material(0).albedo_color = top_color
			
	elif typein == 3:
		$Armature/Skeleton3D/Pants.mesh = load("res://Outfits/Pants/Pants%s.tres"%PlayerProfile.get_pants())
		current_pants = PlayerProfile.get_pants()
		pants_color = PlayerProfile.get_pants_color()
		if not pants_color:
			pants_color = extract_mat($Armature/Skeleton3D/Pants)
		$Armature/Skeleton3D/Pants.get_active_material(0).albedo_color = pants_color
	elif typein == 4:
		$Armature/Skeleton3D/Shoes.mesh = load("res://Outfits/Shoes/Shoes%s.tres"%PlayerProfile.get_shoes())
		current_shoes = PlayerProfile.get_shoes()
		shoes_color = PlayerProfile.get_shoes_color()
		if not shoes_color:
			shoes_color = extract_mat($Armature/Skeleton3D/Shoes)
		$Armature/Skeleton3D/Shoes.get_active_material(0).albedo_color = shoes_color

func turn_off_inspect_soon():
	await get_tree().create_timer(1.0).timeout
	inspect = false
	
func extract_mat(meshin):
	var mat = meshin.get_active_material(0)
	if mat:
		if mat and not mat.resource_local_to_scene:
			mat = mat.duplicate()
			mat.resource_local_to_scene = true
			meshin.set_surface_override_material(0, mat)
		return mat.albedo_color
	return null

func change_mesh(type,item,flag,color):
	
	inspect = true
	animtype = randi()%2 + 1
	turn_off_inspect_soon()
	print(inspect)
	
	if flag == 1:
		if type == 1:
			$Armature/Skeleton3D/Hair.mesh = load("res://Outfits/Hair/Hair%s.tres"%item)
			current_hair = item
		elif type == 2:
			$Armature/Skeleton3D/Top.mesh = load("res://Outfits/Tops/Shirt%s.tres"%item)
			current_top = item
		elif type == 3:
			$Armature/Skeleton3D/Pants.mesh = load("res://Outfits/Pants/Pants%s.tres"%item)
			current_pants = item
		elif type == 4:
			$Armature/Skeleton3D/Shoes.mesh = load("res://Outfits/Shoes/Shoes%s.tres"%item)
			current_shoes = item
	elif flag == 2:
		if type == 1:
			$Armature/Skeleton3D/Hair.get_active_material(0).albedo_color = color
			hair_color = color
		elif type == 2:
			$Armature/Skeleton3D/Top.get_active_material(0).albedo_color = color
			top_color = color
		elif type == 3:
			$Armature/Skeleton3D/Pants.get_active_material(0).albedo_color = color
			pants_color = color
		elif type == 4:
			$Armature/Skeleton3D/Shoes.get_active_material(0).albedo_color = color
			shoes_color = color


func save_outfit():
	PlayerProfile.set_character(character_int)
	
	PlayerProfile.set_hair(current_hair)
	PlayerProfile.set_top(current_top)
	PlayerProfile.set_pants(current_pants)
	PlayerProfile.set_shoes(current_shoes)
	
	PlayerProfile.set_hair_color(hair_color)
	PlayerProfile.set_top_color(top_color)
	PlayerProfile.set_pants_color(pants_color)
	PlayerProfile.set_shoes_color(shoes_color)

func _process(_delta):
	
	animTree.set("parameters/conditions/Inspect",inspect)
	if animtype == 1:
		animTree.set("parameters/StateMachine/conditions/Inspect1",true)
		animTree.set("parameters/StateMachine/conditions/Inspect2",false)
	elif animtype == 2:
		animTree.set("parameters/StateMachine/conditions/Inspect1",false)
		animTree.set("parameters/StateMachine/conditions/Inspect2",true)
	
