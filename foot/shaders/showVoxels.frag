#version 440

in vec3 normal;
out vec4 FragColor;

uniform vec4 l_dir;
uniform mat4 V;

void main() {
    vec3 n = normalize(normal);
    float intensity = max(0.0, dot(n, l_dir.xyz));
    FragColor = intensity * vec4(0.5, 0.5, 0.5, 1) + vec4(0.5, 0.5, 0.5, 1);
}
