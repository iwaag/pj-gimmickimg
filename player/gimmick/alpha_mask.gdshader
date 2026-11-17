shader_type canvas_item;
// A layer's colour with a separate (feathered) alpha image: a local animated sprite over a still.
// The incoming COLOR is already the texture times modulate; only its alpha is replaced.
uniform sampler2D alpha_tex : filter_linear;
void fragment() {
	COLOR.a *= texture(alpha_tex, UV).r;
}
