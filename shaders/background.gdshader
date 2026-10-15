shader_type canvas_item;

// Palette
uniform vec4 baseColor : source_color = vec4(0.10, 0.11, 0.22, 1.0);
uniform vec4 blobColor1 : source_color = vec4(0.18, 0.22, 0.42, 1.0);
uniform vec4 blobColor2 : source_color = vec4(0.26, 0.20, 0.40, 1.0);
uniform vec4 blobColor3 : source_color = vec4(0.14, 0.28, 0.40, 1.0);
uniform vec4 fogColor : source_color = vec4(0.80, 0.82, 0.95, 1.0);

// Blobs
uniform float speed : hint_range(0.0, 1.0) = 0.15;
uniform float blobSize : hint_range(0.1, 1.5) = 0.55;

// Fog
uniform float fogSpeed : hint_range(0.0, 0.5) = 0.04;
uniform float fogScale : hint_range(0.5, 10.0) = 3.0;
uniform float fogStrength : hint_range(0.0, 1.0) = 0.12;

// Grain (hides color banding in video)
uniform float grainStrength : hint_range(0.0, 0.05) = 0.012;

// A pseudo random number (0-1) for a grid cell. Uses integer maths so the same cell always gives exactly the same value.
float hash(vec2 p) {
	uvec2 q = uvec2(ivec2(floor(p))) * uvec2(1597334673u, 3812015801u);
	uint n = (q.x ^ q.y) * 1597334673u;
	return float(n) / 4294967295.0;
}

// Smooth-looking per-pixel noise for dithering (hides colour banding).
float ditherNoise(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// Smooth random hills : random values on a grid, blended smoothly between grid points.
float valueNoise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	vec2 smoothLocal = local * local * (3.0 - 2.0 * local);
	return mix(mix(a, b, smoothLocal.x), mix(c, d, smoothLocal.x), smoothLocal.y);
}

// Layers of noise stacked from big to small: the "cloudy" look.
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * valueNoise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// How strongly a blob centred at `center` affects this pixel: 1 at the centre, fading softly to 0.
float blob(vec2 uv, vec2 center, float size, float aspect) {
	vec2 diff = uv - center;
	diff.x *= aspect; // keep blobs round on a tall screen
	float dist = length(diff);
	return exp(-(dist * dist) / (size * size));
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x; // width / height
	float t = TIME * speed;

	// Each blob drifts on its own slow looping path, with different speeds so they never sync up.
	vec2 center1 = vec2(0.30 + 0.25 * sin(t * 1.0), 0.30 + 0.20 * cos(t * 0.8));
	vec2 center2 = vec2(0.70 + 0.25 * cos(t * 0.7), 0.55 + 0.25 * sin(t * 0.9 + 1.0));
	vec2 center3 = vec2(0.45 + 0.30 * sin(t * 0.6 + 2.0), 0.80 + 0.15 * cos(t * 1.1));

	// Start from the base colour and blend each blob in on top.
	vec3 col = baseColor.rgb;
	col = mix(col, blobColor1.rgb, blob(UV, center1, blobSize, aspect));
	col = mix(col, blobColor2.rgb, blob(UV, center2, blobSize, aspect));
	col = mix(col, blobColor3.rgb, blob(UV, center3, blobSize, aspect));

	// Fog: two noise layers drifting in different directions, blended together.
	vec2 fogUv = vec2(UV.x * aspect, UV.y) * fogScale;
	float fogTime = TIME * fogSpeed;
	float fogA = fbm(fogUv + vec2(fogTime, fogTime * 0.3));
	float fogB = fbm(fogUv * 1.4 + vec2(-fogTime * 0.6, fogTime * 0.2));
	float fog = smoothstep(0.35, 0.75, (fogA + fogB) * 0.5);
	col = mix(col, fogColor.rgb, fog * fogStrength);

	// Tiny per-pixel noise so smooth gradients don't turn into visible bands after video compression.
	col += (ditherNoise(FRAGCOORD.xy + fract(TIME) * 100.0) - 0.5) * grainStrength;

	COLOR = vec4(col, 1.0);
}
