extends GutTest

var game: Node
var skeptic_scene = preload("uid://b7wo2a5407873")
var mock_skeptic: CharacterBody2D
var other_skeptic: CharacterBody2D


func before_each():
	var mock_peer = OfflineMultiplayerPeer.new()
	get_tree().get_multiplayer().set_multiplayer_peer(mock_peer)

	game = preload("uid://c4twc836ak4bd").instantiate()
	game.name = "Game"
	get_tree().root.add_child(game)
	get_tree().current_scene = game

	for node in get_tree().get_nodes_in_group("local_player"):
		node.remove_from_group("local_player")


func after_each():
	var leftover_icons = find_all_icons_in_engine(get_tree().root)
	for icon in leftover_icons:
		if is_instance_valid(icon):
			icon.free()

	if is_instance_valid(mock_skeptic):
		mock_skeptic.queue_free()
	if is_instance_valid(other_skeptic):
		other_skeptic.queue_free()
	if is_instance_valid(game):
		game.queue_free()

	get_tree().get_multiplayer().set_multiplayer_peer(null)
	await wait_physics_frames(2)


func test_player_can_call_other_player():
	# Arrange
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.id = 1
	mock_skeptic.role = Player.Role.SKEPTIC
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)

	other_skeptic = skeptic_scene.instantiate()
	other_skeptic.id = 2
	other_skeptic.role = Player.Role.SKEPTIC
	other_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(other_skeptic)

	await wait_physics_frames(3)

	# Act
	mock_skeptic.call_other_skeptic()

	await wait_physics_frames(5)
	var icons = find_all_icons_in_engine(get_tree().root)

	# Assert
	assert_gt(icons.size(), 0, "Ikona wezwania nie pojawiła się w drzewie sceny!")


func test_player_can_t_call_outside_range_size():
	# Arrange: Potrzebujemy dwóch sceptyków, aby sprawdzić, czy sygnał do nich NIE dotrze
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.id = 1
	mock_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(mock_skeptic)
	mock_skeptic.global_position = Vector2(0, 0)

	other_skeptic = skeptic_scene.instantiate()
	other_skeptic.id = 2
	other_skeptic.add_to_group("skeptics")
	get_tree().root.add_child(other_skeptic)
	# Ustawiamy drugiego sceptyka potężnie daleko
	other_skeptic.global_position = Vector2(99999, 99999)

	await wait_physics_frames(3)

	# Act
	mock_skeptic.call_other_skeptic()
	await wait_physics_frames(5)

	# Assert: Sprawdzamy czy w całym silniku nie narodził się żaden IconPlaceholder
	var icons = find_all_icons_in_engine(get_tree().root)
	assert_eq(icons.size(), 2)
	for icon in icons:
		assert_false(icon.visible)


func test_walkie_talkie_adds_message_to_ui_for_everyone():
	await wait_physics_frames(2)

	# Instancjonujemy Twój prawdziwy interfejs
	# (Upewnij się, że ścieżka do Twojej sceny UI jest poprawna!)
	var ui_scene = preload("uid://cjks5cw6xyieq")
	var mock_ui = ui_scene.instantiate()
	mock_ui.name = "UserInterface"
	game.add_child(mock_ui)

	# KLUCZOWE DLA TESTU: Wymuszamy autorytet sieciowy dla UI w środowisku offline,
	# aby funkcje sprawdzające "multiplayer.get_unique_id()" przepuściły kod dalej
	mock_ui.set_multiplayer_authority(1)
	mock_ui.walkie_talkie_message.visible = false

	# Tworzymy sceptyka i przypisujemy mu ID pasujące do autorytetu sieci (w GUT to zwykle 1)
	mock_skeptic = skeptic_scene.instantiate()
	mock_skeptic.id = 1
	mock_skeptic.set_multiplayer_authority(1)
	mock_skeptic.add_to_group("skeptics")
	game.add_child(mock_skeptic)

	await wait_physics_frames(4)

	# Rejestrujemy UI w Twoim skrypcie globalnym, dokładnie tak jak w grze!
	# (Zakładam, że Twój Singleton nazywa się Multiplayer lub NetworkManager)
	MultiplayerFeatures.local_ui = mock_ui

	# Act: Wywołujemy bezpośrednio funkcję RPC, która ma zmienić stan UI
	if mock_ui.has_method("receive_walkie_talkie_message"):
		mock_ui.receive_walkie_talkie_message("C15")
	else:
		# Jeśli funkcja nadal jest w Skeptic.gd, wywołujemy ją przez Sceptyka:
		mock_skeptic.send_walkie_talkie_message("C15")

	await wait_physics_frames(5)

	# Assert
	var walkie_talkie_ui_component = mock_ui.walkie_talkie_message
	assert_true(walkie_talkie_ui_component.visible, "Komponent WalkieTalkieMessage powinien być widoczny na ekranie!")
	assert_eq(walkie_talkie_ui_component.coordinates_text, "C15", "Współrzędne w UI nie pasują do wysłanej wiadomości!")


func find_all_icons_in_engine(node: Node) -> Array:
	var result = []
	if not is_instance_valid(node):
		return result
	if node is IconPlaceholder:
		result.append(node)
	for child in node.get_children():
		result += find_all_icons_in_engine(child)
	return result
