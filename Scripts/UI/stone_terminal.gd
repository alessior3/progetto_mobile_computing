extends CanvasLayer

signal terminal_closed
signal sudo_triggered
signal sudo_open_triggered

@onready var output_label = $Control/StoneBackground/MarginContainer/VBoxContainer/OutputLabel
@onready var input_field = $Control/StoneBackground/MarginContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var prompt_label = $Control/StoneBackground/MarginContainer/VBoxContainer/HBoxContainer/PromptLabel

var target_number: int = 0
var history: Array = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_field.text_submitted.connect(_on_text_submitted)
	input_field.grab_focus()
	
	_add_to_output("--- ANCIENT TERMINAL v1.0.4-LNX ---")
	_add_to_output("Digitare 'help' per la lista dei comandi.")
	_add_to_output(" ")

func setup(number: int):
	target_number = number

func _on_text_submitted(new_text: String):
	var command = new_text.strip_edges().to_lower()
	input_field.clear()
	
	_add_to_output("root@ancient_altar:~# " + new_text)
	_parse_command(command)
	
	# Scroll automatico (se necessario)
	# output_label.scroll_to_line(output_label.get_line_count())

func _parse_command(cmd_full: String):
	var parts = cmd_full.split(" ")
	var cmd = parts[0]
	
	match cmd:
		"":
			return
		"ls":
			_add_to_output("vault_logic.c  kernel.bin  readme.txt  lost_souls.log")
		"cat":
			if parts.size() < 2:
				_add_to_output("Utilizzo: cat [file]")
			elif parts[1] == "readme.txt":
				_add_to_output("==================================================")
				_add_to_output("AVVERTENZA: I socket dell'altare richiedono un materiale")
				_add_to_output("altamente conduttivo per attivarsi correttamente.")
				_add_to_output("Solo un metallo obile (come l'Oro) garantira' il flusso energetico.")
				_add_to_output("==================================================")
			elif parts[1] == "vault_logic.c":
				_add_to_output("// Require perfect conductivity (Au) to avoid segfaults")
				_add_to_output("#include <stdio.h>")
				_add_to_output("int main() {")
				_add_to_output("    int target = " + str(target_number) + ";")
				_add_to_output("    if (get_sum() == target) unlock_vault();")
				_add_to_output("    return 0;")
				_add_to_output("}")
			elif parts[1] == "lost_souls.log":
				_add_to_output("[LOG] 12/04/1204: Avventuriero 'Gimli' disperso.")
				_add_to_output("[LOG] 05/09/1208: Errore di segmentazione nell'anima.")
				_add_to_output("[LOG] 22/01/1210: Tentativo di login fallito dall'utente 'Phantom'.")
			elif parts[1] == "kernel.bin":
				_add_to_output("ERRORE: Impossibile leggere file binario. Dati corrotti o criptati.")
				_add_to_output("Suggerimento: prova a usare 'hexdump' (non ancora installato).")
			else:
				_add_to_output("cat: " + parts[1] + ": Nessun file o directory.")
		"help":
			_add_to_output("Comandi disponibili: ls, cat, help, clear, sudo, exit")
		"clear":
			output_label.text = ""
		"exit":
			_close()
		"sudo":
			if parts.size() > 1 and parts[1] == "open":
				var player = get_tree().get_first_node_in_group("player")
				if player and "god_mode" in player and player.god_mode:
					_add_to_output("GOD MODE RILEVATA.")
					_add_to_output("Bypass del Kernel in corso...")
					_add_to_output("ACCESSO CONCESSO. Apertura forzata del caveau.")
					sudo_open_triggered.emit()
					
					input_field.editable = false
					await get_tree().create_timer(1.5).timeout
					_close()
					return
			
			_add_to_output("Tentativo di bypass del Kernel...")
			_add_to_output("ERRORE: L'utente 'player' non e' nel file sudoers. Accesso al caveau negato.")
			_add_to_output("ALLARME SISTEMA: SISTEMA DI DIFESA ATTIVATO.")
			sudo_triggered.emit()
			
			input_field.editable = false
			await get_tree().create_timer(1.5).timeout
			_close()
		"printf":
			_add_to_output(str(target_number))
		"whoami":
			_add_to_output("Un'anima persa tra i bit.")
		_:
			_add_to_output("-bash: " + cmd + ": comando non trovato")

func _add_to_output(text: String):
	output_label.text += text + "\n"

func _close():
	terminal_closed.emit()
	queue_free()

func _on_close_button_pressed():
	_close()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_close()
