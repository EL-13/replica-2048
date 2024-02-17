extends CanvasLayer


signal restart
signal instructions
signal credits


func _on_restart_button_pressed():
	restart.emit()

func _on_instructions_button_pressed():
	instructions.emit()

func _on_credits_button_pressed():
	credits.emit()
