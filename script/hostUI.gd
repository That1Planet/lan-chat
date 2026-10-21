extends Control
var addresses
var ipv4s: Array = []

func _ready():
	get_all_ipv4()
	LanHandler.client_connected.connect(_on_client_list_changed)
	LanHandler.client_disconnected.connect(_on_client_list_changed_disc)
	Global.HostUI = self
	await get_tree().process_frame
	$"Text Boxes/IPAddress".text = str(ipv4s).remove_chars('"[]')
	$"Text Boxes/Username".text = Global.current_client.user
	

func _process(delta: float) -> void:
	LanHandler.handle_server_broadcasting(delta)
func get_all_ipv4() -> Array:
	for address in IP.get_local_addresses():
		if address.is_valid_ip_address() and address.find(":") == -1 and not address.begins_with("127.") and not address.begins_with("169."):
			address = address.remove_chars('"[]')
			ipv4s.append(address)
	return ipv4s

#func add_to_client_list(client_id, client_info: Dictionary):
	#print("New Client ", client_id, client_info)
	#$"Text Boxes/ClientList".text += client_info.get("name") + ": " + str(client_id) + "\n"
#
#func remove_from_client_list(client_id):
	#var text : String = $"Text Boxes/ClientList".text
	#var lines = text.split("\n")
	#var finished_lines = ["Client List: [br]"]
	#for line in lines:
		#if line.contains(str(client_id)):
			#continue
		#else:
			#finished_lines.append(line)
	#
	#text = "\n".join(finished_lines)
	#$"Text Boxes/ClientList".text = text
# Triggered when a client connects
func _on_client_list_changed(client_id, client_info: Dictionary):
	print("Client connected: ", client_id, client_info)
	refresh_client_display()

# Triggered when a client disconnects
func _on_client_list_changed_disc(client_id):
	print("Client disconnected: ", client_id)
	refresh_client_display()
	
func refresh_client_display():
	var list_text = "Client List:\n"
	
	# Loop through all active clients stored in LanHandler
	for id in LanHandler.clients:
		var client_info = LanHandler.clients[id]
		var client_name = client_info.get("name", "Player")
		list_text += client_name + ": " + str(id) + "\n"
	
	# Update the UI text box cleanly without duplicate headers or stale entries
	$"Text Boxes/ClientList".text = list_text

func _on_discovery_toggle_toggled(toggled_on: bool) -> void:
	LanHandler.set_discoverable(toggled_on)
	if toggled_on:
		print("Server is now discoverable on the LAN.")
		$VBoxContainer/ServerDiscovery/ColorRect.color = Color(0.0, 0.662, 0.161, 1.0)
	else:
		$VBoxContainer/ServerDiscovery/ColorRect.color = Color(0.99, 0.0, 0.0, 1.0)
		print("Server is now hidden from LAN discovery.")
		
@rpc("authority")
func _on_server_message_text_submitted(new_text: String) -> void:
	Global.rpc("tell_clients",new_text)


func _on_spawn_test_text_pressed() -> void:
	Global.rpc("new_message",)


func _on_regrab_ip_pressed() -> void:
	pass # Replace with function body.


func _on_refresh_list_pressed() -> void:
	LanHandler.refresh_client_list()


func _on_kick_all_pressed() -> void:
	pass # Replace with function body.


func _on_save_text_log_pressed() -> void:
	pass # Replace with function body.


func _on_reset_server_pressed() -> void:
	LanHandler.restart_server()


func _on_line_edit_text_submitted(new_text: String) -> void:
	LanHandler.server_name = new_text


func _on_line_edit_2_text_submitted(new_text: String) -> void:
	LanHandler.server_description = new_text


func _on_username_text_submitted(new_text: String) -> void:
	Global.current_client.user = new_text
	LanHandler.client_info.set("name", new_text)
	LanHandler.refresh_client_list()
	$"Text Boxes/Username".text = new_text
