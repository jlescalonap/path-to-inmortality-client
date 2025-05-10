extends Control

# En Godot 4, usamos esto:
var socket
var selected_gender := ""
var message_label: Label
var connection_attempt_timer: Timer

func _ready():
	# Obter referência ao MessageLabel
	message_label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MessageLabel
	if not message_label:
		push_error("MessageLabel não encontrado na cena!")
		return
	
	# Criar timer para timeout de conexão
	connection_attempt_timer = Timer.new()
	connection_attempt_timer.one_shot = true
	connection_attempt_timer.timeout.connect(_on_connection_timeout)
	add_child(connection_attempt_timer)
	
	# Conexão de sinais na UI
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GenderMale.pressed.connect(_on_gender_male_pressed)
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GenderFemale.pressed.connect(_on_gender_female_pressed)
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ConnectButton.pressed.connect(_on_connect_pressed)
	
	# Conexão de sinais do Global
	Global.connect("login_successful", _on_login_successful)
	Global.connect("login_failed", _on_login_failed)
	Global.connect("connection_lost", _on_connection_lost)
	Global.connect("connection_established", _on_connection_established)
	
	message_label.text = "Bienvenido! Por favor ingresa tu nombre y género."

func _on_gender_male_pressed():
	selected_gender = "male"
	# Visual feedback
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GenderMale.add_theme_color_override("font_color", Color(0, 1, 0))
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GenderFemale.remove_theme_color_override("font_color")

func _on_gender_female_pressed():
	selected_gender = "female"
	# Visual feedback
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GenderFemale.add_theme_color_override("font_color", Color(0, 1, 0))
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GenderMale.remove_theme_color_override("font_color")

func _on_connect_pressed():
	var player_name = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerName.text.strip_edges()
	if player_name == "" or selected_gender == "":
		message_label.text = "Ingresa tu nombre y género."
		return
	
	message_label.text = "Conectando al servidor..."
	print("Tentando conectar ao servidor")
	
	# Inicializar a conexão WebSocket com o servidor
	if Global.connect_to_server():
		message_label.text = "Esperando respuesta del servidor..."
		
		# Definir tempo limite para conexão (10 segundos)
		connection_attempt_timer.start(10.0)
	else:
		message_label.text = "Error de conexión: No se pudo iniciar la conexión al servidor."

func _on_connection_timeout():
	message_label.text = "Tiempo de espera agotado. El servidor no responde."
	print("Timeout de conexão. Servidor não respondeu.")
	# Tentar reconectar ou mostrar opções para o usuário

func _on_connection_established():
	print("Conexão estabelecida, enviando dados de login")
	message_label.text = "Conexión establecida, enviando datos de login..."
	
	# Parar o timer de timeout
	connection_attempt_timer.stop()
	
	# Enviar dados de login agora que temos uma conexão estabelecida
	var player_name = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/PlayerName.text.strip_edges()
	if not Global.login(player_name, selected_gender):
		message_label.text = "Error al enviar datos de login."

func _on_login_successful():
	print("Login bem-sucedido! ID: " + Global.player_id)
	message_label.text = "¡Login exitoso! Entrando al juego..."
	# Aguardar um momento para mostrar a mensagem antes de mudar de cena
	await get_tree().create_timer(1.0).timeout
	# Mudar para a cena principal do jogo
	get_tree().change_scene_to_file("res://GameWorld.tscn")

func _on_login_failed(error_message):
	print("Falha no login: " + error_message)
	message_label.text = "Error de login: " + error_message

func _on_connection_lost():
	print("Conexão perdida com o servidor")
	message_label.text = "Se perdió la conexión con el servidor."
	connection_attempt_timer.stop()

func _exit_tree():
	# Desconectar sinais para evitar vazamentos de memória
	Global.disconnect("login_successful", _on_login_successful)
	Global.disconnect("login_failed", _on_login_failed)
	Global.disconnect("connection_lost", _on_connection_lost)
	Global.disconnect("connection_established", _on_connection_established)
	
	# Remover o timer
	if connection_attempt_timer:
		connection_attempt_timer.stop()
		connection_attempt_timer.queue_free()
