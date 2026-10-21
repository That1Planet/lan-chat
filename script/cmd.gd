# DebugConsoleLine.gd
# "give" to add items, or "tp" to teleport the player.

extends LineEdit
class_name DebugConsoleLine

# Key to toggle the console on/off
const TOGGLE_KEY := KEY_F1

func _ready() -> void:
	# Ensure this node always processes input even if the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Placeholder to guide the user
	placeholder_text = "Type command then press Enter (give \"res://Items/Sword.tres\" or tp (100,200))"
	# Connect the "text_submitted" signal, called when Enter is pressed
	connect("text_submitted", Callable(self, "_on_text_submitted"))


func _unhandled_input(event: InputEvent) -> void:
	# Toggle the console when F1 is pressed
	if event is InputEventKey and event.pressed and event.keycode == TOGGLE_KEY:
		if visible:
			_close_console()
		else:
			_open_console()


func _open_console() -> void:
	text = ""          # clear previous text
	visible = true     # show console
	grab_focus()       # capture keyboard input so player stops moving


func _close_console() -> void:
	visible = false    # hide console
	release_focus()    # release keyboard input


# Called when Enter is pressed
func _on_text_submitted(new_text: String) -> void:
	# Remove spaces at the start and end
	var command: String = new_text.strip_edges()
	if command != "":
		_process_command(command)  # handle the command
	clear()  # clear input box
	_close_console()

# ---------------------------
# Command processor
# ---------------------------
func _process_command(command: String) -> void:
	# Split command into parts (e.g., "give" and the filepath)
	var parts: Array = _split_args(command)
	if parts.size() == 0:
		return

	var cmd: String = str(parts[0]).to_lower() # first word is command
	var args: Array = []
	if parts.size() > 1:
		args = parts.slice(1, parts.size()) # rest are arguments

	# Dispatch command
	match cmd:
		"help":            
			_cmd_help()
		"setnameself":
			Global.current_client.user = args[0]
			LanHandler.client_info.set("name", args[0])
		"grab":
			_cmd_grab_data_id(args)
		"setname":
			_cmd_set_name(args)
		"callum_scukhehe":
			_cmd_crash()
		_:
			print("Unknown command:", cmd)

# ---------------------------
# Commands
# --------------------------- 

# --- help command ---
func _cmd_help() -> void:
	print("--- Developer Console Help ---")
	print("give <resource_path>     - Add an item to the player's inventory")
	print("tp <x> <y>               - Teleport player to coordinates")
	print("tp (<x>,<y>)             - Teleport player using parentheses format")
	print("help                     - Show this help message")
	print("You can use quotes for paths with spaces: give \"res://Items/My Sword.tres\"")

# --- set player id name ---
func _cmd_set_name(args):
	pass

func _cmd_grab_data_id(args):
	if args.size() == 1:
		Global._send_request_client_data_rpc(args[0])
# --- crash the game ---
func _cmd_crash():
	get_tree().root.queue_free()
# ---------------------------
# Argument splitter
# ---------------------------
func _split_args(command: String) -> Array:
	# This function splits a command into arguments, handling quotes and parentheses
	var out: Array = []           # store final arguments
	var i: int = 0                # current index in string
	var n: int = command.length() # total length of string

	while i < n:
		# Skip whitespace
		while i < n and command[i] == " ":
			i += 1
		if i >= n:
			break

		var ch: String = command[i]

		# Handle double-quoted strings
		if ch == "\"":
			var j: int = command.find("\"", i + 1) # find closing quote
			if j == -1: # if not found, go to end
				j = n
			out.append(command.substr(i + 1, j - (i + 1))) # grab string without quotes
			i = j + 1

		# Handle single-quoted strings
		elif ch == "'":
			var j: int = command.find("'", i + 1)
			if j == -1:
				j = n
			out.append(command.substr(i + 1, j - (i + 1)))
			i = j + 1

		# Handle parentheses (e.g., (100,200))
		elif ch == "(":
			var depth: int = 1  # track nested parentheses
			var j: int = i + 1   # start looking after '('
			while j < n and depth > 0:
				var c: String = command[j]
				if c == "(":
					depth += 1
				elif c == ")":
					depth -= 1
					if depth == 0:
						j += 1
						break
				j += 1
			out.append(command.substr(i, j - i)) # include the parentheses
			i = j

		# Handle unquoted words
		else:
			var j: int = command.find(" ", i) # find next space
			if j == -1: # if no space, take until end
				out.append(command.substr(i, n - i))
				break
			else:
				out.append(command.substr(i, j - i))
				i = j + 1

	return out
