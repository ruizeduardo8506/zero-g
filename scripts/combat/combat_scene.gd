extends Control

const PARTY_SLOTS: Array[Vector2] = [
	Vector2(220, 420),
	Vector2(140, 320),
	Vector2(140, 500),
	Vector2(80, 410),
]
const ENEMY_SLOT_TWO := Vector2(980, 440)

@onready var _controller: CombatController = %CombatController
@onready var _hud: CombatHud = %CombatHud
@onready var _player_entity: Node2D = %Player
@onready var _enemy_entity: Node2D = %Enemy


func _ready() -> void:
	_spawn_party()
	_spawn_extra_enemy()
	_wire_signals()
	if _player_entity != null:
		CombatStateMachine.set_active_player_entity(_player_entity)
	_controller.start_combat(StarterDeck.create_party_deck(PartyManager.recruited))
	call_deferred("_focus_default_target")


func _focus_default_target() -> void:
	if _player_entity != null:
		EventBus.target_hovered.emit(_player_entity)


func _wire_signals() -> void:
	CombatStateMachine.phase_changed.connect(_on_phase_changed)
	EventBus.hand_updated.connect(_on_hand_updated)
	EventBus.mana_updated.connect(_on_mana_updated)
	EventBus.piles_updated.connect(_on_piles_updated)
	_hud.end_turn_pressed.connect(_controller.end_player_turn)
	_hud.physical_attack_pressed.connect(_controller.try_physical_attack)
	_hud.burn_revive_pressed.connect(_controller.try_burn_revive)
	var hand: HandContainer = _hud.get_hand_container()
	if hand != null:
		hand.card_selected.connect(_on_card_selected)


func _spawn_party() -> void:
	var ids: Array[String] = PartyManager.recruited
	if ids.is_empty():
		ids = [PartyManager.ORPHAN]
	_configure_battler(_player_entity, ids[0], PARTY_SLOTS[0])
	for i in range(1, ids.size()):
		if i >= PARTY_SLOTS.size():
			break
		var extra := CombatEntity.new()
		extra.name = ids[i]
		extra.entity_id = ids[i]
		extra.display_name = PartyManager.display_name(ids[i])
		extra.body_color = PartyManager.body_color(ids[i])
		extra.max_hp = 90
		extra.max_mana = 0
		extra.position = PARTY_SLOTS[i]
		extra.add_to_group("player")
		%Battlers.add_child(extra)


func _spawn_extra_enemy() -> void:
	if GameManager.encounter_kind != "rift":
		return
	var extra := EnemyAI.new()
	extra.name = "Enemy2"
	extra.entity_id = "enemy_2"
	extra.display_name = "Rift Elite"
	extra.max_hp = 60
	extra.max_mana = 0
	extra.attack_damage = 6
	extra.telegraph_text = "Rift elite coils to strike."
	extra.body_color = Color(0.7, 0.25, 0.55, 1.0)
	extra.position = ENEMY_SLOT_TWO
	extra.add_to_group("enemies")
	%Battlers.add_child(extra)


func _configure_battler(node: Node2D, member_id: String, slot: Vector2) -> void:
	node.position = slot
	if node is CombatEntity:
		var entity: CombatEntity = node as CombatEntity
		entity.entity_id = member_id
		entity.display_name = PartyManager.display_name(member_id)
		entity.body_color = PartyManager.body_color(member_id)
		var body: ColorRect = entity.get_node_or_null("Body") as ColorRect
		if body != null:
			body.color = entity.body_color


func _on_phase_changed(_previous: int, _current: int) -> void:
	var live_phase: int = CombatStateMachine.current_phase
	var phase_name: String = CombatStateMachine.Phase.keys()[live_phase]
	_hud.update_turn(CombatStateMachine.turn_number, phase_name)
	_hud.update_plays(_controller.player.cards_played_this_turn)
	var can_act: bool = (
		live_phase == CombatStateMachine.Phase.PLAYER_MAIN
		and not CombatStateMachine.is_combat_over()
	)
	var can_end_turn: bool = (
		not CombatStateMachine.is_combat_over()
		and (
			live_phase == CombatStateMachine.Phase.PLAYER_MAIN
			or live_phase == CombatStateMachine.Phase.WAITING_FOR_TARGET
		)
	)
	_hud.set_interaction_enabled(can_act)
	_hud.set_end_turn_enabled(can_end_turn)


func _on_hand_updated(hand: Array[CardData]) -> void:
	var hand_container: HandContainer = _hud.get_hand_container()
	if hand_container == null:
		return
	var mana: int = _controller.player.mana.current
	var entity: Node = _player_entity
	if entity != null and "current_mana" in entity:
		mana = int(entity.get("current_mana"))
	hand_container.display_hand(hand, mana)
	_hud.update_plays(_controller.player.cards_played_this_turn)


func _on_mana_updated(current: int, cap: int) -> void:
	_hud.update_mana(current, cap)
	_on_hand_updated(DeckManager.get_hand_cards())


func _on_piles_updated(draw_count: int, burn_count: int) -> void:
	_hud.update_piles(draw_count, burn_count)


func _on_card_selected(card: CardData) -> void:
	_controller.try_play_card(card)
