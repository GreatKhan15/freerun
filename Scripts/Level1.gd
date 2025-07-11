extends Node3D

var start_position: Vector3 = Vector3(0, 2, 0)
var finish_line: Area3D
var race_times: Dictionary = {}
var my_player
var race_started = false
var race_finished = false

var segment_progress : float
var cp_pos
var next_cp_pos

var winners: Array = [] 

@onready var racePath = $RacePath/Path3D
@onready var curve = $RacePath/Path3D.curve
@onready var spawnPoint = $SpawnPoint
@onready var timer_label: Label = $"CanvasLayer/UI/Top Right/MarginContainer/VBoxContainer/LapTimer"
@onready var raceProgressBar: ProgressBar = $"CanvasLayer/UI/Top Center/PanelContainer/ProgressBar"
@onready var playerTags = $CanvasLayer/PlayerTags
@onready var myTagParent = $CanvasLayer/MyTag
@onready var racePositionsCont = $"CanvasLayer/UI/Top Left/MarginContainer/VBoxContainer/RacePositions"

@export var spawnabletag : PackedScene
var myMarker

@onready var raceFinishSplash = $CanvasLayer/UI/FinishCover.material

func _ready():
	# Find checkpoints and finish line
	for mainchild in get_children():
		if mainchild.name.begins_with("RacePath"):
			for child in mainchild.get_children():
				if child.name == "FinishLine":
					finish_line = child
					finish_line.body_entered.connect(_on_finish_line_entered)
	#checkpoints.sort_custom(func(a, b): return a.name < b.name)
	
	
func _process(delta):
	
	for player in get_tree().get_nodes_in_group("players"):
		if multiplayer.is_server():
			if player.player_id in race_times:
				race_times[player.player_id]["time"] += delta
				update_timer.rpc(player.player_id, race_times[player.player_id]["time"])
			
		var found = false
		if my_player:
			if not player.name == my_player.name:
				for tags in playerTags.get_children():
					if tags.name == player.name:
						found = true
						tags.global_position.y = raceProgressBar.global_position.y - tags.size.y
						tags.global_position.x = raceProgressBar.global_position.x - (tags.size.x/2) + (player.raceprogress/100 * raceProgressBar.size.x)
					
				if not found:
					add_marker(player.name.to_int())
	
	if my_player:
		for player in get_tree().get_nodes_in_group("players"):
			if not player.has_node("NameTag"):
				var playerLabel = Label3D.new()
				playerLabel.text = "New Player"
				playerLabel.name = "NameTag"
				playerLabel.position = Vector3(0,3,0)
				player.add_child(playerLabel)
			if player.has_node("NameTag"):
				var playerNameTag = player.get_node("NameTag")
				playerNameTag.text = player.player_nick
				playerNameTag.look_at(my_player.savedCameraPos,Vector3.UP)
				playerNameTag.rotate_object_local(Vector3.UP, deg_to_rad(180))
		update_my_race_tag()
			
	update_race_positions()
func update_my_race_tag():
	if race_started and not race_finished:
		var player_pos = my_player.global_position

		var closest_offset = 0.0
		var min_distance := INF

		var steps = 300
		for i in steps:
			var t = float(i) / float(steps)
			var point = curve.sample_baked(t * curve.get_baked_length())
			var dist = player_pos.distance_to(racePath.to_global(point))
			if dist < min_distance:
				min_distance = dist
				closest_offset = t

		var progress_percent = closest_offset * 100.0
		raceProgressBar.value = progress_percent
		my_player.raceprogress = progress_percent
		myMarker.global_position.x = raceProgressBar.global_position.x - (myMarker.size.x/2) + (progress_percent/100 * raceProgressBar.size.x)
		
	myMarker.global_position.y = raceProgressBar.global_position.y - myMarker.size.y*1.2

func update_race_positions():
	var players = get_tree().get_nodes_in_group("players")
	var remaining_players = players.filter(func(p): return not winners.has(str(p.name)))
	remaining_players.sort_custom(func(a, b): return a.raceprogress > b.raceprogress)

	for child in racePositionsCont.get_children():
		child.queue_free()

	var i = 1

	for winner in winners:
		var label = RichTextLabel.new()
		label.bbcode_enabled = true
		label.modulate = Color.GOLD
		label.text = "%s# %s" %[str(i), winner]
		label.scroll_active = false
		label.fit_content = true
		racePositionsCont.add_child(label)
		i += 1

	for player in remaining_players:
		var label = RichTextLabel.new()
		label.modulate = Color.WHITE
		label.text = "%s# " % str(i)

		if my_player and player.name == my_player.name:
			label.modulate = Color.LIME_GREEN
			label.text += "%s" % player.player_nick
		else:
			label.text += "%s" % player.player_nick

		label.scroll_active = false
		label.fit_content = true
		racePositionsCont.add_child(label)
		i += 1


@rpc("call_local")
func update_timer(player_id: int, time: float):
	if multiplayer.get_unique_id() == player_id:
		var total_ms = int(time * 1000)
		var hours = total_ms / 3600000.0
		var minutes = (total_ms % 3600000) / 60000.0
		var seconds = (total_ms % 60000) / 1000.0
		var milliseconds = total_ms % 1000

		timer_label.text = "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]

func setup_race(player: CharacterBody3D):
	race_started = true
	race_times[player.player_id] = {"time": 0.0, "checkpoint": 0}
	


func add_marker(id: int):
	var tagToAdd = spawnabletag.instantiate()
	tagToAdd.name = str(id)
	if my_player.name == str(id):
		tagToAdd.texture = load("res://TagMarker.png")
		myMarker = tagToAdd
		myTagParent.add_child(tagToAdd)
	else:
		tagToAdd.texture = load("res://TagMarkerEnemy.png")
		playerTags.add_child(tagToAdd)
	
	tagToAdd.global_position.x = raceProgressBar.global_position.x - (tagToAdd.size.x/2)
	tagToAdd.global_position.y = raceProgressBar.global_position.y
	
func remove_marker(id: int):
	for tags in playerTags.get_children():
		if tags.name == str(id):
			tags.queue_free()
	

@rpc("call_local")
func position_start(pos):
	my_player.global_position = pos
	my_player.raceStarted = true
	race_started = true

func _on_finish_line_entered(body: Node):
	if multiplayer.is_server() and body.is_in_group("players") and body.player_id in race_times:
		var player_id = body.player_id
		
		var time = race_times[body.player_id]["time"]
		notify_finish.rpc(body.player_id, time)
		race_times.erase(body.player_id)

@rpc("call_local")
func notify_finish(player_id: int, time: float):
	winners.append(str(player_id))
	if my_player:
		if my_player.name == str(player_id):
			PlayerProfile.add_match()
			var total_ms = int(time * 1000)
			var hours = total_ms / 3600000.0
			var minutes = (total_ms % 3600000) / 60000.0
			var seconds = (total_ms % 60000) / 1000.0
			var milliseconds = total_ms % 1000

			print("Finished race in %.2f seconds!" % time)
			timer_label.text = "%02d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]
			$"CanvasLayer/UI/Top Right/MarginContainer/VBoxContainer/Laptime".text = "Finished! :"
			raceProgressBar.value = 100
			myMarker.global_position.x = raceProgressBar.global_position.x - (myMarker.size.x/2) + raceProgressBar.size.x
			race_finished = true
			my_player.raceprogress = 100
			my_player.raceFinished = true
			
			if raceFinishSplash and raceFinishSplash is ShaderMaterial:
				raceFinishSplash.set_shader_parameter("base_alpha", 0.05)
			
		
		
