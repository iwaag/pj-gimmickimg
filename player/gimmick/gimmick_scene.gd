extends Control
## Plays one gimmick scene: a still image with animated layers over it (project_coop p1; contract:
## docs/delivery.md). Relocatable: every path in scene.json is relative to that file, and this folder may sit
## anywhere under res://. Works with gl_compatibility and Forward Plus.
##
##   var g = load("res://<folder>/gimmick_scene.gd").new()
##   g.scene_path = "res://<folder>/scenes/<id>/scene.json"   # before adding it to the tree
##   g.fit = "cover"                                            # cover | contain | stretch
##   add_child(g)
##
## The node fills the rect a host gives it (anchors, size) like a TextureRect; `modulate` dims every layer.
## `problems` lists what could not be loaded (a missing file is skipped, never fatal); `ok()` is true when the
## scene file parsed and every layer loaded.

const SHADER := "alpha_mask.gdshader"
const WARP_SHADER := "warp.gdshader"

@export var scene_path := ""
@export_enum("cover", "contain", "stretch") var fit := "cover"

var scene: Dictionary = {}
var problems: Array[String] = []
var _stage := Node2D.new()
var _size := Vector2(1, 1)
var _time := 0.0
var _sparkles: Array = []  # [Sprite2D, period, phase, peak alpha, base scale]
var _motes: Array = []     # [Sprite2D, base position, velocity, phase, peak alpha, rect]
var _paths: Array = []     # path layers: dictionaries, see the "path" case of _layer
var _soft_tex: Texture2D
var _star_tex: Texture2D


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	resized.connect(_layout)
	load_scene(scene_path)


func _process(delta: float) -> void:
	_time += delta
	for sp in _sparkles:
		var a := maxf(0.0, sin(TAU * _time / sp[1] + sp[2]))
		a = a * a * a
		sp[0].modulate.a = a * sp[3]
		sp[0].scale = Vector2.ONE * sp[4] * (0.5 + 0.5 * a)
	for p in _paths:
		_move_path(p)
	for m in _motes:
		var r: Rect2 = m[5]
		var q: Vector2 = m[1] + m[2] * _time
		q.x = fposmod(q.x - r.position.x, r.size.x)
		q.y = fposmod(q.y - r.position.y, r.size.y)
		var f := Vector2(q.x / r.size.x, q.y / r.size.y)
		var edge := minf(minf(f.x, 1.0 - f.x), minf(f.y, 1.0 - f.y))
		var fade := smoothstep(0.0, 0.12, edge)
		var tw := 0.65 + 0.35 * sin(_time * 1.3 + m[3])
		m[0].position = r.position + q + Vector2(sin(_time * 0.6 + m[3]), cos(_time * 0.45 + m[3] * 1.7)) * 7.0
		m[0].modulate.a = fade * tw * m[4]


## Jumps the scene's clock (paths, glints, motes) to t seconds; for stills and checks.
func seek(t: float) -> void:
	_time = t


func ok() -> bool:
	return not scene.is_empty() and problems.is_empty()


func load_scene(path: String) -> void:
	for c in _stage.get_children():
		c.queue_free()
	_sparkles.clear()
	_motes.clear()
	_paths.clear()
	problems.clear()
	scene = {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if typeof(d) != TYPE_DICTIONARY or d.get("format", "") != "gimmick_scene":
		problems.append("scene missing or not a gimmick_scene (%s)" % path)
		return
	scene = d
	var base := path.get_base_dir()
	_size = Vector2(d["size"][0], d["size"][1])
	for layer in d.get("layers", []):
		var n := _layer(layer, base)
		if n != null:
			n.name = str(layer.get("name", layer["type"]))
			_stage.add_child(n)
	for p in _paths:   # the layer drawn just before a path layer is where it returns to after a "behind" stretch
		var i: int = p["root"].get_index()
		p["after"] = _stage.get_child(i - 1) if i > 0 else null
	_layout()


func _layer(l: Dictionary, base: String) -> CanvasItem:
	match str(l["type"]):
		"image":
			var tex := _tex(base, l["src"])
			if tex == null: return null
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = _vec(l.get("position", [0, 0]))
			return s
		"video":
			var path := base.path_join(l["src"])
			if not ResourceLoader.exists(path):
				problems.append("video missing (%s)" % l["src"])
				return null
			var p := VideoStreamPlayer.new()
			p.expand = true  # before the stream and size: otherwise the control grows to the clip's own size
			p.stream = load(path)
			var r: Array = l["rect"]
			p.position = Vector2(r[0], r[1])
			p.size = Vector2(r[2], r[3])
			p.loop = l.get("loop", true)
			p.autoplay = true
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if l.has("alpha"):
				var a := _tex(base, l["alpha"])
				if a != null:
					var m := ShaderMaterial.new()
					m.shader = load(get_script().resource_path.get_base_dir().path_join(SHADER))
					m.set_shader_parameter("alpha_tex", a)
					p.material = m
			return p
		"frames":
			var sf := SpriteFrames.new()
			sf.set_animation_speed("default", float(l.get("fps", 12)))
			sf.set_animation_loop("default", true)
			var frames: Array = []
			for f in l["frames"]:
				var t := _tex(base, f)
				if t != null: frames.append(t)
			if frames.is_empty(): return null
			for t in frames: sf.add_frame("default", t)
			if l.get("pingpong", false):
				for i in range(frames.size() - 2, 0, -1): sf.add_frame("default", frames[i])
			var s := AnimatedSprite2D.new()
			s.sprite_frames = sf
			s.centered = false
			s.position = _vec(l.get("position", [0, 0]))
			s.autoplay = "default"
			return s
		"warp":
			var tex := _tex(base, l["src"])
			var mc := _tex(base, l["map_c"])
			var ms := _tex(base, l["map_s"])
			if tex == null or mc == null or ms == null: return null
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = _vec(l.get("position", [0, 0]))
			var m := ShaderMaterial.new()
			m.shader = load(get_script().resource_path.get_base_dir().path_join(WARP_SHADER))
			m.set_shader_parameter("map_c", mc)
			m.set_shader_parameter("map_s", ms)
			m.set_shader_parameter("amp", float(l.get("amp", 4.0)))
			m.set_shader_parameter("omega", TAU / float(l.get("period", 5.0)))
			s.material = m
			return s
		"path":
			# a sprite (body, optionally wings that flutter about a root) that follows a looping coordinate path:
			# samples [t (0..1 of period), x, y, rotation deg, scale x (negative = mirrored), scale y] evenly spaced in t,
			# t = 0 and 1 equal; `origin` is the sprite's anchor (crop px), `behind` + `behind_when` ([[t0, t1]]) draw it
			# behind the named layers during those parts of the loop
			var body := _tex(base, l["src"])
			if body == null: return null
			var root := Node2D.new()
			var org := _vec(l.get("origin", [0, 0]))
			var wing: Node2D = null
			if l.has("wing_src"):
				var wt := _tex(base, l["wing_src"])
				if wt != null:
					wing = Node2D.new()
					var pv := _vec(l.get("wing_pivot", [0, 0]))
					wing.position = pv - org
					var ws := Sprite2D.new()
					ws.texture = wt
					ws.centered = false
					ws.position = -pv
					wing.add_child(ws)
					root.add_child(wing)
			var bs := Sprite2D.new()
			bs.texture = body
			bs.centered = false
			bs.position = -org
			root.add_child(bs)
			_paths.append({"root": root, "wing": wing, "samples": l.get("samples", []), "period": float(l.get("period", 10.0)),
				"wing_deg": float(l.get("wing_deg", 0.0)), "wing_hz": float(l.get("wing_hz", 10.0)),
				"behind": l.get("behind", []), "when": l.get("behind_when", []), "is_behind": false, "after": null})
			_move_path(_paths[-1])
			return root
		"sparkle":
			# points: [x, y, size px, period s, phase] each; a four-point star that flares and fades, added to the still
			var root := Node2D.new()
			var add := _additive()
			var col := _color(l.get("color", [1.0, 0.96, 0.85]))
			var peak := float(l.get("alpha", 0.9))
			for p in l.get("points", []):
				var sp := Sprite2D.new()
				sp.texture = _star()
				sp.material = add
				sp.modulate = Color(col, 0.0)
				sp.position = Vector2(p[0], p[1])
				root.add_child(sp)
				_sparkles.append([sp, float(p[3]), float(p[4]), peak, float(p[2]) / 48.0])
			return root
		"pollen":
			# motes drift across `rect` with a velocity each and wrap at its edges, fading there
			var root := Node2D.new()
			var add := _additive()
			var rr: Array = l["rect"]
			var rect := Rect2(rr[0], rr[1], rr[2], rr[3])
			var col := _color(l.get("color", [1.0, 0.9, 0.55]))
			var rng := RandomNumberGenerator.new()
			rng.seed = int(l.get("seed", 1))
			var v: Array = l.get("velocity", [8, -3])
			var sz: Array = l.get("size", [4, 12])
			for i in int(l.get("count", 30)):
				var sp := Sprite2D.new()
				sp.texture = _soft()
				sp.material = add
				sp.modulate = Color(col, 0.0)
				var k := rng.randf()
				sp.scale = Vector2.ONE * lerpf(sz[0], sz[1], k * k) / 32.0
				root.add_child(sp)
				var vel := Vector2(v[0], v[1]) * rng.randf_range(0.6, 1.4) + Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2))
				_motes.append([sp, Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y), vel,
					rng.randf() * TAU, float(l.get("alpha", 0.6)) * rng.randf_range(0.5, 1.0), rect])
			return root
	problems.append("unknown layer type %s" % l["type"])
	return null


func _move_path(p: Dictionary) -> void:
	var smp: Array = p["samples"]
	var n := smp.size() - 1
	if n < 1: return
	var f := fposmod(_time / p["period"], 1.0)
	var k := f * n
	var i := mini(int(k), n - 1)
	var a: Array = smp[i]
	var b: Array = smp[i + 1]
	var w := k - i
	var root: Node2D = p["root"]
	root.position = Vector2(lerpf(a[1], b[1], w), lerpf(a[2], b[2], w))
	root.rotation_degrees = lerpf(a[3], b[3], w)
	root.scale = Vector2(lerpf(a[4], b[4], w), lerpf(a[5], b[5], w))
	if a.size() > 6 and b.size() > 6:   # optional 7th sample value: opacity (a part that fades out and in to restart its loop)
		root.modulate.a = lerpf(a[6], b[6], w)
	if p["wing"] != null:
		p["wing"].rotation_degrees = p["wing_deg"] * sin(TAU * p["wing_hz"] * _time)
	var behind := false
	for r in p["when"]:
		if f >= r[0] and f < r[1]: behind = true
	if behind != p["is_behind"] and root.get_parent() == _stage:
		p["is_behind"] = behind
		if behind:
			var first := -1
			for nm in p["behind"]:
				var c := _stage.get_node_or_null(str(nm))
				if c != null and (first < 0 or c.get_index() < first): first = c.get_index()
			if first >= 0: _stage.move_child(root, first)
		elif p["after"] != null:
			_stage.move_child(root, p["after"].get_index() + (0 if root.get_index() < p["after"].get_index() else 1))


func _tex(base: String, rel: String) -> Texture2D:
	var path := base.path_join(rel)
	if not ResourceLoader.exists(path):
		problems.append("image missing (%s)" % rel)
		return null
	return load(path)


func _color(a: Array) -> Color:
	return Color(a[0], a[1], a[2])


func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _soft() -> Texture2D:
	if _soft_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var r := Vector2(x - 31.5, y - 31.5).length() / 32.0
				var a := clampf(1.0 - r, 0.0, 1.0)
				a = a * a * (3.0 - 2.0 * a)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_soft_tex = ImageTexture.create_from_image(img)
	return _soft_tex


func _star() -> Texture2D:
	if _star_tex == null:
		var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
		for y in 48:
			for x in 48:
				var dx := absf(x - 23.5) / 24.0
				var dy := absf(y - 23.5) / 24.0
				var core := exp(-(dx * dx + dy * dy) * 40.0)
				var h := exp(-dy * 60.0) * clampf(1.0 - dx, 0.0, 1.0) * 0.8
				var v := exp(-dx * 60.0) * clampf(1.0 - dy, 0.0, 1.0) * 0.8
				img.set_pixel(x, y, Color(1, 1, 1, clampf(core + h + v, 0.0, 1.0)))
		_star_tex = ImageTexture.create_from_image(img)
	return _star_tex


func _vec(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


func _layout() -> void:
	var k := size / _size
	match fit:
		"cover": k = Vector2.ONE * maxf(k.x, k.y)
		"contain": k = Vector2.ONE * minf(k.x, k.y)
	_stage.scale = k
	_stage.position = (size - _size * k) / 2.0
