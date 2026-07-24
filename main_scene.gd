extends Control

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

var username: String

func _ready() -> void:
	multiplayer.connected_to_server.connect(made_connection)
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if username_text_edit.text == null || username_text_edit.text.is_empty():
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
	if username_text_edit.text == null || username_text_edit.text.is_empty():
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
	pass # Replace with function body.
