extends Node3D

var start_position: Vector3 = Vector3(0, 2, 0)
var checkpoints: Array[Area3D] = []
var finish_line: Area3D
var race_times: Dictionary = {}

@onready var timer_label: Label = $TimerLabel

func _ready():
	# Find checkpoints and finish line
	for child in get_children():
		if child is Area3D and child.name.begins_with("Checkpoint"):
			checkpoints.append(child)
			child.body_entered.connect(_on_checkpoint_entered.bind(child))
		elif child.name == "FinishLine":
			finish_line = child
			finish_line.body_entered.connect(_on_finish_line_entered)
	checkpoints.sort_custom(func(a, b): return a.name < b.name)

func _process(delta):
	if multiplayer.is_server():
		for player in get_tree().get_nodes_in_group("players"):
			if player.player_id in race_times:
				race_times[player.player_id]["time"] += delta
				update_timer.rpc(player.player_id, race_times[player.player_id]["time"])

@rpc("authority")
func update_timer(player_id: int, time: float):
	if multiplayer.get_unique_id() == player_id:
		timer_label.text = "Time: %.2f" % time

func start_race(player: CharacterBody3D):
	if multiplayer.is_server():
		player.global_position = start_position
		race_times[player.player_id] = {"time": 0.0, "checkpoint": 0}
		notify_race_start.rpc(player.player_id)

@rpc("authority")
func notify_race_start(player_id: int):
	if multiplayer.get_unique_id() == player_id:
		print("Race started!")

func _on_checkpoint_entered(body: Node, checkpoint: Area3D):
	if multiplayer.is_server() and body.is_in_group("players"):
		var current_checkpoint = race_times[body.player_id]["checkpoint"]
		var checkpoint_index = checkpoints.find(checkpoint)
		if checkpoint_index == current_checkpoint:
			race_times[body.player_id]["checkpoint"] += 1
			notify_checkpoint.rpc(body.player_id, checkpoint_index + 1)

@rpc("authority")
func notify_checkpoint(player_id: int, checkpoint_num: int):
	if multiplayer.get_unique_id() == player_id:
		print("Checkpoint %d reached!" % checkpoint_num)

func _on_finish_line_entered(body: Node):
	if multiplayer.is_server() and body.is_in_group("players"):
		var player_id = body.player_id
		if race_times[player_id]["checkpoint"] == checkpoints.size():
			var time = race_times[player_id]["time"]
			notify_finish.rpc(player_id, time)
			race_times.erase(player_id)

@rpc("authority")
func notify_finish(player_id: int, time: float):
	if multiplayer.get_unique_id() == player_id:
		print("Finished race in %.2f seconds!" % time)
