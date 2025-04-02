extends Node2D

@export var tile_size: Vector2 = Vector2(64, 64)
@export var grid_size: Vector2i = Vector2i(8, 8)
@export var tile_scene_path: String = "res://scenes/tile.tscn"

@export var ratio: float = 1.2          # Во сколько раз увеличить спрайт относительно tile_size
@export var camera_zoom: Vector2 = Vector2(0.8, 0.8)  # Зум камеры (чем меньше, тем дальше поле)
@export var camera_offset: Vector2 = Vector2(0, 0)    # Смещение камеры

var board: Dictionary[Vector2i, Node] = {}
var textures: Array = []
var selected_tile: Node = null

func _ready():
	randomize()
	load_textures()
	center_field()
	spawn_initial_board()
	setup_camera()

# ----------------------------------------
# КАМЕРА
# ----------------------------------------
func setup_camera():
	if has_node("Camera2D"):
		var cam = get_node("Camera2D") as Camera2D
		cam.current = true
		cam.zoom = camera_zoom
		cam.position = camera_offset

# ----------------------------------------
# ЦЕНТРОВКА ПОЛЯ
# ----------------------------------------
func center_field():
	var viewport_size = get_viewport_rect().size
	var field_size = Vector2(grid_size.x * tile_size.x, grid_size.y * tile_size.y)
	position = (viewport_size - field_size)/2

# ----------------------------------------
# ЗАГРУЗКА ТЕКСТУР
# ----------------------------------------
func load_textures():
	textures.clear()
	var dir = DirAccess.open("res://assets/chips/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				var tex = load("res://assets/chips/" + file_name)
				if tex:
					textures.append(tex)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Не удалось открыть папку res://assets/chips/")

func get_random_texture() -> Texture2D:
	if textures.is_empty():
		push_error("Нет текстур!")
		return null
	return textures[randi() % textures.size()]

# ----------------------------------------
# СОЗДАНИЕ ПОЛЯ
# ----------------------------------------
func spawn_initial_board():
	board.clear()
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var tile = create_tile_at(x, y)
			board[Vector2i(x, y)] = tile

func create_tile_at(x: int, y: int) -> Node:
	var scene = load(tile_scene_path)
	if scene == null:
		push_error("Не удалось загрузить сцену: " + tile_scene_path)
		return null
	var tile = scene.instantiate()
	tile.position = Vector2(x, y) * tile_size
	add_child(tile)

	if tile.has_node("Sprite2D"):
		var s = tile.get_node("Sprite2D") as Sprite2D
		var tex = get_random_texture()
		if tex:
			s.texture = tex
			# Масштабируем, чтобы вписать в tile_size * ratio
			var tex_size = tex.get_size()
			var w_ratio = (tile_size.x * ratio) / tex_size.x
			var h_ratio = (tile_size.y * ratio) / tex_size.y
			var final_ratio = min(w_ratio, h_ratio)
			s.scale = Vector2(final_ratio, final_ratio)
	return tile

# ----------------------------------------
# ПОИСК МАТЧЕЙ
# ----------------------------------------
func find_matches() -> Array:
	var matches = []

	# Горизонталь
	for y in range(grid_size.y):
		var run = []
		for x in range(grid_size.x):
			var tile = board.get(Vector2i(x, y), null)
			if tile and same_texture(run, tile):
				run.append(tile)
			else:
				if run.size() >= 3:
					matches.append(run.duplicate())
				run.clear()
				if tile:
					run.append(tile)
		if run.size() >= 3:
			matches.append(run.duplicate())

	# Вертикаль
	for x in range(grid_size.x):
		var run = []
		for y in range(grid_size.y):
			var tile = board.get(Vector2i(x, y), null)
			if tile and same_texture(run, tile):
				run.append(tile)
			else:
				if run.size() >= 3:
					matches.append(run.duplicate())
				run.clear()
				if tile:
					run.append(tile)
		if run.size() >= 3:
			matches.append(run.duplicate())

	return matches

func same_texture(run: Array, tile: Node) -> bool:
	if run.is_empty():
		return true
	var first_tile = run[0]
	return get_tile_texture(first_tile) == get_tile_texture(tile)

func get_tile_texture(tile: Node) -> Texture2D:
	if tile.has_node("Sprite2D"):
		var s = tile.get_node("Sprite2D") as Sprite2D
		return s.texture
	return null

# ----------------------------------------
# УДАЛЕНИЕ МАТЧЕЙ
# ----------------------------------------
func remove_matches() -> bool:
	var found = find_matches()
	if found.is_empty():
		return false

	for run in found:
		if run.size() == 4:
			# Превращаем в striped
			create_striped(run[0], "H")
			# Удаляем остальные
			for i in range(1, run.size()):
				var p = find_tile_pos(run[i])
				if p.x != -1:
					remove_tile_at(p)
		else:
			# Обычное удаление
			for tile in run:
				var pos = find_tile_pos(tile)
				if pos.x != -1:
					remove_tile_at(pos)

	return true

func highlight_tile(tile: Node, col: Color):
	if tile.has_node("Sprite2D"):
		var s = tile.get_node("Sprite2D") as Sprite2D
		s.modulate = col

func find_tile_pos(tile: Node) -> Vector2i:
	for key in board.keys():
		if board[key] == tile:
			return key
	return Vector2i(-1, -1)

# ----------------------------------------
# ГРАВИТАЦИЯ (Gather Approach)
# ----------------------------------------
func apply_gravity():
	for x in range(grid_size.x):
		var col_tiles = []
		# Собираем все фишки столбца сверху вниз
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			if board.has(pos):
				col_tiles.append(board[pos])
				board.erase(pos)
		# col_tiles[0] – фишка, которая была сверху
		# Заполняем снизу (y=grid_size.y-1) вверх
		var new_y = grid_size.y - 1
		# Переворачиваем массив, чтобы нижняя фишка (изначально последняя) пошла первой
		col_tiles.reverse()
		for tile in col_tiles:
			var new_pos = Vector2i(x, new_y)
			new_y -= 1
			board[new_pos] = tile
			var target_pos = Vector2(new_pos.x, new_pos.y) * tile_size
			tile.create_tween().tween_property(tile, "position", target_pos, 0.3)

# ----------------------------------------
# ДОСПАВНИВАНИЕ ФИШЕК
# ----------------------------------------
func spawn_new_tiles_progressive() -> void:
	# Идём по рядам сверху вниз (y=0 -> y=grid_size.y-1)
	for y in range(grid_size.y-1, -1, -1):
		var spawned_any = false
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			if not board.has(pos):
				# Создаём фишку на "один ряд выше" (y=-1), чтобы упала сверху
				var tile = create_tile_at(x, -1) 
				# Сохраняем в board
				board[pos] = tile
				# Анимируем падение
				var target_pos = Vector2(x, y) * tile_size
				tile.create_tween().tween_property(tile, "position", target_pos, 0.4)
				spawned_any = true
		if spawned_any:
			# Если в этом ряду что-то заспавнили, подождём 0.1с,
			# чтобы была задержка перед следующим рядом
			await get_tree().create_timer(0.1).timeout

# ----------------------------------------
# ЦЕПНАЯ РЕАКЦИЯ
# ----------------------------------------
func process_matches():
	while await remove_matches():
		apply_gravity()
		await spawn_new_tiles_progressive()
		await get_tree().create_timer(0.3).timeout

# ----------------------------------------
# СВАП ФИШЕК (соседние) + обратный свап
# ----------------------------------------
func swap_tiles(a: Node, b: Node):
	var posA = find_tile_pos(a)
	var posB = find_tile_pos(b)
	if posA.x == -1 or posB.x == -1:
		return

	# Разрешаем свап только между соседними (манхэттенское расстояние = 1)
	if abs(posA.x - posB.x) + abs(posA.y - posB.y) != 1:
		return

	var orig_a_pos = a.position
	var orig_b_pos = b.position

	# Меняем местами в словаре
	var tmp = board[posA]
	board[posA] = board[posB]
	board[posB] = tmp

	# Меняем позиции узлов
	a.position = orig_b_pos
	b.position = orig_a_pos

	var matches = find_matches()
	if matches.is_empty():
		# Нет совпадений – откатываем
		await get_tree().create_timer(0.2).timeout
		a.position = orig_a_pos
		b.position = orig_b_pos
		var tmp2 = board[posA]
		board[posA] = board[posB]
		board[posB] = tmp2
	else:
		await process_matches()

# ----------------------------------------
# ОБРАБОТКА КЛИКОВ
# ----------------------------------------
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = event.position
		var found_tile: Node = null
		# Ищем фишку под кликом
		for key in board.keys():
			var tile = board[key]
			var global_pos = tile.get_global_position()
			var rect = Rect2(global_pos - tile_size/2, tile_size)
			if rect.has_point(click_pos):
				found_tile = tile
				break
		if found_tile:
			if selected_tile == null:
				selected_tile = found_tile
				highlight_tile(selected_tile, Color(1,1,0))  # желтый
			else:
				if selected_tile != found_tile:
					highlight_tile(selected_tile, Color(1,1,1))
					await swap_tiles(selected_tile, found_tile)
				else:
					highlight_tile(selected_tile, Color(1,1,1))
				selected_tile = null
			if found_tile and is_booster(found_tile):
				await activate_booster(found_tile)
				return
func activate_booster(tile: Node):
	# Вызываем explode у бустера (передаём board и self)
	if tile is StripedTile:
		tile.explode(board, self)
	elif tile is WrappedTile:
		tile.explode(board, self)
	elif tile is ColorBombTile:
		tile.explode(board, self)
	else:
		return
	# После удаления вызываем process_matches(), чтобы были cascades
	await process_matches()
func is_booster(tile: Node) -> bool:
	return tile is StripedTile or tile is WrappedTile or tile is ColorBombTile

func is_striped(tile: Node) -> bool:
	return tile is StripedTile

func is_wrapped(tile: Node) -> bool:
	return tile is WrappedTile
		
		
		
			
func is_colorbomb(tile: Node) -> bool:
	return tile is ColorBombTile
func remove_tile_at(pos: Vector2i):
	if board.has(pos):
		var t = board[pos]
		board.erase(pos)
		t.queue_free()
func create_striped(old_tile: Node, orientation: String):
	var pos = find_tile_pos(old_tile)
	if pos.x == -1:
		return
	remove_tile_at(pos)

	var scene = load("res://scenes/tile_striped.tscn")
	var booster_tile = scene.instantiate()
	booster_tile.position = old_tile.position
	add_child(booster_tile)
	board[pos] = booster_tile

	# Если хотите внутри tile_striped.gd хранить orientation,
	# можно прописать booster_tile.orientation = orientation
