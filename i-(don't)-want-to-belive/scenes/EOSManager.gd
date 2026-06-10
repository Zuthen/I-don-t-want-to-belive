extends Node

const PRODUCT_ID = "9147364a34df4c78a1f766dd68df0185"
const SANDBOX_ID = "019828132a1c4077984c21119672ab95"
const DEPLOYMENT_ID = "bac7202ed4ce4d6385cbe179d6da1d29"
const CLIENT_ID = "xyza7891WQPYKg0xv7MtmwluA5kMonav"
const CLIENT_SECRET = "AwTn2JgETfmFRwnv7v4SuJ04WJPhJ2M2ASS+MsadN04"
const ENCRYPTION_KEY = ""


func _ready():
	# Odpalamy czyste, jednolinkowe logowanie z najnowszego API
	start_epic_loggin()


# --- SYSTEM LOGOWANIA ASYNCHRONICZNEGO ---
func start_epic_loggin():
	print("[EOS] Konfiguruję obiekt HCredentials...")

	# ROZWIĄZANIE BŁĘDU: Tworzymy dedykowany obiekt poświadczeń dla metody setup_eos_async
	var creds = HCredentials.new()
	creds.product_name = "MojaGra"
	creds.product_version = "1.0.0"
	creds.product_id = PRODUCT_ID
	creds.sandbox_id = SANDBOX_ID
	creds.deployment_id = DEPLOYMENT_ID
	creds.client_id = CLIENT_ID
	creds.client_secret = CLIENT_SECRET
	creds.encryption_key = ENCRYPTION_KEY

	print("[EOS] Łączę z darmowymi serwerami Epic Games za pomocą HCredentials...")

	# Przekazujemy tylko JEDEN obiekt jako argument (zamiast 6 tekstów)
	var login_success = await HPlatform.setup_eos_async(creds)

	if login_success:
		print("[EOS] SUKCES! Zalogowano do Epic Connect za pomocą setup_eos_async!")
		print("[EOS] Twoje cyfrowe ID to: ", HAuth.product_user_id)
	else:
		print("[EOS] BŁĄD: Logowanie nie powiodło się. Sprawdź swoje klucze w kodzie.")


# --- HOST: KLIKNIĘCIE "STWÓRZ LOBBY" ---
func _on_button_host_pressed():
	print("[LOBBY] Wysyłam żądanie o utworzenie pokoju P2P...")

	# Konfiguracja lobby jako słownik – to najnowsze API akceptuje bez problemu
	var lobby_dict = {
		"max_members": 4,
		"bucket_id": "MojaGra_v1",
		"presence_enabled": true,
	}

	var created_lobby_id = await HLobbies.create_lobby(lobby_dict)

	if created_lobby_id != "":
		print("[LOBBY] JEST! Pokój utworzony na serwerach Epic.")
		print("[LOBBY] KOD DO SKOPIOWANIA: ", created_lobby_id)
		$LineEdit.text = created_lobby_id
	else:
		print("[LOBBY] BŁĄD: Nie udało się utworzyć pokoju.")


# --- CLIENT: KLIKNIĘCIE "DOŁĄCZ DO LOBBY" ---
func _on_button_join_pressed():
	var target_lobby_id = $LineEdit.text.strip_edges()
	if target_lobby_id == "":
		print("[LOBBY] Błąd: Wklej najpierw kod lobby do pola LineEdit!")
		return

	print("[LOBBY] Łączę z hostem pokoju za pomocą kodu...")
	var join_success = await HLobbies.join_lobby(target_lobby_id)

	if join_success:
		print("[LOBBY] SUKCES! Połączenie P2P nawiązane. Grasz z hostem!")
	else:
		print("[LOBBY] BŁĄD: Nie udało się dołączyć do pokoju.")
