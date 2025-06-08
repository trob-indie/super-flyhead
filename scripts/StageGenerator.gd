extends Node3D

var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

var grid_size = Vector3i(5, 5, 5)
var path: Array[Vector3i] = []

func _ready():
	var texture = load("res://icon.svg")
	
	material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.cull_mode = BaseMaterial3D.CULL_DISABLED # disable backface culling to see inside
	
	generate_rooms()
	create_mesh_from_rooms()

func generate_rooms():
	path.clear()
	var grid_max_y = grid_size.y - 1

	var total_layers = 5
	var current_layer_z = 0
	var previous_layer_cells = []

	# Create the first room with neighbor expansion
	var room_cells = [Vector3i(0, grid_max_y, current_layer_z)]
	var cells_to_expand = [room_cells[0]]
	var desired_room_size = randi_range(2, 6)
	var directions = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0)]

	# Force at least 2 cells for the first room
	var first_cell = room_cells[0]
	for dir in directions:
		var neighbor = first_cell + dir
		if abs(neighbor.x) < grid_size.x / 2 and neighbor.y >= 0 and neighbor.y <= grid_max_y:
			if not room_cells.has(neighbor):
				room_cells.append(neighbor)
				cells_to_expand.append(neighbor)
				break

	while room_cells.size() < desired_room_size and cells_to_expand.size() > 0:
		var cell = cells_to_expand.pop_front()
		for dir in directions:
			var neighbor = cell + dir
			if abs(neighbor.x) < grid_size.x / 2 and neighbor.y >= 0 and neighbor.y <= grid_max_y:
				if not room_cells.has(neighbor):
					# 🔥 Calculate decreasing bias based on room growth
					var progress = float(room_cells.size()) / desired_room_size
					var bias = 1.0 - progress
					var base_chance = 0.8
					var final_chance = base_chance * bias
					# 🔥 Favor downward direction slightly
					if dir == Vector3i(0, -1, 0):
						final_chance += 0.1
					elif dir == Vector3i(0, 1, 0):
						final_chance -= 0.1
					final_chance = clamp(final_chance, 0.0, 1.0)

					if randf() < final_chance:
						room_cells.append(neighbor)
						cells_to_expand.append(neighbor)
						if room_cells.size() >= desired_room_size:
							break
		if room_cells.size() >= desired_room_size:
			break

	path.append_array(room_cells)
	previous_layer_cells = room_cells

	# Create rooms for the next layers with downward bias and decreasing probability
	for i in range(1, total_layers):
		current_layer_z -= 1

		var anchor_cell = previous_layer_cells.pick_random()
		room_cells = [Vector3i(anchor_cell.x, anchor_cell.y, current_layer_z)]

		cells_to_expand = [room_cells[0]]
		desired_room_size = randi_range(2, 6)

		# First expansion step to ensure at least 2 cells
		first_cell = room_cells[0]
		for dir in directions:
			var neighbor = first_cell + dir
			if abs(neighbor.x) < grid_size.x / 2 and neighbor.y >= 0 and neighbor.y <= grid_max_y:
				if not room_cells.has(neighbor):
					room_cells.append(neighbor)
					cells_to_expand.append(neighbor)
					break

		while room_cells.size() < desired_room_size and cells_to_expand.size() > 0:
			var cell = cells_to_expand.pop_front()
			for dir in directions:
				var neighbor = cell + dir
				if abs(neighbor.x) < grid_size.x / 2 and neighbor.y >= 0 and neighbor.y <= grid_max_y:
					if not room_cells.has(neighbor):
						# 🔥 Decreasing bias based on room growth
						var progress = float(room_cells.size()) / desired_room_size
						var bias = 1.0 - progress
						var base_chance = 0.9
						var final_chance = base_chance * bias
						# 🔥 Favor downward direction
						if dir == Vector3i(0, -1, 0):
							final_chance += 0.1
						elif dir == Vector3i(0, 1, 0):
							final_chance -= 0.1
						final_chance = clamp(final_chance, 0.0, 1.0)

						if randf() < final_chance:
							room_cells.append(neighbor)
							cells_to_expand.append(neighbor)
							if room_cells.size() >= desired_room_size:
								break
			if room_cells.size() >= desired_room_size:
				break

		path.append_array(room_cells)
		previous_layer_cells = room_cells


func create_mesh_from_rooms():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)

	var size = 100.0
	var spacing = size * 2.0
	var directions = {
		"right": Vector3i(1, 0, 0),
		"left": Vector3i(-1, 0, 0),
		"up": Vector3i(0, 1, 0),
		"down": Vector3i(0, -1, 0)
	}

	var room_cells_set = path.duplicate()

	for cell in path:
		var o = Vector3(cell) * spacing
		var vertices = [
			Vector3(-size, -size, -size) + o,
			Vector3(size, -size, -size) + o,
			Vector3(size, size, -size) + o,
			Vector3(-size, size, -size) + o,
			Vector3(-size, -size, size) + o,
			Vector3(size, -size, size) + o,
			Vector3(size, size, size) + o,
			Vector3(-size, size, size) + o
		]

		var uvs = [
			Vector2(0, 0),
			Vector2(1, 0),
			Vector2(1, 1),
			Vector2(0, 1)
		]

		var faces = {
			"back": [0, 1, 2, 3],
			"right": [1, 5, 6, 2],
			"front": [5, 4, 7, 6],
			"left": [4, 0, 3, 7],
			"top": [3, 2, 6, 7],
			"bottom": [4, 5, 1, 0]
		}

		# Only add faces if there is no adjacent cell in that direction
		if not room_cells_set.has(cell + directions["right"]):
			add_face(st, vertices, faces["right"], uvs)
		if not room_cells_set.has(cell + directions["left"]):
			add_face(st, vertices, faces["left"], uvs)
		if not room_cells_set.has(cell + directions["up"]):
			add_face(st, vertices, faces["top"], uvs)
		if not room_cells_set.has(cell + directions["down"]):
			add_face(st, vertices, faces["bottom"], uvs)

		# Always add front/back faces (no neighbor in z direction)
		add_face(st, vertices, faces["front"], uvs)
		add_face(st, vertices, faces["back"], uvs)

	var mesh = st.commit()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

func add_face(st: SurfaceTool, vertices: Array, face: Array, uvs: Array):
	st.set_uv(uvs[0])
	st.add_vertex(vertices[face[0]])

	st.set_uv(uvs[1])
	st.add_vertex(vertices[face[1]])

	st.set_uv(uvs[2])
	st.add_vertex(vertices[face[2]])

	st.set_uv(uvs[2])
	st.add_vertex(vertices[face[2]])

	st.set_uv(uvs[3])
	st.add_vertex(vertices[face[3]])

	st.set_uv(uvs[0])
	st.add_vertex(vertices[face[0]])
