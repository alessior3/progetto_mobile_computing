extends Control

# --- RIFERIMENTI UI ---
@onready var feedback_label = $VBoxContainer/FeedbackLabel
@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var btn_login = $VBoxContainer/btnlogin
@onready var btn_registrati = $VBoxContainer/btnRegistrati
@onready var btn_google = $VBoxContainer/btnGoogle
@onready var btn_inizia = $VBoxContainer/btnInizia
@onready var btn_carica = $VBoxContainer/btnCarica
@onready var btn_quit = $VBoxContainer/btnQuit

# Variabile per il plugin nativo Android
var google_sign_in_plugin

func _ready():
	# Colleghiamo i segnali di Auth (Autoload)
	Auth.register_succeeded.connect(_on_register_success)
	Auth.register_failed.connect(_on_auth_failed)
	Auth.login_failed.connect(_on_auth_failed)
	Auth.login_succeeded.connect(_on_manual_login_success)
	Auth.google_login_succeeded.connect(_on_google_login_success)
	
	# ASCOLTIAMO IL SAVEMANAGER PER NON CRASHARE!
	SaveManager.load_response.connect(_on_save_manager_response)
	
	# Cerchiamo il plugin di Android
	if Engine.has_singleton("GodotGoogleSignIn"):
		google_sign_in_plugin = Engine.get_singleton("GodotGoogleSignIn")
		google_sign_in_plugin.initialize(Global.google_web_client_id)
		
		# Segnali esatti per Google
		google_sign_in_plugin.sign_in_success.connect(_on_sign_in_success)
		google_sign_in_plugin.sign_in_failed.connect(_on_sign_in_failed)
	else:
		print("Plugin Google non caricato. Normale se sei su PC.")
		
	if Auth.api_key == "":
		feedback_label.text = "ERRORE: secret.cfg NON TROVATO NELL'APK!"
	else:
		feedback_label.text = "Chiave OK (" + str(Auth.api_key.length()) + " car.)"

# --- LOGIN EMAIL STANDARD ---
func _on_btnlogin_pressed():
	var email = email_input.text.strip_edges()
	var password = password_input.text
	if email == "" or password == "":
		feedback_label.text = "Inserisci email e password!"
		return
	Auth.login_user(email, password)

func _on_manual_login_success(local_id, id_token):
	Global.current_username = email_input.text.strip_edges()
	_mostra_menu_gioco("Login effettuato!")

# --- REGISTRAZIONE ---
func _on_btn_registrati_pressed():
	var email = email_input.text.strip_edges()
	var password = password_input.text
	Auth.register_user(email, password)

func _on_register_success(_local_id) -> void:
	feedback_label.text = "Account creato! Ora premi Login."
	password_input.text = ""

func _on_auth_failed(error_message) -> void:
	feedback_label.text = str(error_message)

# --- GOOGLE SIGN-IN ---
func _on_btn_google_pressed():
	feedback_label.text = "Controllo plugin..."
	if Engine.has_singleton("GodotGoogleSignIn"):
		feedback_label.text = "Plugin TROVATO! Chiamo Google..."
		var plugin = Engine.get_singleton("GodotGoogleSignIn")
		plugin.signIn()
	else:
		feedback_label.text = "ERRORE CRITICO: Plugin ASSENTE nell'APK!"

func _on_sign_in_success(id_token: String, email: String, display_name: String):
	feedback_label.text = "Google OK! Ciao " + display_name + ". Invio a Firebase..."
	Auth.login_with_google(id_token)

func _on_sign_in_failed(errore = "", extra1 = "", extra2 = ""):
	feedback_label.text = "ERRORE RIFIUTO GOOGLE: " + str(errore)

func _on_google_login_success(google_email: String) -> void:
	Global.current_username = google_email
	_mostra_menu_gioco("Google Login OK!")

# --- FUNZIONE DI SERVIZIO PER PULIRE L'INTERFACCIA ---
func _mostra_menu_gioco(messaggio: String):
	feedback_label.text = messaggio
	email_input.visible = false
	password_input.visible = false
	btn_login.visible = false
	btn_registrati.visible = false
	btn_google.visible = false
	
	btn_inizia.visible = true
	btn_carica.visible = true

# --- BOTTONI DI GIOCO ---
func _on_btn_inizia_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_btn_carica_pressed() -> void:
	feedback_label.text = "Controllo salvataggi nel Cloud..."
	SaveManager.load_game()

# Riceve la risposta dal SaveManager e aggiorna l'interfaccia
func _on_save_manager_response(success: bool, message: String):
	feedback_label.text = message

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
