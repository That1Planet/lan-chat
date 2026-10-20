extends Control


func _ready() -> void:
	pass
##Host
func _on_button_pressed() -> void:
	Global.current_client.role = "host"
	Global.current_client.user = $Panel2/TextEdit2.text
	if not $Panel2/TextEdit2.text:
		LanHandler.client_info.set("name", "Host")
	LanHandler.client_info.set("name", $Panel2/TextEdit2.text)
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://host_ui.tscn")
	LanHandler.create_lobby()
	
##Join
func _on_button_2_pressed() -> void:
	Global.current_client.user = $Panel2/TextEdit2.text
	Global.host_ip = str($Panel2/TextEdit.text)
	LanHandler.client_info.set("name",$Panel2/TextEdit2.text)
	if LanHandler.join_lobby(Global.host_ip):
		get_tree().change_scene_to_file("res://client_view.tscn")

##SETTINGS
func _on_button_3_pressed() -> void:
	$Settings.visible = true

##Quit
func _on_button_4_pressed() -> void:
	get_tree().quit()


func _on_button_5_pressed() -> void:
	$Panel3.visible = !$Panel3.visible
	await LanHandler.start_client_discovery()
	LanHandler.restart_client_discovery()


func _on_back_pressed() -> void:
	$Settings.visible = false


func _on_token_text_submitted(new_text: String) -> void:
	Global.DiscordToken = new_text


func _on_channel_id_text_submitted(new_text: String) -> void:
	Global.DiscordChannelID = new_text
