extends Node
class_name MatchFinder

# Ищет матчи по горизонтали и вертикали.
# Возвращает массив словарей вида: { "type": <"horizontal"|"vertical">, "tiles": [<tile1>, <tile2>, ...] }
func find_matches(tiles, grid_size: Vector2i) -> Array:
	var matches = []

	# Горизонтальный проход
	for y in range(grid_size.y):
		var x = 0
		while x < grid_size.x:
			var index = x + y * grid_size.x
			var current_tile = tiles[index]
			# Пропускаем, если фишка не существует или нет Sprite2D
			if current_tile == null or not current_tile.has_node("Sprite2D"):
				x += 1
				continue
			var sprite = current_tile.get_node("Sprite2D") as Sprite2D
			var current_texture = sprite.texture
			var run = [ current_tile ]
			var next_x = x + 1
			while next_x < grid_size.x:
				var next_index = next_x + y * grid_size.x
				var next_tile = tiles[next_index]
				if next_tile != null and next_tile.has_node("Sprite2D"):
					var next_sprite = next_tile.get_node("Sprite2D") as Sprite2D
					if next_sprite.texture == current_texture:
						run.append(next_tile)
						next_x += 1
						continue
					else:
						break
				else:
					break
			if run.size() >= 3:
				matches.append({ "type": "horizontal", "tiles": run.duplicate() })
			x = next_x

	# Вертикальный проход
	for x in range(grid_size.x):
		var y = 0
		while y < grid_size.y:
			var index = x + y * grid_size.x
			var current_tile = tiles[index]
			if current_tile == null or not current_tile.has_node("Sprite2D"):
				y += 1
				continue
			var sprite = current_tile.get_node("Sprite2D") as Sprite2D
			var current_texture = sprite.texture
			var run = [ current_tile ]
			var next_y = y + 1
			while next_y < grid_size.y:
				var next_index = x + next_y * grid_size.x
				var next_tile = tiles[next_index]
				if next_tile != null and next_tile.has_node("Sprite2D"):
					var next_sprite = next_tile.get_node("Sprite2D") as Sprite2D
					if next_sprite.texture == current_texture:
						run.append(next_tile)
						next_y += 1
						continue
					else:
						break
				else:
					break
			if run.size() >= 3:
				matches.append({ "type": "vertical", "tiles": run.duplicate() })
			y = next_y

	return matches


# Пример функции подсветки найденных матчей (можно поместить в game_manager.gd)
func highlight_matches(tiles, grid_size: Vector2i, finder: MatchFinder):
	var matches = finder.find_matches(tiles, grid_size)
	if matches.is_empty():
		return

	# Подсвечиваем
	for match in matches:
		for t in match["tiles"]:
			if t.has_node("Sprite2D"):
				var s = t.get_node("Sprite2D") as Sprite2D
				s.modulate = Color(1, 0.5, 0.5)

	# Ждём 1 секунду
	await get_tree().create_timer(1.0).timeout

	# Сбрасываем цвет
	for t in tiles:
		if t.has_node("Sprite2D"):
			t.get_node("Sprite2D").modulate = Color(1, 1, 1)
