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
	Auth.login_succeeded.connect(_on_manual_login_success) # Login email standard
	
	# Login Google
	Auth.google_login_succeeded.connect(_on_google_login_success)
	
	# Cerchiamo il plugin di Android
	if Engine.has_singleton("GodotGoogleSignIn"):
		google_sign_in_plugin = Engine.get_singleton("GodotGoogleSignIn")
		google_sign_in_plugin.user_authenticated.connect(_on_google_token_received)
	else:
		print("Plugin Google non caricato. Normale se sei su PC.")

# --- LOGIN EMAIL STANDARD ---
func _on_btnlogin_pressed():
	var email = email_input.text
	var password = password_input.text
	if email == "" or password == "":
		feedback_label.text = "Inserisci email e password!"
		return
	Auth.login_user(email, password)

func _on_manual_login_success(local_id, id_token):
	Global.current_username = email_input.text
	_mostra_menu_gioco("Login effettuato!")

# --- REGISTRAZIONE ---
func _on_btn_registrati_pressed():
	var email = email_input.text
	var password = password_input.text
	Auth.register_user(email, password)

func _on_register_success(_local_id) -> void:
	feedback_label.text = "Account creato! Ora premi Login."
	password_input.text = ""

func _on_auth_failed(error_message) -> void:
	feedback_label.text = error_message

# --- GOOGLE SIGN-IN ---

func _on_btn_google_pressed():
	feedback_label.text = "Controllo plugin..."
	
	# TEST SPIA: Verifichiamo forzatamente se Godot ha impacchettato il plugin nell'APK
	if Engine.has_singleton("GodotGoogleSignIn"):
		feedback_label.text = "Plugin TROVATO! Chiamo Google..."
		# Se lo trova, tenta di lanciare la finestra di login
		var plugin = Engine.get_singleton("GodotGoogleSignIn")
		plugin.signIn(Global.google_web_client_id)
	else:
		feedback_label.text = "ERRORE CRITICO: Plugin ASSENTE nell'APK!"

func _on_google_token_received(google_id_token: String):
	feedback_label.text = "Verifica Google in corso..."
	Auth.login_with_google(google_id_token)

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
	var success = SaveManager.load_game()
	if not success:
		feedback_label.text = "Nessun dato nel Cloud!"

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
