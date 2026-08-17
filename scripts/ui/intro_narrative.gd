extends Control

## Short intro slides. Does not mention the five-seal twist.

const SLIDES: Array[String] = [
	"You are the Orphan — a scavenger with no innate magic, surviving on trash and common gear picked from old battlefields.",
	"The world is splitting between the primal Old Gods, who hate technology, and the New Gods, architects of civilization who demand obedience.",
	"An abandoned Heretic's Shack sits on the city outskirts. From there you will fight, recruit allies, and scrape together a future.",
]

var _index: int = 0


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.CUTSCENE)
	%NextButton.pressed.connect(_on_next)
	_show_slide()


func _on_next() -> void:
	_index += 1
	if _index >= SLIDES.size():
		GameManager.finish_intro()
		return
	_show_slide()


func _show_slide() -> void:
	%SlideLabel.text = SLIDES[_index]
	%NextButton.text = "BEGIN" if _index == SLIDES.size() - 1 else "NEXT"
