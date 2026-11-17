extends Control
## Standalone view of the delivered scene(s): the first scene under res://gimmick/scenes/, or
## `-- --scene=<id>`; `--dim=<f>` modulates it like a dimming host. Esc quits; --shot=<png> --frames=<n> saves a frame and quits (checks).

var _frames := 0
var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var ids := DirAccess.get_directories_at("res://gimmick/scenes")
	var id: String = _args.get("scene", ids[0] if ids.size() > 0 else "")
	var g = load("res://gimmick/gimmick_scene.gd").new()
	g.scene_path = "res://gimmick/scenes/%s/scene.json" % id
	g.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _args.has("dim"): var k := float(_args["dim"]); g.modulate = Color(k, k, k, 1.0)   # a host dimming the scene (e.g. 0.55)
	add_child(g)
	if _args.has("t"): g.seek(float(_args["t"]))   # start at t seconds (stills of a moving layer)
	for p in g.problems: printerr("GIMMICK ", p)
	print("GIMMICK scene %s ok=%s" % [id, g.ok()])
	if _args.has("seq"): _sequence(g)


## --seq=<dir> --n=<count> --step=<seconds>: saves n stills of the scene at t = t + i * step, named from f<first> (a deterministic clip for ffmpeg).
func _sequence(g: Control) -> void:
	var step := float(_args.get("step", "0.1"))
	for i in int(_args.get("n", "100")):
		g.seek(float(_args.get("t", "0")) + i * step)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/f%04d.png" % [_args["seq"], int(_args.get("first", "0")) + i])
	get_tree().quit()


func _process(_d: float) -> void:
	_frames += 1
	if _args.has("quit") and _frames == int(_args["quit"]): get_tree().quit()   # with --write-movie: recording length in frames
	if _args.has("shot") and _frames == int(_args.get("frames", "60")):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_args["shot"])
		get_tree().quit()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE: get_tree().quit()
