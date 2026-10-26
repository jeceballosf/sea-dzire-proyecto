extends Area3D

func _on_body_entered(body: Node3D) -> void:
	print("El agua tocó a: ", body.name)
	if body is CharacterBody3D:
		get_tree().call_deferred("reload_current_scene")
