# Guia de Conexão - Cliente Godot 4.4.1

## Introdução

Este documento apresenta as instruções para conectar um cliente desenvolvido em Godot 4.4.1 ao servidor do jogo "Path to Immortality". A comunicação acontece através de WebSocket, permitindo interações em tempo real entre o cliente e o servidor.

## Requisitos

- Godot Engine 4.4.1
- Conhecimento básico de GDScript e WebSocket

## Configuração do WebSocket no Godot

### 1. Criar um Cliente WebSocket

Primeiro, você precisa criar um objeto `WebSocketClient` no Godot:

```gdscript
extends Node

var websocket_client = WebSocketClient.new()
var server_url = "ws://localhost:8080/ws"
var client_connected = false

func _ready():
    # Conectar sinais
    websocket_client.connect("connection_established", _on_connection_established)
    websocket_client.connect("connection_error", _on_connection_error)
    websocket_client.connect("connection_closed", _on_connection_closed)
    websocket_client.connect("data_received", _on_data_received)

    # Iniciar conexão com o servidor
    var error = websocket_client.connect_to_url(server_url)
    if error != OK:
        print("Erro ao conectar ao servidor: ", error)
        return

func _process(delta):
    # Necessário para processar mensagens e manter a conexão ativa
    if client_connected:
        websocket_client.poll()

# Callbacks para os sinais WebSocket
func _on_connection_established(protocol):
    print("Conexão estabelecida com o servidor!")
    client_connected = true

func _on_connection_error():
    print("Erro de conexão!")
    client_connected = false

func _on_connection_closed(was_clean = false):
    print("Conexão fechada. Clean: ", was_clean)
    client_connected = false

func _on_data_received():
    var data = websocket_client.get_peer(1).get_packet().get_string_from_utf8()
    print("Dados recebidos: ", data)

    # Processar a mensagem recebida
    var json = JSON.new()
    var error = json.parse(data)
    if error == OK:
        var message = json.data
        handle_message(message)
    else:
        print("Erro ao processar JSON: ", error)

# Função para enviar mensagens para o servidor
func send_message(message_obj):
    if client_connected:
        var json = JSON.new()
        var text = json.stringify(message_obj)
        websocket_client.get_peer(1).put_packet(text.to_utf8_buffer())
    else:
        print("Não é possível enviar mensagem: cliente não está conectado")

# Processar mensagens recebidas
func handle_message(message):
    match message.type:
        "login":
            handle_login_response(message)
        "move":
            handle_move_response(message)
        "attack":
            handle_attack_response(message)
        "error":
            handle_error(message)
```

### 2. Login no Servidor

Para fazer login no servidor e começar a jogar:

```gdscript
func login(player_name, gender):
    var login_message = {
        "type": "login",
        "payload": {
            "name": player_name,
            "gender": gender  # Deve ser "male" ou "female"
        }
    }
    send_message(login_message)

func handle_login_response(message):
    if message.success:
        Global.player_id = message.data.id
        Global.player_name = message.data.name
        print("Login bem-sucedido: ", message.data.message)
        # Transição para a cena principal do jogo
        get_tree().change_scene_to_file("res://scenes/game_world.tscn")
    else:
        print("Falha no login: ", message.error)
```

### 3. Movimentação do Jogador

Para enviar atualizações de movimento ao servidor:

```gdscript
func move_player(x, y):
    var move_message = {
        "type": "move",
        "payload": {
            "x": x,
            "y": y
        }
    }
    send_message(move_message)

func handle_move_response(message):
    if message.success:
        # Atualizar posição confirmada pelo servidor
        print("Movimento confirmado para posição: ", message.data.x, ", ", message.data.y)
    else:
        print("Falha ao mover: ", message.error)
```

### 4. Sistema de Combate

Para atacar outro jogador ou NPC:

```gdscript
func attack_target(target_id):
    var attack_message = {
        "type": "attack",
        "payload": {
            "target_id": target_id
        }
    }
    send_message(attack_message)

func handle_attack_response(message):
    if message.success:
        print("Ataque bem-sucedido! Dano causado: ", message.data.damage)
    else:
        print("Falha ao atacar: ", message.error)
```

### 5. Tratamento de Erros

Função para lidar com mensagens de erro do servidor:

```gdscript
func handle_error(message):
    print("Erro do servidor: ", message.error)
    # Exibir mensagem de erro ao usuário
    # Por exemplo: mostrar um popup
```

## Protocolos de Comunicação

### Formato das Mensagens

Todas as mensagens trocadas entre o cliente e o servidor seguem o formato JSON:

```json
{
  "type": "tipo_da_mensagem",
  "payload": {
    // Dados específicos do tipo de mensagem
  }
}
```

As respostas do servidor seguem o formato:

```json
{
    "type": "tipo_da_mensagem",
    "success": true/false,
    "data": {
        // Dados da resposta (quando success=true)
    },
    "error": "mensagem_de_erro" // (quando success=false)
}
```

### Tipos de Mensagens

#### 1. Login

**Cliente → Servidor:**

```json
{
    "type": "login",
    "payload": {
        "name": "NomeDoJogador",
        "gender": "male" ou "female"
    }
}
```

**Servidor → Cliente (sucesso):**

```json
{
    "type": "login",
    "success": true,
    "data": {
        "id": "ID_do_jogador",
        "name": "NomeDoJogador",
        "gender": "male" ou "female",
        "message": "Bem-vindo ao Path to Immortality, NomeDoJogador!"
    }
}
```

#### 2. Movimento

**Cliente → Servidor:**

```json
{
  "type": "move",
  "payload": {
    "x": 123.45,
    "y": 67.89
  }
}
```

**Servidor → Cliente (sucesso):**

```json
{
  "type": "move",
  "success": true,
  "data": {
    "x": 123.45,
    "y": 67.89
  }
}
```

#### 3. Ataque

**Cliente → Servidor:**

```json
{
  "type": "attack",
  "payload": {
    "target_id": "ID_do_alvo"
  }
}
```

**Servidor → Cliente (sucesso):**

```json
{
  "type": "attack",
  "success": true,
  "data": {
    "target_id": "ID_do_alvo",
    "damage": 10
  }
}
```

## Considerações de Segurança

1. **Validação de Entrada**: Sempre valide as entradas do usuário antes de enviar ao servidor.
2. **Tratamento de Erros**: Implemente tratamento de erros robusto para lidar com falhas de conexão ou respostas de erro do servidor.
3. **Reconexão Automática**: Implemente um sistema de reconexão automática para lidar com quedas temporárias de conexão.

## Exemplo de Implementação Completa

Para um exemplo completo de implementação, consulte o diretório `client/godot/` no repositório do projeto.

## Configuração do Ambiente de Desenvolvimento

### Servidor Local

Para desenvolvimento local, o servidor está configurado para rodar em:

- URL: `ws://localhost:8080/ws`

### Servidor de Produção

Para o ambiente de produção, use:

- URL: `wss://path-to-immortality.example.com/ws` (substitua pelo URL real do servidor)

## Suporte e Solução de Problemas

Se encontrar problemas ao conectar-se ao servidor, verifique:

1. O servidor está em execução e acessível.
2. A URL do WebSocket está correta.
3. Não há firewalls bloqueando a conexão.
4. Os dados enviados estão no formato JSON correto.

Para mais informações, consulte a documentação da API ou entre em contato com a equipe de desenvolvimento.
