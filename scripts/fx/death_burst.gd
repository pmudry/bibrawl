extends CPUParticles2D

## Éclat de particules joué une fois puis libéré.


func _ready() -> void:
	# Même raison que les projectiles : l'éclat ne doit pas disparaître sous l'herbe.
	z_index = GrassLayer.Z_INDEX + 1
	emitting = true
	finished.connect(queue_free)
