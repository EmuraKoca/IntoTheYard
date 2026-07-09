extends "res://base_enemy.gd"

# Boss'a özgü ortak değişkenler
var phase: int = 1
var max_phase: int = 2
var phase_threshold: float = 0.5  # HP %50'ye düşünce phase 2

func _ready() -> void:
	super._ready()

func _enemy_process(delta: float) -> void:
	_check_phase()
	_boss_process(delta)

func _check_phase() -> void:
	if phase < max_phase and float(health) / float(max_health) <= phase_threshold:
		phase += 1
		_on_phase_change(phase)

func _on_phase_change(_new_phase: int) -> void:
	pass  # child override: phase geçişinde özel efekt/davranış

func _boss_process(_delta: float) -> void:
	pass  # child override: boss'a özgü AI
