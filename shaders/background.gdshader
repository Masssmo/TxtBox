shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.1, 0.1, 0.3, 1.0);
uniform vec4 color_b : source_color = vec4(0.8, 0.3, 0.5, 1.0);
uniform float speed : hint_range(0.0, 5.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float blend = UV.y + sin(TIME * speed + UV.x * 3.0) * 0.1;
	COLOR = mix(color_a, color_b, blend);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
