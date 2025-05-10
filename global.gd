extends Node

# Informações do jogador
var player_id = ""
var player_name = ""
var player_gender = ""

# Status da conexão
var websocket = null
var server_url = "ws://localhost:8080/ws"
var client_connected = false
var connection_in_progress = false

# Sinais para comunicação entre cenas
signal login_successful()
signal login_failed(error_message)
signal connection_established()
signal connection_lost()
signal message_received(data)

func _ready():
	# Inicializar o cliente apenas uma vez
	if websocket == null:
		initialize_websocket()

func initialize_websocket():
	websocket = WebSocketPeer.new()

func connect_to_server():
	print("Tentando conectar ao servidor: ", server_url)
	
	# Configurar cabeçalhos
	websocket.handshake_headers = PackedStringArray(["User-Agent: Godot"])
	
	# Tentar conectar ao servidor
	var err = websocket.connect_to_url(server_url)
	if err != OK:
		print("Erro ao conectar ao servidor: ", err)
		return false
	
	print("Tentativa de conexão iniciada...")
	connection_in_progress = true
	return true

func _process(_delta):
	if websocket == null:
		return
	
	# Verifica o estado da conexão e atualiza
	websocket.poll()
	
	var state = websocket.get_ready_state()
	
	# Se estamos esperando por uma conexão e ela foi estabelecida
	if connection_in_progress and state == WebSocketPeer.STATE_OPEN:
		print("Conexão WebSocket estabelecida!")
		connection_in_progress = false
		client_connected = true
		emit_signal("connection_established")
	
	# Processar pacotes recebidos
	if state == WebSocketPeer.STATE_OPEN:
		while websocket.get_available_packet_count() > 0:
			var packet = websocket.get_packet()
			var data_str = packet.get_string_from_utf8()
			print("Dados recebidos: ", data_str)
			
			var response = JSON.parse_string(data_str)
			if response != null:
				handle_message(response)
			else:
				print("Erro ao processar JSON recebido")
	
	# Se a conexão foi fechada
	if client_connected and state == WebSocketPeer.STATE_CLOSED:
		var code = websocket.get_close_code()
		var reason = websocket.get_close_reason()
		print("Conexão WebSocket fechada. Código: ", code, " Razão: ", reason)
		client_connected = false
		emit_signal("connection_lost")

func send_message(message_obj):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_str = JSON.stringify(message_obj)
		print("Enviando mensagem: ", json_str)
		var result = websocket.send_text(json_str)
		if result != OK:
			print("Erro ao enviar mensagem: ", result)
			return false
		return true
	else:
		print("Não é possível enviar mensagem: cliente não está conectado")
		return false

func login(username, gender):
	var login_message = {
		"type": "login",
		"payload": {
			"name": username,
			"gender": gender
		}
	}
	return send_message(login_message)

func handle_message(message):
	# Emitir sinal para qualquer mensagem recebida
	print("Processando mensagem: ", message)
	emit_signal("message_received", message)
	
	# Processar mensagens por tipo
	if message.has("type"):
		match message.type:
			"login":
				handle_login_response(message)
			# Outros tipos de mensagem serão implementados conforme necessário
	else:
		print("Mensagem recebida sem tipo definido: ", message)

func handle_login_response(message):
	if message.has("success") and message.success:
		player_id = message.data.id
		player_name = message.data.name
		player_gender = message.data.gender
		print("Login bem-sucedido: ", message.data.message)
		client_connected = true
		emit_signal("login_successful")
	else:
		var error_msg = "Erro desconhecido"
		if message.has("error"):
			error_msg = message.error
		print("Falha no login: ", error_msg)
		emit_signal("login_failed", error_msg)

func disconnect_from_server():
	if websocket != null and websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.close()
		client_connected = false 
