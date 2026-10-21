extends Panel
class_name msg

var content = ""
var extcontent = ""
var exfiletype = ""
var bbcode_effects
var user = "USER"
var time = Time.get_unix_time_from_system()
var filetype = "string"
var image_size = 100
func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Wait for container layout to settle
	await get_tree().process_frame
	
	# Dynamically get parent width, defaulting safely if unavailable
	var parent_width = 300.0
	if get_parent().get_parent() is Control and get_parent().get_parent().size.x > 0:
		parent_width = get_parent().get_parent().size.x - 20 # 20px margin padding
	var usable_width = parent_width
	var text_width = usable_width - 20 # 10px padding on left and right
	
	custom_minimum_size = Vector2(usable_width, 50)
	position = Vector2.ZERO
	
	# Setup the username and timestamp header
	var name_display = WrapRichText.new()
	name_display.bbcode_enabled = true
	name_display.position = Vector2(10, 5)
	name_display.custom_minimum_size = Vector2(text_width, 25)
	name_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_display.text = user + " [color=#808080]" + str(format_message_time(time)) + "[/color]"
	add_child(name_display)
	var current_y = 30.0
	var text_to_display
	if filetype == "string":
		text_to_display = content
	elif extcontent != "":
		text_to_display = extcontent
	
	var text = WrapRichText.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.position = Vector2(10, 30)
	text.custom_minimum_size = Vector2(text_width, 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	if (content is PackedByteArray and text_to_display != "" and exfiletype == "string") or (content is not PackedByteArray and filetype == "string"):
		text.text = text_to_display
		await get_tree().process_frame
		add_child(text)
		var total_height_text = text.position.y + text.get_content_height() + 10
		current_y += total_height_text
	if filetype != "string" and filetype != null:
		var texture_rect = load_image_from_buffer(content,filetype,text_width)
		if extcontent != "":
			texture_rect.position.y = current_y - 30
		await get_tree().process_frame
		var total_height_image = texture_rect.position.y + texture_rect.size.y + 15 # 15px bottom padding
		current_y += total_height_image
		if extcontent != "":
			custom_minimum_size = Vector2(usable_width, max(50,current_y - 100)) 
		else:
			custom_minimum_size = Vector2(usable_width, max(50,current_y - 25))
	else:
		custom_minimum_size = Vector2(usable_width, max(50,current_y))
	

func load_image_from_buffer(buffer, type, text_width):
	var image = Image.new()
	var loaded_file : Error = FAILED
	
	match type.to_lower():
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
		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		texture_rect.texture = texture
		texture_rect.position = Vector2(10,30)
		texture_rect.custom_minimum_size.x = text_width
		texture_rect.custom_minimum_size.y = image_size
		texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(texture_rect)
		print("loaded image from buffer")
		return texture_rect
	else:
		print("IMAGE FAILED TO LOAD FROM BUFFER")
		return
		
## Formats a message's unix timestamp relative to the current system time in local time.
func format_message_time(msg_unix_time: float) -> String:
	# Dynamically convert UTC unix time to local time using the system's timezone bias (in minutes)
	var local_unix_time = msg_unix_time + (Time.get_time_zone_from_system().bias * 60)
	
	# 1. Get the date/time dictionaries for both the message and now using local time
	var msg_dict = Time.get_datetime_dict_from_unix_time(local_unix_time)
	var now_dict = Time.get_datetime_dict_from_system(false) # false = local system time
	
	# 2. Convert 24-hour time to 12-hour format and determine AM/PM
	var period = "AM"
	var hour_12 = msg_dict.hour
	
	if hour_12 >= 12:
		period = "PM"
		if hour_12 > 12:
			hour_12 -= 12
	elif hour_12 == 0:
		hour_12 = 12
		
	# Format the minute string to always be two digits (e.g., "05" instead of "5")
	var minute_str = "%02d" % msg_dict.minute
	var time_str = "%d:%s %s" % [hour_12, minute_str, period]
	
	# 3. Check if it's the exact same calendar day (Same Year, Month, and Day)
	var is_same_day = (msg_dict.year == now_dict.year and 
					   msg_dict.month == now_dict.month and 
					   msg_dict.day == now_dict.day)
	
	if is_same_day:
		# Output format: "5:40 PM"
		return time_str
	else:
		# Get a readable month string using a match block
		var month_name = ""
		match msg_dict.month:
			1: month_name = "Jan"
			2: month_name = "Feb"
			3: month_name = "Mar"
			4: month_name = "Apr"
			5: month_name = "May"
			6: month_name = "Jun"
			7: month_name = "Jul"
			8: month_name = "Aug"
			9: month_name = "Sep"
			10: month_name = "Oct"
			11: month_name = "Nov"
			12: month_name = "Dec"
			
		# Output format: "Oct 15, 5:40 PM" (Includes year if it's a completely different year)
		if msg_dict.year != now_dict.year:
			return "%s %d, %d, %s" % [month_name, msg_dict.day, msg_dict.year, time_str]
		else:
			return "%s %d, %s" % [month_name, msg_dict.day, time_str]
