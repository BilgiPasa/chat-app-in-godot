extends Control

@export var reset_text_timer: Timer # For sending message when pressed enter
@export var revert_text_timer: Timer # For reverting text when pressed tab
@export var dots_timer: Timer # For animating the dots of the wait menu warning label
@export var version_label: Label

@export var start_menu: Control # The menu that shows at start
@export var username_text_edit: TextEdit
@export var host_button: Button
@export var join_button: Button
@export var start_menu_warning_label: Label

@export var wait_menu: Control # The wait menu that appeares after pressing the "Join Lobby" button
@export var entered_username_label: Label
@export var cancel_button: Button
@export var wait_menu_warning_label: Label

@export var chat_menu: Control # The chat menu
@export var chat_text_edit: TextEdit
@export var message_text_edit: TextEdit
@export var send_button: Button
@export var host_or_client_label: Label # Shows that if you are a host or a client

const PORT: int = 9999 # The server port
const TEXT_TIMERS_WAIT_SECONDS: float = 0.01
const DOTS_TIMER_WAIT_SECONDS: float = 0.75
const USERNAME_ERROR_TEXT: String = "Please enter a username."
const USERNAME_ERROR_TEXT_2: String = "Please don't have a space\nat the start of the username."
const USERNAME_ERROR_TEXT_3: String = "Please don't have a space\nat the end of the username."
const TRYING_TO_CONNECT_TEXT: String = "Trying to connect to the server."

var dots_of_the_text: int = 1 # For the dots_timer
var lobby_chat: String = "" # This variable is used by only the host.
var username: String
var temp_str: String # For storing texts temporarily
var text_for_host_or_client_lbl: String

enum RevertTypes{USERNAME, MESSAGE} # Types of text reverting when pressed tab
var current_revert_type: RevertTypes # Used for reverting text when pressed tab
var shift_tabbed_at_start_menu: bool = false # Used for determining what to grab focus after reverting the text at the start menu

func _ready() -> void:
	multiplayer.connected_to_server.connect(made_connection)
	multiplayer.connection_failed.connect(failed_connection)
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_text_timer.wait_time = TEXT_TIMERS_WAIT_SECONDS
	revert_text_timer.wait_time = TEXT_TIMERS_WAIT_SECONDS
	dots_timer.wait_time = DOTS_TIMER_WAIT_SECONDS
	version_label.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	chat_text_edit.editable = false
	open_start_menu()

func made_connection() -> void: # When client makes connection and enters a lobby
	open_chat_menu()
	send_message.rpc("\n[Client] " + username + " entered the lobby at " + Time.get_time_string_from_system())

func failed_connection() -> void: # When client fails to connect
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	open_start_menu()
	show_start_menu_warning_lbl("Could not connect to the server.")

func open_start_menu() -> void: # Open the start menu, Close the wait and chat menus
	dots_timer.stop()
	dots_of_the_text = 1 # Reset "Trying to connect" dot animation
	start_menu.process_mode = Node.PROCESS_MODE_INHERIT
	start_menu.show()
	wait_menu.process_mode = Node.PROCESS_MODE_DISABLED
	wait_menu.hide()
	chat_menu.process_mode = Node.PROCESS_MODE_DISABLED
	chat_menu.hide()
	start_menu_warning_label.hide()
	username_text_edit.grab_focus()

func open_wait_menu() -> void: # Open the wait menu, Close the start and chat menus
	start_menu.process_mode = Node.PROCESS_MODE_DISABLED
	start_menu.hide()
	wait_menu.process_mode = Node.PROCESS_MODE_INHERIT
	wait_menu.show()
	chat_menu.process_mode = Node.PROCESS_MODE_DISABLED
	chat_menu.hide()
	entered_username_label.text = "Entered username: " + username
	show_wait_menu_warning_lbl(TRYING_TO_CONNECT_TEXT)
	dots_timer.start()

func open_chat_menu() -> void: # Open the chat menu, Close the start and wait menus
	dots_timer.stop()
	dots_of_the_text = 1 # Reset "Trying to connect" dot animation
	start_menu.process_mode = Node.PROCESS_MODE_DISABLED
	start_menu.hide()
	wait_menu.process_mode = Node.PROCESS_MODE_DISABLED
	wait_menu.hide()
	chat_menu.process_mode = Node.PROCESS_MODE_INHERIT
	chat_menu.show()
	host_or_client_label.text = text_for_host_or_client_lbl
	message_text_edit.grab_focus()

func _on_host_button_pressed() -> void:
	if text_is_null_or_empty(username_text_edit.text): # If the username is null or empty
		show_start_menu_warning_lbl(USERNAME_ERROR_TEXT)
	elif username_text_edit.text[0] == " ": # If the username's first character is a space
		show_start_menu_warning_lbl(USERNAME_ERROR_TEXT_2)
	elif username_text_edit.text[username_text_edit.text.length() - 1] == " ": # If the username's last character is a space
		show_start_menu_warning_lbl(USERNAME_ERROR_TEXT_3)
	else:
		username = username_text_edit.text
		var peer = ENetMultiplayerPeer.new()
		var error: int = peer.create_server(PORT)

		if error == 20: # If the error is ERR_CANT_CREATE
			show_start_menu_warning_lbl("Could not create a server.\nTry to join instead.")
			return
		elif error == 22: # If the error is ERR_ALREADY_IN_USE
			show_start_menu_warning_lbl("Could not create a server.\nYou are already in a server.")
			return
		elif error: # If there is an another error
			show_start_menu_warning_lbl("Could not create a server.\nENetMultiplayerPeer.create_server error ")
			return

		multiplayer.multiplayer_peer = peer
		text_for_host_or_client_lbl = "Host"
		open_chat_menu()
		send_message.rpc("[Host] " + username + " created the lobby at " + Time.get_time_string_from_system())

func _on_join_button_pressed() -> void:
	if text_is_null_or_empty(username_text_edit.text): # If the username is null or empty
		show_start_menu_warning_lbl(USERNAME_ERROR_TEXT)
	elif username_text_edit.text[0] == " ": # If the username's first character is a space
		show_start_menu_warning_lbl(USERNAME_ERROR_TEXT_2)
	elif username_text_edit.text[username_text_edit.text.length() - 1] == " ": # If the username's last character is a space
		show_start_menu_warning_lbl(USERNAME_ERROR_TEXT_3)
	else:
		username = username_text_edit.text
		var peer = ENetMultiplayerPeer.new()
		var error: int = peer.create_client("127.0.0.1", PORT) # Connect to localhost

		if error == 20: # If the error is ERR_CANT_CREATE
			show_start_menu_warning_lbl("Could not connect to a server.\nTry to host instead.")
			return
		elif error == 22: # If the error is ERR_ALREADY_IN_USE
			show_start_menu_warning_lbl("Could not connect to a server.\nYou are already in a server.")
			return
		elif error: # If there is an another error
			show_start_menu_warning_lbl("Could not create a server.\nENetMultiplayerPeer.create_client error ")
			return

		multiplayer.multiplayer_peer = peer
		text_for_host_or_client_lbl = "Client"
		open_wait_menu()

func _on_cancel_button_pressed() -> void:
	dots_timer.stop()
	open_start_menu()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("enter"): # If pressed enter
		if start_menu.visible && username_text_edit.has_focus():
			current_revert_type = RevertTypes.USERNAME
			temp_str = username_text_edit.text
			revert_text_timer.start()
		elif chat_menu.visible && message_text_edit.has_focus():
			temp_str = message_text_edit.text

			if text_is_null_or_empty(temp_str) || text_is_full_of_spaces(temp_str):
				reset_text_timer.start()
			else:
				send_message_and_reset_text("\n" + username + ": " + temp_str)

	if event.is_action_pressed("tab"): # If pressed tab
		if start_menu.visible && username_text_edit.has_focus():
			current_revert_type = RevertTypes.USERNAME
			temp_str = username_text_edit.text
			revert_text_timer.start()
		elif chat_menu.visible && message_text_edit.has_focus():
			current_revert_type = RevertTypes.MESSAGE
			temp_str = message_text_edit.text
			revert_text_timer.start()

	if event.is_action_pressed("shift_tab"): # If pressed shift + tab
		if start_menu.visible && username_text_edit.has_focus():
			shift_tabbed_at_start_menu = true
			current_revert_type = RevertTypes.USERNAME
			temp_str = username_text_edit.text
			revert_text_timer.start()
		elif chat_menu.visible && message_text_edit.has_focus():
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
	send_message.rpc(message) # Call the send_message function remotely
	reset_text_timer.start()

"""
How the messaging system works:
	When someone sends a message, the sender calls the "send_message" function with rpc.
	Because the rpc sync is "call_local", when this function is called with rpc, this function is executed
	at all of the peers.
	But because of the if statement "if multiplayer.multiplayer_peer.get_unique_id() == 1:", inside of the
	if statement is executed by only the host.
	So, when someone sends a message, the message string is added to the host's "lobby_chat" string and the
	"update_chat" function is called with rpc by the host.
	In that function, the host updates and scrolls down the chat of all peers.
"""

# When called with rpc, add the given message to host's "lobby_chat" string variable and call the update_chat function with rpc at host
@rpc("any_peer", "call_local", "reliable") # "any_peer" means that everyone can call this function with rpc
func send_message(message: String) -> void:
	if multiplayer.multiplayer_peer.get_unique_id() == 1: # If this function is executed at host
		lobby_chat += message
		update_chat.rpc(lobby_chat)

# When called with rpc, update the chat of everyone based on host's "lobby_chat" string variable and scroll down the chat of everyone
@rpc("authority", "call_local", "reliable") # "authority" means that only the host can call this function with rpc
func update_chat(chat_string: String) -> void:
	chat_text_edit.text = chat_string
	chat_text_edit.scroll_vertical = chat_text_edit.get_line_count() # Scroll down the chat to the end

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

func _on_dots_timer_timeout() -> void:
	if dots_of_the_text == 1:
		show_wait_menu_warning_lbl(TRYING_TO_CONNECT_TEXT + ".")
		dots_of_the_text = 2
	elif dots_of_the_text == 2:
		show_wait_menu_warning_lbl(TRYING_TO_CONNECT_TEXT + "..")
		dots_of_the_text = 3
	else:
		show_wait_menu_warning_lbl(TRYING_TO_CONNECT_TEXT)
		dots_of_the_text = 1

func text_is_null_or_empty(text: String) -> bool:
	return text == null || text.is_empty()

func text_is_full_of_spaces(text: String) -> bool:
	for i in range(0, text.length()):
		if text[i] != " ": # If there is a character which is not space
			return false

	return true

func show_start_menu_warning_lbl(text: String):
	start_menu_warning_label.text = text
	start_menu_warning_label.show()

func show_wait_menu_warning_lbl(text: String):
	wait_menu_warning_label.text = text
	wait_menu_warning_label.show()
