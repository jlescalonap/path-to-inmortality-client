extends Node2D

func _ready():
	# Verificar se o jogador está autenticado
	if Global.player_id == "":
		# Se não estiver autenticado, voltar para a tela de login
		get_tree().change_scene_to_file("res://LoginScreen.tscn")
		return
	
	# Verificar se a conexão com o servidor ainda está ativa
	if not Global.client_connected:
		$UI/StatusLabel.text = "La conexión con el servidor se ha perdido. Reconectando..."
		
		# Tentar reconectar ao servidor
		if Global.connect_to_server():
			# Conectar ao sinal de conexão estabelecida para continuar após reconexão
			Global.connect("connection_established", _on_reconnection_established)
		else:
			$UI/StatusLabel.text = "No se pudo reconectar al servidor."
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file("res://LoginScreen.tscn")
			return
	
	# Configurar informações do jogador na interface
	$UI/StatusPanel/PlayerInfo.text = "Conectado como: %s\nID: %s" % [Global.player_name, Global.player_id]
	$UI/StatusLabel.text = "Mundo de jogo carregado com sucesso"
	
	# Conectar sinais do Global para atualização da interface
	Global.connect("connection_lost", _on_connection_lost)
	Global.connect("message_received", _on_message_received)

func _on_reconnection_established():
	$UI/StatusLabel.text = "Reconexión exitosa. Continuando juego..."
	
	# Desconectar o sinal após uso único
	if Global.is_connected("connection_established", _on_reconnection_established):
		Global.disconnect("connection_established", _on_reconnection_established)
	
	# Reconectar os handlers normais
	if not Global.is_connected("connection_lost", _on_connection_lost):
		Global.connect("connection_lost", _on_connection_lost)
	
	if not Global.is_connected("message_received", _on_message_received):
		Global.connect("message_received", _on_message_received)

func _on_connection_lost():
	$UI/StatusLabel.text = "¡Conexión perdida con el servidor!"
	# Aguardar um momento e voltar para a tela de login
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://LoginScreen.tscn")

func _on_message_received(data):
	# Mostrar mensagens recebidas do servidor
	if data.has("type"):
		$UI/StatusLabel.text = "Mensaje recibido: %s" % data.type
		
	# Processar diferentes tipos de mensagens
	# Este é apenas um exemplo básico, deve ser expandido conforme necessário
	match data.type:
		"player_update":
			update_player_info(data)
		"world_update":
			update_world_state(data)

func update_player_info(data):
	# Atualizar informações do jogador com base nos dados recebidos
	if data.success and data.has("data"):
		# Implementar lógica específica aqui
		pass

func update_world_state(data):
	# Atualizar o estado do mundo com base nos dados recebidos
	if data.success and data.has("data"):
		# Implementar lógica específica aqui
		pass

func _exit_tree():
	# Desconectar sinais para evitar vazamentos de memória
	if Global.is_connected("connection_lost", _on_connection_lost):
		Global.disconnect("connection_lost", _on_connection_lost)
	
	if Global.is_connected("message_received", _on_message_received):
		Global.disconnect("message_received", _on_message_received)
		
	if Global.is_connected("connection_established", _on_reconnection_established):
		Global.disconnect("connection_established", _on_reconnection_established) 