extends Node


## Node refrencing 
var DiscordChannelID 
var DiscordToken
var HostUI
var ClientUI 

var host_ip 
var current_client = {
	"user" : "none", 
	"role" : "none",
	"peerid" : "00000000"
	}
signal server_message_received(message_text)
signal message_received(metadata,message_text)
## WE USE GLOBAL SCRIPT TO RECIVE AND SEND DATA AND SIGNALS 
## WE CALL GLOBAL.RPC("FUNCTION_NAME", FUCNTION ARGS) TO SEND SIGNALS TO ALL LOCATION 
enum actions { 
	TEXT,
	IMAGE,
}
@rpc("authority")
func tell_server(player,data,amount):
	pass

@rpc("any_peer", "reliable")
func _send_request_client_data_rpc(requested_id: int) -> void:
	_receive_request_data.rpc_id(requested_id, multiplayer.get_unique_id())

@rpc("any_peer", "reliable")
func _receive_request_data(sender_id: int,) -> void:
	var payload = {
		"user": current_client.user,
		"role": current_client.role,
		"peerid": current_client.peerid,
	}
	receive_data.rpc_id(sender_id, payload)

@rpc("any_peer","reliable")
func receive_data(data):
	print("Received Data From Pull: ", data)

@rpc("any_peer")
func tell_clients(text):
	# Check for the Lobby label
	server_message_received.emit(text)
	print("DEBUG: Signal 'server_message_received' was emitted.")

@rpc("any_peer","call_local")
func new_message(metadata,text):
	print("You have mail")
	message_received.emit(metadata,text)
	
@rpc("any_peer")
func updateclientlist(client,info):
	LanHandler.clients[client] = info

@rpc("authority")
func checkinfo(client):
	pass
