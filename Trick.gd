extends Area3D

@export var trick_id: int = 1 # Vault
@onready var obstacle : StaticBody3D = get_parent()
@onready var shape_node := $CollisionShape3D 

var extents

signal player_entered_trick_area(trick_id, obstacle)
signal player_exited_trick_area()

func _ready():
	add_to_group("trick")
	extents = shape_node.shape.size * 0.5  # size is full dimensions


func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("player_entered_trick_area", trick_id, obstacle)

func _on_body_exited(body):
	if body.is_in_group("player"):
		emit_signal("player_exited_trick_area")
