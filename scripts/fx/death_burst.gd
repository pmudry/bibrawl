extends CPUParticles2D

## Éclat de particules joué une fois puis libéré.


func _ready() -> void:
	emitting = true
	finished.connect(queue_free)
