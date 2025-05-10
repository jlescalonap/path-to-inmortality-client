# Main.tscn (con Node como raíz)
extends Node2D
func _ready():
	get_tree().change_scene_to_file.call_deferred("res://splash_screen.tscn")
