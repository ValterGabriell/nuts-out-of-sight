class_name GerenciadorDeCutscene
extends Node3D

@export var cutscene_animation_player: AnimationPlayer
@export var jogador_movimento: JogadorMovimento

func _ready() -> void:
	if cutscene_animation_player != null:
		cutscene_animation_player.animation_started.connect(_on_cutscene_started)
		cutscene_animation_player.animation_finished.connect(_on_cutscene_finished)

func _on_cutscene_started(anim_name: StringName) -> void:
	if jogador_movimento != null:
		jogador_movimento.em_cutscene = true

func _on_cutscene_finished(anim_name: StringName) -> void:
	if jogador_movimento != null:
		jogador_movimento.em_cutscene = false