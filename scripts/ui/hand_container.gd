class_name HandContainer
extends Control

signal card_selected(card: CardData)

@export var card_scene: PackedScene
@export var max_card_width: float = 112.0
@export var min_card_width: float = 64.0
@export var card_spacing: float = 8.0
@export var bottom_margin: float = 16.0

var _cards: Array[CardWidget] = []


func _ready() -> void:
	resized.connect(_reflow_hand)


func display_hand(hand: Array[CardData], current_mana: int) -> void:
	_clear_cards()
	if card_scene == null:
		push_error("HandContainer: card_scene is not assigned.")
		return
	for card in hand:
		var widget: CardWidget = card_scene.instantiate() as CardWidget
		add_child(widget)
		widget.setup(card, current_mana)
		widget.card_pressed.connect(_on_card_pressed)
		_cards.append(widget)
	_reflow_hand()


func _reflow_hand() -> void:
	if _cards.is_empty():
		return

	var count: int = _cards.size()
	var available: float = size.x - (card_spacing * maxi(count - 1, 0))
	var card_width: float = available / float(count)
	card_width = clampf(card_width, min_card_width, max_card_width)

	var total_width: float = (card_width * count) + (card_spacing * maxi(count - 1, 0))
	var start_x: float = (size.x - total_width) * 0.5
	var card_height: float = card_width * 1.4
	var y: float = size.y - card_height - bottom_margin

	for i in _cards.size():
		var widget: CardWidget = _cards[i]
		widget.custom_minimum_size = Vector2(card_width, card_height)
		widget.size = Vector2(card_width, card_height)
		widget.position = Vector2(start_x + i * (card_width + card_spacing), y)
		widget.max_width = max_card_width


func _on_card_pressed(card: CardData) -> void:
	card_selected.emit(card)


func _clear_cards() -> void:
	for widget in _cards:
		widget.queue_free()
	_cards.clear()
