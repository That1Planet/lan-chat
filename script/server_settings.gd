extends Control

const ini_base_path = "user://"
var current_ini = "config.ini"

@onready var config_line: LineEdit = $Panel/ScrollContainer/Control/Config
@onready var load_ini_button: Button = $Panel/ScrollContainer/Control/LoadINI
@onready var server_name: LineEdit = $"Panel/ScrollContainer/Control/Server Name"
@onready var description: LineEdit = $Panel/ScrollContainer/Control/Description
@onready var text_only: CheckBox = $Panel/ScrollContainer/Control/TextOnly
@onready var username: CheckBox = $Panel/ScrollContainer/Control/Username

func _ready() -> void:
	self.visible = false

func update_ini():
	var config = ConfigFile.new()
	
	if config_line.text != "":
		current_ini = config_line.text
		if not current_ini.contains(".ini"):
			current_ini = current_ini.strip_edges() + ".ini"
	else:
		current_ini = "config.ini"

	config.set_value("INFO","NAME",server_name.text)
	config.set_value("INFO","DESC",description.text)
	
	config.set_value("SETTINGS","TEXT_ONLY",text_only.button_pressed)
	config.set_value("SETTINGS","USERNAME_LOCK",username.button_pressed)
	
	var err : Error = config.save(ini_base_path + current_ini)
	if err == OK:
		print("Saved/Updated INI File: ", ini_base_path + current_ini)

func _on_load_ini_pressed() -> void:
	load_ini(config_line.text)

func load_ini(path: String) -> void:
	var config = ConfigFile.new()
	var err : Error
	if path.contains("user://") and path.contains(".ini"):
		err = config.load(path)
	elif path.contains("user://"):
		err = config.load(path.strip_edges() + ".ini")
	else:
		err = config.load(ini_base_path + path.strip_edges() + ".ini")
	
	if err != OK:
		print("Config file not found or failed to load. Error code: ", err)
		return
		
	var configs : Dictionary = {}
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			configs["key"] = config.get_value(section, key)
	server_name.text = configs["NAME"]
	description.text = configs["DESC"]
	
	text_only.button_pressed = configs["TEXT_ONLY"]
	username.button_pressed = configs["USERNAME_LOCK"]
	
	
func _on_load_to_current_pressed() -> void:
	LanHandler.server_name = server_name.text
	LanHandler.server_description = description.text_only
