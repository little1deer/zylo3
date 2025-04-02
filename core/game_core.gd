# core/game_core.gd
extends Node
class_name GameCore

# Базовый класс для плиток
class Tile:
	var board = null
	var x = 0
	var y = 0
	var destructable = true
	
	func _init(_board = null, _x = 0, _y = 0):
		board = _board
		x = _x
		y = _y
	
	# Возвращает массив плиток, которые будут уничтожены при взрыве
	func explode() -> Array:
		return [self]
	
	# Проигрывает визуальные эффекты взрыва (передайте FxPool, если есть)
	func show_explosion_fx(pool):
		# Переопределите в наследниках
		pass
	
	# Обновляет состояние игры (например, увеличивает счет)
	func update_game_state(state):
		# Переопределите в наследниках
		pass

# Класс для хранения состояния игры
class GameState:
	var score = 0
	var collected_candies = {}   # Например, словарь с ключами – цветами конфет
	
	func _init():
		reset()
	
	func reset():
		score = 0
		collected_candies.clear()
		# Инициализируйте другие данные, если нужно
	
	func add_candy(color):
		if collected_candies.has(color):
			collected_candies[color] += 1
		else:
			collected_candies[color] = 1

# Класс игрового поля (GameBoard)
class GameBoard:
	var level = null         # Данные уровня (ширина, высота, массив плиток и т.д.)
	var game_state = GameState.new()
	var tiles = []           # Массив плиток (типа Tile)
	var tile_positions = []  # Массив позиций для плиток
	var grid_width = 0
	var grid_height = 0
	
	# Загрузка уровня. level_data – словарь с данными уровня
	func load_level(level_data):
		grid_width = level_data.width
		grid_height = level_data.height
		tiles.clear()
		tile_positions.clear()
		
		# Создаем плитки на основе level_data.tiles (здесь для примера все плитки создаются одинаковыми)
		for j in range(grid_height):
			for i in range(grid_width):
				# Допустим, level_data.tiles – массив строк, где "Candy" означает обычную конфету
				var tile_type = level_data.tiles[i + j * grid_width]
				var tile = create_tile(i, j, tile_type)
				tiles.append(tile)
				# Простое позиционирование: каждая плитка занимает 64x64 пикселя
				tile_positions.append(Vector2(i * 64, j * 64))
		
		game_state.reset()
	
	# Создание плитки. tile_data может быть, например, строкой "Candy"
	func create_tile(x, y, tile_data) -> Tile:
		# Для начала создадим обычную плитку типа Candy
		var tile = Tile.new(self, x, y)
		# Здесь можно добавить логику установки цвета или других параметров на основе tile_data
		return tile
	
	# Получение плитки по координатам
	func get_tile(x, y) -> Tile:
		if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
			return tiles[x + y * grid_width]
		return null
	
	# Пример метода для взрыва плитки
	func explode_tile(tile: Tile) -> Array:
		if tile == null:
			return []
		var exploded_tiles = tile.explode()
		# Вызов эффектов и обновление состояния
		for t in exploded_tiles:
			t.show_explosion_fx(null)  # Передайте FxPool, если потребуется
			t.update_game_state(game_state)
		# Удаление плитки
		var index = tiles.find(tile)
		if index != -1:
			tiles[index] = null
		return exploded_tiles
	
	# Пример метода для применения гравитации (очень базовая реализация)
	func apply_gravity():
		# Здесь реализуйте логику перемещения плиток вниз, если под ними пусто
		pass
