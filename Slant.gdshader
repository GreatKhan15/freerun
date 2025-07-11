shader_type canvas_item;

uniform float shear = -0.15; // adjust this
uniform bool horizontal = true;

void vertex() {
    if (horizontal) {
        // Shear in X
        VERTEX.x += VERTEX.y * shear;
    } else {
        // Shear in Y
        VERTEX.y += VERTEX.x * shear;
    }
}
