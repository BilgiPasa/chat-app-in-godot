extends Control

@export var reset_text_timer: Timer
@export var version_label: Label

@export var start_menu: Control
@export var username_text_edit: TextEdit
@export var host_button: Button
@export var join_button: Button
@export var warning_label: Label

@export var chat_menu: Control
@export var chat_text_edit: TextEdit
@export var message_text_edit: TextEdit

const PORT: int = 9999
const USERNAME_ERROR_TEXT: String = "Please enter a username."
const USERNAME_ERROR_TEXT_2: String = "Please don't have a space at the start of the username."
const USERNAME_ERROR_TEXT_3: String = "Please don't have a space at the end of the username."

var lobby_chat: String = "" # This variable is only used by the host.
var username: String

func _ready() -> void:
	multiplayer.connected_to_server.connect(made_connection)
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_text_timer.wait_time = 0.1
	version_label.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	warning_label.hide()
	chat_text_edit.editable = false
	open_start_menu()

func made_connection() -> void:
	open_chat_menu()

func open_start_menu() -> void:
	start_menu.process_mode = Node.PROCESS_MODE_INHERIT
	start_menu.show()
	chat_menu.process_mode = Node.PROCESS_MODE_DISABLED
	chat_menu.hide()
	username_text_edit.grab_focus()

func open_chat_menu() -> void:
	start_menu.process_mode = Node.PROCESS_MODE_DISABLED
	start_menu.hide()
	chat_menu.process_mode = Node.PROCESS_MODE_INHERIT
	chat_menu.show()
	message_text_edit.grab_focus()

func _on_host_button_pressed() -> void:
	if text_is_null_or_empty(username_text_edit.text): # If the username is null or empty
		warning_label.text = USERNAME_ERROR_TEXT
		warning_label.show()
	elif username_text_edit.text[0] == " ": # If the username's first character is a space
		warning_label.text = USERNAME_ERROR_TEXT
		warning_label.show()
	elif username_text_edit.text[username_text_edit.text.length() - 1] == " ": # If the username's last character is a space
		warning_label.text = USERNAME_ERROR_TEXT
		warning_label.show()
	else:
		username = username_text_edit.text
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_server(PORT)

		if error:
			warning_label.text = "Could not create a server.\nENetMultiplayerPeer.create_server error " + str(error)
			warning_label.show()
			return

		multiplayer.multiplayer_peer = peer
		open_chat_menu()

func _on_join_button_pressed() -> void:
	if text_is_null_or_empty(username_text_edit.text): # If the username is null or empty
		warning_label.text = USERNAME_ERROR_TEXT
		warning_label.show()
	elif username_text_edit.text[0] == " ": # If the username's first character is a space
		warning_label.text = USERNAME_ERROR_TEXT
		warning_label.show()
	elif username_text_edit.text[username_text_edit.text.length() - 1] == " ": # If the username's last character is a space
		warning_label.text = USERNAME_ERROR_TEXT
		warning_label.show()
	else:
		username = username_text_edit.text
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_client("127.0.0.1", PORT)

		if error:
			warning_label.text = "Could not create a server.\nENetMultiplayerPeer.create_client error " + str(error)
			warning_label.show()
			return

		multiplayer.multiplayer_peer = peer
		warning_label.text = "Trying to connect to the server."
		warning_label.show()

func _on_send_button_pressed() -> void:
	message_text_edit.grab_focus()

	if text_is_null_or_empty(message_text_edit.text) || text_is_full_of_spaces(message_text_edit.text): # If the message is null or empty or full of spaces
		reset_text_timer.start()
	else:
		send_message_and_reset_text("\n" + username + ": " + message_text_edit.text)

func send_message_and_reset_text(message: String) -> void:
	send_message.rpc(message)
	reset_text_timer.start()

@rpc("any_peer", "call_local", "reliable")
func send_message(message: String) -> void:
	if multiplayer.multiplayer_peer.get_unique_id() == 1: # If the sender is host
		lobby_chat += message
		update_chat.rpc(lobby_chat)

@rpc("authority", "call_local", "reliable")
func update_chat(chat_string: String) -> void:
	chat_text_edit.text = chat_string
	chat_text_edit.scroll_vertical = chat_text_edit.get_line_count()

func _on_reset_text_timer_timeout() -> void:
	reset_text_timer.stop()
	message_text_edit.text = ""

func text_is_null_or_empty(text: String) -> bool:
	return text == null || text.is_empty()

func text_is_full_of_spaces(text: String) -> bool:
	for i in range(0, text.length()):
		if text[i] != " ": # If there is a character which is not space
			return false

	return true
