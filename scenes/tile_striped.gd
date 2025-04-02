# tile_striped.gd
class_name StripedTile
extends Node2D

func explode(board, game_manager):
	# Удаляем всю строку или столбец (упрощённо – строку)
	# Допустим, не учитываем "горизонт/вертик" – просто строку
	var pos = game_manager.find_tile_pos(self)
	if pos.x == -1:
		return
	# Удаляем все фишки в y=pos.y
	for x in range(game_manager.grid_size.x):
		var p = Vector2i(x, pos.y)
		if board.has(p):
			game_manager.remove_tile_at(p)
	# Удаляем сам StripedTile
	game_manager.remove_tile_at(pos)
