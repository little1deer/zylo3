# tile_wrapped.gd
class_name WrappedTile
extends Node2D

func explode(board, game_manager):
	# Удаляем 3×3 вокруг
	var pos = game_manager.find_tile_pos(self)
	if pos.x == -1:
		return
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var p = Vector2i(pos.x + dx, pos.y + dy)
			if board.has(p):
				game_manager.remove_tile_at(p)
	# Саму себя тоже удаляем
	# (если не было в цикле)
	if board.has(pos):
		game_manager.remove_tile_at(pos)
