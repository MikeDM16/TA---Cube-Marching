#version 440

in Data {
    vec3 l_dir;
    vec3 normal;
} DataIn;

out vec4 FragColor;

void main() {
    vec3 n = normalize(DataIn.normal);
    float intensity = max(0.0, dot(n, DataIn.l_dir));
    FragColor = intensity * vec4(0.7, 0.7, 0.7, 1) + vec4(0.3, 0.3, 0.3, 1);
}
