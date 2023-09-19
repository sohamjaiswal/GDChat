extends Control

@onready var chatLog = get_node("VBoxContainer/RichTextLabel")
@onready var inputLabel = get_node("VBoxContainer/HBoxContainer/Label")
@onready var messageInputField = get_node("VBoxContainer/HBoxContainer/LineEdit")
@onready var addressInputField = get_node("VBoxContainer/VBoxContainer/HBoxContainer/LineEdit")
@onready var connectToServerButton = get_node("VBoxContainer/VBoxContainer/HBoxContainer/Button")
@onready var usernameInputField = get_node("VBoxContainer/VBoxContainer/HBoxContainer2/LineEdit")
@onready var updateUsernameButton = get_node("VBoxContainer/VBoxContainer/HBoxContainer2/Button")

var groups = [
	{'name': 'Team', 'color': '#71B571'},
	{'name': 'Match', 'color': '#DC143C'},
	{'name': 'Global', 'color': '#ffffff'},
	{'name': 'System', 'color': '#69c9f3'}
]

var serverAddress = 'localhost'

var group_index = 0
var username = 'default'

var _client = WebSocketPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	changeGroup()
	updateUsername()
	updateServerConnection()
	messageInputField.connect("text_submitted", text_submitted)
	connectToServerButton.connect("pressed", updateServerConnection)
	updateUsernameButton.connect("pressed", updateUsername)
	
func _process(_delta):
	_client.poll()
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			chatLog.append_text(_client.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		add_system_message("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1], code != -1)
		set_process(false) # Stop processing.

	
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			messageInputField.grab_focus()
			return
		if event.pressed and event.keycode == KEY_ESCAPE:
			messageInputField.release_focus()
			return
		if event.pressed and event.keycode == KEY_TAB:
			changeGroup()
			updateUsernameButton.grab_focus()
			return

func changeGroup():
	group_index += 1
	if group_index > (groups.size() - 2):
		group_index = 0
	inputLabel.text = '[' + groups[group_index]['name'] + ']'
	inputLabel.set("theme_override_colors/font_color", Color(groups[group_index]['color']))

func format_message(senderName: String, text: String, group = 0):
	return '[color=' + groups[group]['color'] + ']' + '[' + senderName + ']: ' + text + '[/color]' + '\n'

func add_message(senderName: String, text: String, group = 0):
	chatLog.append_text(format_message(senderName, text, group))

func add_system_message(text: String, error = false):
	if error:
		add_message("SYSTEM ERROR", text, 3)
		return
	add_message("SYSTEM", text, 3, )

func text_submitted(text):
	if text == '':
		return
	add_message(username, text, group_index)
	_client.send_text(format_message(username, text, group_index))
	messageInputField.clear()
	
func updateServerConnection():
	var prevServer = serverAddress
	serverAddress = addressInputField.text
	add_system_message('Removing ' + prevServer + ' & connecting to ' + serverAddress)
	var res = _client.connect_to_url(serverAddress)
	if res != OK:
		add_system_message("Could not connect to given server.", true)
		return
	add_system_message("Connected 🥳")

func updateUsername():
	var prevUsername = username
	username = usernameInputField.text
	add_system_message("Your username has been updated from " + prevUsername + " to " + username)
