extends Control

func _ready() -> void:
	Global.ClientUI = self
	$"Text Boxes/IPAddress".text = "Connected to: " + Global.host_ip
	$"Text Boxes/Username".text = Global.current_client.user

func _on_reconnect_pressed() -> void:
	LanHandler.reconnect_client()


func _on_line_edit_text_changed(new_text: String) -> void:
	Global.current_client.user = new_text
	LanHandler.client_info.set("name", new_text)
	$"Text Boxes/Username".text = "Username: " + new_text
	LanHandler.reconnect_client()

func _on_fetch_latest_pressed() -> void:
	pass # Replace with function body.
