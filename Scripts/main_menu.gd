extends Control

# --- RIFERIMENTI UI ---
@onready var feedback_label = $VBoxContainer/FeedbackLabel
@onready var email_input = $VBoxContainer2/EmailInput
@onready var password_input = $VBoxContainer2/PasswordInput
@onready var btn_login = $VBoxContainer2/login
@onready var btn_registrati = $VBoxContainer2/Reg
@onready var btn_google = $VBoxContainer2/Google
@onready var btn_inizia = $VBoxContainer2/NuovaPartita
@onready var btn_carica = $VBoxContainer2/CaricaPartita
@onready var btn_quit = $VBoxContainer2/Esc

# Variabile per il plugin nativo Android
var google_sign_in_plugin

# Variabili per gli stili delle caselle di testo
var email_normal_style: StyleBox
var email_focus_style: StyleBox
var password_normal_style: StyleBox
var password_focus_style: StyleBox

func _ready():
	if not has_node("MenuSound"):
		var menu_sound = AudioStreamPlayer.new()
		menu_sound.name = "MenuSound"
		menu_sound.stream = preload("res://Sounds/menu_sound.wav")
		menu_sound.autoplay = true
		menu_sound.volume_db = -25.0
		add_child(menu_sound)
		
	# Salviamo gli stili originali
	email_normal_style = email_input.get_theme_stylebox("normal")
	var e_focus = email_input.get_theme_stylebox("focus")
	email_focus_style = email_normal_style.duplicate()
	if email_focus_style is StyleBoxTexture and e_focus is StyleBoxTexture:
		email_focus_style.texture = e_focus.texture
	
	password_normal_style = password_input.get_theme_stylebox("normal")
	var p_focus = password_input.get_theme_stylebox("focus")
	password_focus_style = password_normal_style.duplicate()
	if password_focus_style is StyleBoxTexture and p_focus is StyleBoxTexture:
		password_focus_style.texture = p_focus.texture
	
	# Colleghiamo i segnali per il cambio testo
	email_input.text_changed.connect(_on_email_text_changed)
	password_input.text_changed.connect(_on_password_text_changed)
		
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

# --- GESTIONE STILI INPUT ---
func _on_email_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		email_input.add_theme_stylebox_override("normal", email_focus_style)
	else:
		email_input.add_theme_stylebox_override("normal", email_normal_style)

func _on_password_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		password_input.add_theme_stylebox_override("normal", password_focus_style)
	else:
		password_input.add_theme_stylebox_override("normal", password_normal_style)

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
	
	# Su Android e iOS a volte quit() non funziona. Forziamo l'uscita:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		OS.kill(OS.get_process_id())
