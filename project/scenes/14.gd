extends Sprite2D


# called when the node enters the scene tree for the first time.
func _ready():
	var scale_main = get_parent().scale_final
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, 'modulate:a', 1, 0.5).from(0.5)
	tween.tween_property(self, 'scale', Vector2(1.0, 1.0) * scale_main, 0.5).from(Vector2(0.8, 0.8) * scale_main)
