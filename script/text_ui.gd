extends Control
@onready var discord = preload("uid://butsg8veggryq")
# Node references based on standard chat layout structure
@onready var message_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var message_input: LineEdit = $LineEdit
@onready var send_button: Button = $Button

var currently_loaded_file = null
var filetype = null
var current_image_height = 100

func _ready() -> void:
	$ScrollContainer/VBoxContainer.custom_minimum_size.x = $ScrollContainer.size.x
	$Panel2.visible = false
	# 1. Connect to Global's signal to listen for incoming messages from any peer or the host[cite: 1]
	Global.message_received.connect(_on_message_received)
	get_window().files_dropped.connect(file_dropped)
	var discord_bot = $DiscordBot
	discord_bot.TOKEN = Global.DiscordToken 
	discord_bot.login()
	discord_bot.bot_ready.connect(_on_DiscordBot_bot_ready)
	discord_bot.message_create.connect(_on_DiscordBot_message_create)
	
func _on_DiscordBot_bot_ready(bot: DiscordBot):
	print("Logged in as %s#%s" % [bot.user.username, bot.user.discriminator])
	print("Listening on %d channels and %d guilds." % [bot.channels.size(), bot.guilds.size()])

## Sends the message to all clients and the host via the Global script RPC[cite: 1]
func send_message() -> void:
	if not message_input and not currently_loaded_file:
		return
		
	var text_content = message_input.text.strip_edges()
	if text_content.is_empty() and currently_loaded_file == null:
		return
	var payload = {
		"username" : Global.current_client.get("user", "none"),
		"timeutc" : Time.get_unix_time_from_system(),
		"filetype" : filetype,
		"current_image_height" : current_image_height,
		"duelmessage" : "",
		"filetype2" : ""
	}
	if payload["username"] == "none" or payload["username"].is_empty():
		payload["username"] = LanHandler.client_info.get("name", "Player")
	if currently_loaded_file:
		print("Sending Image")
		if not text_content.is_empty():
			payload["duelmessage"] = text_content
			payload["filetype2"] = "string"
		Global.rpc("new_message",payload, currently_loaded_file)
		$Panel2.visible = false
		$"Panel2/image display".texture = load("res://icon.svg")
		currently_loaded_file = null
		filetype = null
	else:
		# Call Global RPC to broadcast the message to all connected peers and host
		Global.rpc("new_message",payload, text_content)
		$DiscordBot.send(Global.DiscordChannelID, payload["username"]+ ": " + text_content)

	# Clear the input box after sending
	message_input.clear()

func file_dropped(file: PackedStringArray):
	if file.size() > 0:
		var file_path = file[0]
		var buffer = load_image_from_drop(file_path)
		if file_path.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp","svg"]:
			print("VALID file type")
			currently_loaded_file = buffer
			filetype = file_path.get_extension().to_lower()
		else:
			print("File is invalid")

func load_image_from_drop(filepath:String):
	print("Loading File: ", filepath)
	var file = FileAccess.open(filepath,FileAccess.READ)
	if file == null:
		return 
	var buffer : PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var image = Image.load_from_file(filepath)
	if image:
		$Panel2.visible = true
		var texture = ImageTexture.create_from_image(image)
		$"Panel2/image display".texture = texture
		$Panel2/RichTextLabel2.text = filepath.split("\\")[-1]
	return buffer
	
func load_image_from_buffer(buffer, filetype):
	var image = Image.new()
	var loaded_file : Error = FAILED
	
	match filetype.to_lower():
		"png":
			loaded_file = image.load_png_from_buffer(buffer)
		"jpg","jpeg":
			loaded_file = image.load_jpg_from_buffer(buffer)
		"webp":
			loaded_file = image.load_webp_from_buffer(buffer)
		"svg":
			loaded_file = image.load_svg_from_buffer(buffer)
		_:
			print("failed to find file type")
	
	if loaded_file == OK:
		var texture = ImageTexture.create_from_image(image)
		$Panel2.visible = true
		$"Panel2/image display".texture = texture
		print("loaded image from buffer")
	else:
		print("IMAGE FAILED TO LOAD FROM BUFFER")

## Receives broadcasted messages from Global, instantiates the msg class, and populates data[cite: 1, 6]
func _on_message_received(metadata : Dictionary, content) -> void:
	var username = metadata.get("username")
	
		
	# Instantiate the msg class script
	var new_message = msg.new()
	new_message.user = username
	#if timestamp != Time.get_unix_time_from_system():
		#pass
	var filetype = metadata.get("filetype")
	if filetype != null and filetype != "string":
		new_message.filetype = metadata["filetype"]
		new_message.image_size = metadata["current_image_height"]
		new_message.content = content
		new_message.extcontent = metadata.get("duelmessage")
		new_message.exfiletype = metadata.get("filetype2")
	else:
		new_message.content = str(content)
		new_message.filetype = "string"
		new_message.extcontent = ""
	
	if message_container:
		message_container.add_child(new_message)
		
		# Auto-scroll to the bottom of the chat window
		await get_tree().process_frame
		var scroll = $ScrollContainer as ScrollContainer
		if scroll:
			await get_tree().process_frame
			await get_tree().process_frame
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

@warning_ignore("unused_parameter")
func save_message(message,metadata):
	pass
## [time] User | filetype |  currentImageHeight | filetypetwo | content | duelmessage

@warning_ignore("unused_parameter")
func _on_line_edit_text_submitted(new_text: String) -> void:
	send_message()


func _on_button_pressed() -> void:
	send_message()


func _on_v_slider_value_changed(value: float) -> void:
	current_image_height = value
	
func _on_DiscordBot_message_create(bot: DiscordBot, msg: Message, channel: Dictionary):
	print("New message from %s: %s" % [msg.author.username, msg.content])

	if msg.author.bot:
		return
	var payload = {
		"username" : msg.author.username,
		"timeutc" : Time.get_unix_time_from_system(),
		"filetype" : filetype,
		"current_image_height" : current_image_height,
		"duelmessage" : "",
		"filetype2" : ""
	}
	print(msg.content + str(msg.message_reference))
	Global.rpc("new_message",payload, msg.content)
