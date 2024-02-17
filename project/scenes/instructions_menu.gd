extends CanvasLayer


signal resume


func _on_resume_button_pressed():
	resume.emit()
