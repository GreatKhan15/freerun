extends Node3D

@export var player_scene: PackedScene
@export var level_scene: PackedScene
var level : Node3D

var players: Dictionary = {}

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _ready():
	var peer = ENetMultiplayerPeer.new()
	
	#peer.create_server(12345)
	#multiplayer.multiplayer_peer = peer
	#print("Server started on port 12345")
	
	level = level_scene.instantiate()
	add_child(level)

	#peer.create_client("localhost", 12345)
	#multiplayer.multiplayer_peer = peer
	#print("Connecting to server...")
	
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_on_connected_to_server()

func _on_connected_to_server():
	print("Connected to server!")
	#spawn_player(multiplayer.get_unique_id())
	spawn_player(1)

func _on_peer_connected(id: int):
	if multiplayer.is_server():
		spawn_player(id)

func _on_peer_disconnected(id: int):
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
		print("Player %d disconnected" % id)

func spawn_player(id: int):
	var player = player_scene.instantiate()
	player.setup_player(id)
	players[id] = player
	player.global_position = level.get_node("SpawnPoint").global_position
	add_child(player)
	if multiplayer.is_server():
		var level = get_node_or_null("Level")
		if level:
			level.start_race(player)
