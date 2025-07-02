extends Node

@export var playerScene : PackedScene
@export var map : PackedScene

var spawnPosition : Vector3
var racePosition : Vector3

var port = 12345

const SERVER_PORT = 8080
var SERVER_IP = "127.0.0.1"
var map_instance
var my_player
var raceStarted = false

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("ui_q"):
			if Input.is_key_pressed(KEY_ALT):
				get_tree().quit()
		elif event.is_action_pressed("ui_startrace"):
			if multiplayer.is_server():
				#Start Race
				if not raceStarted:
					start_race()
				
	if Input.is_action_just_pressed("ui_enter"):
		print("Enter")
		%Say.visible = !%Say.visible
		if %Say.visible:
			%MessagesBox.show()
			%MessagesDisapearTimer.stop()
		else:
			%MessagesDisapearTimer.start()
			
		if %Say.text != "" and not %Say.visible:
			send_message.rpc(multiplayer.get_unique_id(), %Say.text)
			%Say.text = ""

func _ready() -> void:

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _on_viewport_size_changed():
	%Say.size.x = get_viewport().size.x / 2
	%Say.position.x = get_viewport().size.x / 4
	%Say.position.y = (get_viewport().size.y / 4) * 3


func _process(delta: float) -> void:
	pass


func _on_host_button_pressed() -> void:
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = server_peer
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(del_player)
	load_game()

	#%Server.show()

func _on_join_button_pressed() -> void:	
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP,SERVER_PORT)
	
	multiplayer.multiplayer_peer = client_peer	
	multiplayer.connected_to_server.connect(load_game)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_to_text_submitted(new_text: String) -> void:
	_on_join_button_pressed() 

func _peer_connected(id: int):
	print("peer %s connected" % id)


func del_player(id):
	_del_player.rpc(id)
	_del_player(id)

@rpc("call_local")
func _del_player(id):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	map_instance.remove_marker(id)
	

func load_game():	
	%Menu.hide()
	map_instance = map.instantiate()
	%Map.add_child(map_instance)
	
	for child in map_instance.get_children():
		if child.name.begins_with("Spawn"):
			spawnPosition = child.global_position
		elif child.name.begins_with("RaceStart"):
			racePosition = child.global_position
	
	if multiplayer.is_server():
		_spawn_this(1)
	else:
		spawn_request.rpc_id(1,multiplayer.get_unique_id())
	
@rpc("any_peer")
func spawn_request(id):
	_spawn_this.rpc(id)

@rpc("call_local")
func _spawn_this(id):
	var playerToAdd = playerScene.instantiate()
	playerToAdd.name = str(id)
	playerToAdd.player_id = id
	playerToAdd.set_multiplayer_authority(id)
	$Players.add_child(playerToAdd)
	playerToAdd.global_position = spawnPosition
	if multiplayer.get_unique_id() == id:
		my_player = playerToAdd
		map_instance.my_player = my_player
		
	map_instance.add_marker(id)

func start_race():
	raceStarted = true
	var spacing = 0
	for players in %Players.get_children():
		var spawnSpotperPlayer = racePosition + (Vector3(0,0,1)*spacing)
		map_instance.setup_race(players)
		if players.player_id == 1:
			map_instance.position_start(spawnSpotperPlayer)
		else:
			map_instance.position_start.rpc_id(players.player_id,spawnSpotperPlayer)
		spacing += 2

func _on_connection_failed():
	print("Connection failed")


func _on_server_disconnected():
	print("Server DC %s" % multiplayer.get_unique_id())	
	%Menu.show()
	%Lobby.hide()

	for child in %Map.get_children():
		child.queue_free()
	for child in %Players.get_children():
		child.queue_free()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	


@rpc("call_local", "any_peer")
func send_message(id, message):
	%MessagesBox.show()
	var label = Label.new()
	label.modulate = Color(1, 0.75, 0)
	if id == 1:
		label.modulate = Color.GREEN
		label.text = "SERVER: " + message
	else:
		label.text = str(id) + ": " + message
	%Messages.get_child(0).queue_free()
	%Messages.add_child(label)
	%MessagesDisapearTimer.start()


func _on_enter_button_pressed() -> void:
	%Lobby.hide()


func _on_messages_disapear_timer_timeout() -> void:
	%MessagesBox.hide()
