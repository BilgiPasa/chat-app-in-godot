extends Control

@export var reset_text_timer: Timer
@export var revert_text_timer: Timer
@export var version_label: Label

@export var start_menu: Control
@export var username_text_edit: TextEdit
@export var host_button: Button
@export var join_button: Button
@export var warning_label: Label

@export var chat_menu: Control
@export var chat_text_edit: TextEdit
@export var message_text_edit: TextEdit
@export var send_button: Button

const PORT: int = 9999
const TEXT_TIMERS_WAIT_SECONDS: float = 0.1
const USERNAME_ERROR_TEXT: String = "Please enter a username."
const USERNAME_ERROR_TEXT_2: String = "Please don't have a space at the start of the username."
const USERNAME_ERROR_TEXT_3: String = "Please don't have a space at the end of the username."

var lobby_chat: String = "" # This variable is only used by the host.
var username: String
var temp_str: String

enum RevertTypes{USERNAME, MESSAGE} # Types of text reverting when pressed tab
var current_revert_type: RevertTypes
var shift_tabbed_at_start_menu: bool = false # Used for determining what to grab focus after reverting the text at the start menu

func _ready() -> void:
	multiplayer.connected_to_server.connect(made_connection)
	multiplayer.connection_failed.connect(failed_connection)
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_text_timer.wait_time = TEXT_TIMERS_WAIT_SECONDS
	revert_text_timer.wait_time = TEXT_TIMERS_WAIT_SECONDS
	version_label.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	warning_label.hide()
	chat_text_edit.editable = false
	open_start_menu()

func made_connection() -> void:
	open_chat_menu()
	send_message.rpc("\n[Client] " + username + " entered the lobby at " + Time.get_time_string_from_system())

func failed_connection() -> void:
	show_warning_label_with_text("Could not connect to the server.")
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	host_button.disabled = false
	join_button.disabled = false

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
		show_warning_label_with_text(USERNAME_ERROR_TEXT)
	elif username_text_edit.text[0] == " ": # If the username's first character is a space
		show_warning_label_with_text(USERNAME_ERROR_TEXT_2)
	elif username_text_edit.text[username_text_edit.text.length() - 1] == " ": # If the username's last character is a space
		show_warning_label_with_text(USERNAME_ERROR_TEXT_3)
	else:
		username = username_text_edit.text
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_server(PORT)

		if error:
			show_warning_label_with_text("Could not create a server.\nENetMultiplayerPeer.create_server error " + str(error))
			return

		multiplayer.multiplayer_peer = peer
		host_button.disabled = true
		join_button.disabled = true
		open_chat_menu()
		send_message.rpc("[Host] " + username + " created the lobby at " + Time.get_time_string_from_system())

func _on_join_button_pressed() -> void:
	if text_is_null_or_empty(username_text_edit.text): # If the username is null or empty
		show_warning_label_with_text(USERNAME_ERROR_TEXT)
	elif username_text_edit.text[0] == " ": # If the username's first character is a space
		show_warning_label_with_text(USERNAME_ERROR_TEXT_2)
	elif username_text_edit.text[username_text_edit.text.length() - 1] == " ": # If the username's last character is a space
		show_warning_label_with_text(USERNAME_ERROR_TEXT_3)
	else:
		username = username_text_edit.text
		var peer = ENetMultiplayerPeer.new()
		var error = peer.create_client("127.0.0.1", PORT)

		if error:
			show_warning_label_with_text("Could not create a server.\nENetMultiplayerPeer.create_client error " + str(error))
			return

		multiplayer.multiplayer_peer = peer
		host_button.disabled = true
		join_button.disabled = true
		show_warning_label_with_text("Trying to connect to the server.")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter"):
		if start_menu.visible && username_text_edit.has_focus():
			current_revert_type = RevertTypes.USERNAME
			temp_str = username_text_edit.text
			revert_text_timer.start()
		elif !start_menu.visible && message_text_edit.has_focus():
			temp_str = message_text_edit.text

			if text_is_null_or_empty(temp_str) || text_is_full_of_spaces(temp_str):
				reset_text_timer.start()
			else:
				send_message_and_reset_text("\n" + username + ": " + temp_str)

	if event.is_action_pressed("shift_tab"):
		if start_menu.visible && username_text_edit.has_focus():
			shift_tabbed_at_start_menu = true
			current_revert_type = RevertTypes.USERNAME
			temp_str = username_text_edit.text
			revert_text_timer.start()
		elif !start_menu.visible && message_text_edit.has_focus():
			current_revert_type = RevertTypes.MESSAGE
			temp_str = message_text_edit.text
			revert_text_timer.start()
	elif event.is_action_pressed("tab"):
		if start_menu.visible && username_text_edit.has_focus():
			current_revert_type = RevertTypes.USERNAME
			temp_str = username_text_edit.text
			revert_text_timer.start()
		elif !start_menu.visible && message_text_edit.has_focus():
			current_revert_type = RevertTypes.MESSAGE
			temp_str = message_text_edit.text
			revert_text_timer.start()

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

func _on_revert_text_timer_timeout() -> void:
	revert_text_timer.stop()

	if current_revert_type == RevertTypes.USERNAME:
		username_text_edit.text = temp_str

		if !shift_tabbed_at_start_menu:
			host_button.grab_focus()
		else:
			shift_tabbed_at_start_menu = false
			join_button.grab_focus()
	elif current_revert_type == RevertTypes.MESSAGE:
		message_text_edit.text = temp_str
		send_button.grab_focus()

func text_is_null_or_empty(text: String) -> bool:
	return text == null || text.is_empty()

func text_is_full_of_spaces(text: String) -> bool:
	for i in range(0, text.length()):
		if text[i] != " ": # If there is a character which is not space
			return false

	return true

func show_warning_label_with_text(text: String):
	warning_label.text = text
	warning_label.show()
