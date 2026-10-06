class_name UIBearStressIndicator
extends CanvasLayer

@export var cave: Caverna
@export var stress_label: Label
@export var stress_bar: ProgressBar

func _ready() -> void:
	stress_bar.max_value = Caverna.LIMITE_DE_BARULHO
	cave = cave if cave != null else get_tree().get_first_node_in_group("persistencia_da_caverna") as Caverna
	set_process(cave != null)

func _process(_delta: float) -> void:
	var stress: float = cave.percentual_de_barulho_atual
	stress_label.text = "Bear Noise Stress Level: %d / 100" % roundi(stress)
	stress_bar.value = stress
	stress_bar.modulate = Color.GREEN.lerp(Color.RED, stress / Caverna.LIMITE_DE_BARULHO)
