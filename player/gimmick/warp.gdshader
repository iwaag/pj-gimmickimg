shader_type canvas_item;
// A local, loopable warp of a still crop. Two displacement maps hold the cosine and sine parts of the motion
// (R = dx, G = dy, 127 = none); displacement = amp * (cos(w t) * map_c + sin(w t) * map_s), in pixels of the crop.
// Any spatial phase (waves travelling, a tip lagging its stem) is baked into the two maps. The maps are zero at the
// crop's border, so the crop meets the still seamlessly. The crop may carry its own alpha (a matted layer over a clean
// plate); the displaced alpha moves with the colour.
uniform sampler2D map_c : filter_linear;
uniform sampler2D map_s : filter_linear;
uniform float amp = 4.0;
uniform float omega = 1.2;
varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	vec2 c = (texture(map_c, UV).rg * 255.0 - 127.0) / 127.0;
	vec2 s = (texture(map_s, UV).rg * 255.0 - 127.0) / 127.0;
	vec2 d = (c * cos(omega * TIME) + s * sin(omega * TIME)) * amp;
	// Dimming (modulate) reaches this layer through the vertex colour. In fragment() COLOR already holds the undisplaced
	// texture x modulate, so multiplying by it would square the picture; take the modulate from vertex() instead.
	COLOR = texture(TEXTURE, UV + d / vec2(textureSize(TEXTURE, 0))) * vcol;
}
