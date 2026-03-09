extends Control

# --- RIFERIMENTI AI NODI DELLA SCENA ---
# Assicurati che questi nomi siano identici a quelli nell'albero a sinistra!
@onready var email_input = $VBoxContainer/EmailInput 
@onready var password_input = $VBoxContainer/PasswordInput
@onready var feedback_label = $VBoxContainer/FeedbackLabel 

@onready var btn_inizia = $VBoxContainer/btnInizia
@onready var btn_carica = $VBoxContainer/btnCarica
@onready var btn_login = $VBoxContainer/btnlogin
@onready var btn_registrati = $VBoxContainer/btnRegistrati

# Il nodo auth che abbiamo creato nella scena
@onready var auth = $auth 

func _ready() -> void:
	# All'inizio nascondiamo i bottoni di gioco e puliamo la scritta
	btn_inizia.visible = false
	btn_carica.visible = false
	feedback_label.text = "Benvenuto! Accedi o Registrati."
	
	# --- COLLEGHIAMO I SEGNALI DEL NODO AUTH ---
	auth.login_succeeded.connect(_on_login_success)
	auth.login_failed.connect(_on_auth_failed)
	auth.register_succeeded.connect(_on_register_success)
	auth.register_failed.connect(_on_auth_failed)

# --- FUNZIONI DEI BOTTONI ---

func _on_btn_login_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	
	if email == "" or password == "":
		feedback_label.text = "Inserisci Email e Password!"
		return
		
	feedback_label.text = "Accesso in corso..."
	auth.login_user(email, password)

func _on_btn_registrati_pressed() -> void:
	var email = email_input.text
	var password = password_input.text
	
	if email == "" or password == "":
		feedback_label.text = "Inserisci Email e Password!"
		return
		
	feedback_label.text = "Creazione account in corso..."
	auth.register_user(email, password)

# --- RISPOSTE DA FIREBASE ---

func _on_login_success(_local_id, _id_token) -> void:
	feedback_label.text = "Login effettuato con successo!"
	
	# Nascondiamo i campi di testo e i bottoni di login
	email_input.visible = false
	password_input.visible = false
	btn_login.visible = false
	btn_registrati.visible = false
	
	# Facciamo apparire i bottoni per giocare!
	btn_inizia.visible = true
	btn_carica.visible = true
	
	# Salviamo l'email nel Global per usarla nel salvataggio Cloud
	Global.current_username = email_input.text

func _on_register_success(_local_id) -> void:
	feedback_label.text = "Account creato! Ora premi Login."
	password_input.text = ""

func _on_auth_failed(error_message) -> void:
	feedback_label.text = error_message

# --- BOTTONI DI GIOCO ---

func _on_btn_inizia_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_btn_carica_pressed() -> void:
	print("=== BOTTONE CARICA CLICCATO! ===")
	var success = SaveManager.load_game()
	if not success:
		feedback_label.text = "Nessun salvataggio trovato!"

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
