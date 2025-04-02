# tile_colorbomb.gd
class_name ColorBombTile
extends Node2D

func explode(board, game_manager):
	# Удаляем все фишки того же "цвета" (texture), что у нас
	if not has_node("Sprite2D"):
		return
	var s = $Sprite2D
	var my_tex = s.texture
	if my_tex == null:
		return

	# Проходим по board, ищем те же текстуры
	for key in board.keys():
		var tile = board[key]
		if tile.has_node("Sprite2D"):
			var st = tile.get_node("Sprite2D") as Sprite2D
			if st.texture == my_tex:
				game_manager.remove_tile_at(key)

	# Удаляем сам ColorBombTile
	var pos = game_manager.find_tile_pos(self)
	if pos.x != -1:
		game_manager.remove_tile_at(pos)
