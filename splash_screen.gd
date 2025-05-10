extends Control

func _ready():
	# Simula carga de recursos o conexión
	$Label.text = "Cargando..."
	
	# Espera 2 segundos antes de pasar a LoginScreen
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://LoginScreen.tscn")
