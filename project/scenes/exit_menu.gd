extends CanvasLayer


signal cancel
signal exit


func _on_cancel_button_pressed():
	cancel.emit()

func _on_exit_button_pressed():
	exit.emit()
