#version 440

/*
https://pastebin.com/DQ4Xjn7t
*/

layout(points) in;
layout(triangle_strip, max_vertices = 256) out;

layout(std140, binding = 2) buffer triangles {
    ivec3 TRIANGLES[][5];
};

uniform mat4 PVM;
uniform sampler3D grid;
uniform int GridSize;
uniform int level = 0;

float ISO_LEVEL = 0.00f;

float densities[8];
vec3 corners[8];

vec3 vertices[12] = {vec3(0,0,0), vec3(0,0,0), vec3(0,0,0), vec3(0,0,0),
                     vec3(0,0,0), vec3(0,0,0), vec3(0,0,0), vec3(0,0,0),
                     vec3(0,0,0), vec3(0,0,0), vec3(0,0,0), vec3(0,0,0)};

ivec4 faces[6] = {ivec4(0,1,3,2), ivec4(5,4,6,7), ivec4(4,5,0,1),
                  ivec4(3,2,7,6), ivec4(0,3,4,7), ivec4(2,1,6,5)};

int EDGES[256] = {
    0x0,    0x109,  0x203,  0x30a,  0x406,  0x50f,  0x605,  0x70c,  0x80c,  0x905,  0xa0f,  0xb06,  0xc0a,  0xd03,  0xe09,  0xf00,
    0x190,  0x99,   0x393,  0x29a,  0x596,  0x49f,  0x795,  0x69c,  0x99c,  0x895,  0xb9f,  0xa96,  0xd9a,  0xc93,  0xf99,  0xe90,
    0x230,  0x339,  0x33,   0x13a,  0x636,  0x73f,  0x435,  0x53c,  0xa3c,  0xb35,  0x83f,  0x936,  0xe3a,  0xf33,  0xc39,  0xd30,
    0x3a0,  0x2a9,  0x1a3,  0xaa,   0x7a6,  0x6af,  0x5a5,  0x4ac,  0xbac,  0xaa5,  0x9af,  0x8a6,  0xfaa,  0xea3,  0xda9,  0xca0,
    0x460,  0x569,  0x663,  0x76a,  0x66,   0x16f,  0x265,  0x36c,  0xc6c,  0xd65,  0xe6f,  0xf66,  0x86a,  0x963,  0xa69,  0xb60,
    0x5f0,  0x4f9,  0x7f3,  0x6fa,  0x1f6,  0xff,   0x3f5,  0x2fc,  0xdfc,  0xcf5,  0xfff,  0xef6,  0x9fa,  0x8f3,  0xbf9,  0xaf0,
    0x650,  0x759,  0x453,  0x55a,  0x256,  0x35f,  0x55,   0x15c,  0xe5c,  0xf55,  0xc5f,  0xd56,  0xa5a,  0xb53,  0x859,  0x950,
    0x7c0,  0x6c9,  0x5c3,  0x4ca,  0x3c6,  0x2cf,  0x1c5,  0xcc,   0xfcc,  0xec5,  0xdcf,  0xcc6,  0xbca,  0xac3,  0x9c9,  0x8c0,
    0x8c0,  0x9c9,  0xac3,  0xbca,  0xcc6,  0xdcf,  0xec5,  0xfcc,  0xcc,   0x1c5,  0x2cf,  0x3c6,  0x4ca,  0x5c3,  0x6c9,  0x7c0,
    0x950,  0x859,  0xb53,  0xa5a,  0xd56,  0xc5f,  0xf55,  0xe5c,  0x15c,  0x55,   0x35f,  0x256,  0x55a,  0x453,  0x759,  0x650,
    0xaf0,  0xbf9,  0x8f3,  0x9fa,  0xef6,  0xfff,  0xcf5,  0xdfc,  0x2fc,  0x3f5,  0xff,   0x1f6,  0x6fa,  0x7f3,  0x4f9,  0x5f0,
    0xb60,  0xa69,  0x963,  0x86a,  0xf66,  0xe6f,  0xd65,  0xc6c,  0x36c,  0x265,  0x16f,  0x66,   0x76a,  0x663,  0x569,  0x460,
    0xca0,  0xda9,  0xea3,  0xfaa,  0x8a6,  0x9af,  0xaa5,  0xbac,  0x4ac,  0x5a5,  0x6af,  0x7a6,  0xaa,   0x1a3,  0x2a9,  0x3a0,
    0xd30,  0xc39,  0xf33,  0xe3a,  0x936,  0x83f,  0xb35,  0xa3c,  0x53c,  0x435,  0x73f,  0x636,  0x13a,  0x33,   0x339,  0x230,
    0xe90,  0xf99,  0xc93,  0xd9a,  0xa96,  0xb9f,  0x895,  0x99c,  0x69c,  0x795,  0x49f,  0x596,  0x29a,  0x393,  0x99,   0x190,
    0xf00,  0xe09,  0xd03,  0xc0a,  0xb06,  0xa0f,  0x905,  0x80c,  0x70c,  0x605,  0x50f,  0x406,  0x30a,  0x203,  0x109,  0x0
};

void emit_vert(int vert) {
    gl_Position = PVM * vec4(corners[vert], 1);
    EmitVertex();
}

void emit_face(int face) {
    emit_vert(faces[face][1]);
    emit_vert(faces[face][0]);
    emit_vert(faces[face][3]);
    emit_vert(faces[face][2]);
    EndPrimitive();
}

void emit_cube() {
    for (int face = 0; face < 6; face++)
        emit_face(face);
}

void emit_triangle(int x, int y, int z){
    gl_Position = PVM * vec4(vertices[z], 1);
    EmitVertex();

    gl_Position = PVM * vec4(vertices[y], 1);
    EmitVertex();

    gl_Position = PVM * vec4(vertices[x], 1);
    EmitVertex();
}

vec3 interpolation(vec3 p1, vec3 p2, float valp1, float valp2) {
    float mu;
    vec3 p; 

    mu = (ISO_LEVEL - valp1) / (valp2 - valp1);
    p.x = p1.x + mu * float(p2.x - p1.x);
    p.y = p1.y + mu * float(p2.y - p1.y);
    p.z = p1.z + mu * float(p2.z - p1.z);

    return vec3(p);
}

void main() {
    int start = -1;
    int end = 1;
    float mul = 0.5;

    ivec3 tex_size = textureSize(grid, 0);

    for (float x = start; x < end; x += mul) {
        for (float y = start; y < end; y += mul) {
            for (float z = start; z < end; z += mul) {

                int cubeindex = 0;

                corners[0] = vec3(x, y, z);
                corners[1] = vec3(x + mul, y, z);
                corners[2] = vec3(x + mul, y, z + mul);
                corners[3] = vec3(x, y, z + mul);
                corners[4] = vec3(x, y + mul, z);
                corners[5] = vec3(x + mul, y + mul, z);
                corners[6] = vec3(x + mul, y + mul, z + mul);
                corners[7] = vec3(x, y + mul, z + mul);

                for (int i = 0; i < corners.length; i++) {
                    //densities[i] = texelFetch(grid, ivec3(vec3(corners[i]) * GridSize/pow(2.0, level)), level).r;
                    vec3 aux = (corners[i] + 1) * 0.5;
                    densities[i] = texture(grid, aux).r;
                }

                //the |= operator performs a bitwise logical OR operation on integral operands
                if (densities[0] > ISO_LEVEL) cubeindex |= 1;
                if (densities[1] > ISO_LEVEL) cubeindex |= 2;
                if (densities[2] > ISO_LEVEL) cubeindex |= 4;
                if (densities[3] > ISO_LEVEL) cubeindex |= 8;
                if (densities[4] > ISO_LEVEL) cubeindex |= 16;
                if (densities[5] > ISO_LEVEL) cubeindex |= 32;
                if (densities[6] > ISO_LEVEL) cubeindex |= 64;
                if (densities[7] > ISO_LEVEL) cubeindex |= 128;
            
                //no triangles if it is surrounded by air or surrounded by blocks
                if (EDGES[cubeindex] == 0 || EDGES[cubeindex] == 255) continue;
                
                //find the vertices where the surface intersects the cube
                //the & operator performs a bitwise logical AND operation on integral operands
                if ((EDGES[cubeindex] & 1) == 1)
                    vertices[0]  = interpolation(corners[0], corners[1], densities[0], densities[1]);
                if ((EDGES[cubeindex] & 2) == 2)
                    vertices[1]  = interpolation(corners[1], corners[2], densities[1], densities[2]);
                if ((EDGES[cubeindex] & 4) == 4)
                    vertices[2]  = interpolation(corners[2], corners[3], densities[2], densities[3]);
                if ((EDGES[cubeindex] & 8) == 8)
                    vertices[3]  = interpolation(corners[3], corners[0], densities[3], densities[0]);
                if ((EDGES[cubeindex] & 16) == 16)
                    vertices[4]  = interpolation(corners[4], corners[5], densities[4], densities[5]);
                if ((EDGES[cubeindex] & 32) == 32)
                    vertices[5]  = interpolation(corners[5], corners[6], densities[5], densities[6]);
                if ((EDGES[cubeindex] & 64) == 64)
                    vertices[6]  = interpolation(corners[6], corners[7], densities[6], densities[7]);
                if ((EDGES[cubeindex] & 128) == 128)
                    vertices[7]  = interpolation(corners[7], corners[4], densities[7], densities[4]);
                if ((EDGES[cubeindex] & 256) == 256)
                    vertices[8]  = interpolation(corners[0], corners[4], densities[0], densities[4]);
                if ((EDGES[cubeindex] & 512) == 512)
                    vertices[9]  = interpolation(corners[1], corners[5], densities[1], densities[5]);
                if ((EDGES[cubeindex] & 1024) == 1024)
                    vertices[10] = interpolation(corners[2], corners[6], densities[2], densities[6]);
                if ((EDGES[cubeindex] & 2048) == 2048)
                    vertices[11] = interpolation(corners[3], corners[7], densities[3], densities[7]);
                
                switch (cubeindex) {

                    case 0:
                        break;

                    case 1:
                        emit_triangle(0, 8, 3);
                        break;

                    case 2:
                        emit_triangle(0, 1, 9);
                        break;

                    case 3:
                        emit_triangle(1, 8, 3);
                        emit_triangle(9, 8, 1);
                        break;

                    case 4:
                        emit_triangle(1, 2, 10);
                        break;

                    case 5:
                        emit_triangle(0, 8, 3);
                        emit_triangle(1, 2, 10);
                        break;

                    case 6:
                        emit_triangle(9, 2, 10);
                        emit_triangle(0, 2, 9);
                        break;

                    case 7:
                        emit_triangle(2, 8, 3);
                        emit_triangle(2, 10, 8);
                        emit_triangle(10, 9, 8);
                        break;

                    case 8:
                        emit_triangle(3, 11, 2);
                        break;

                    case 9:
                        emit_triangle(0, 11, 2);
                        emit_triangle(8, 11, 0);
                        break;

                    case 10:
                        emit_triangle(1, 9, 0);
                        emit_triangle(2, 3, 11);
                        break;

                    case 11:
                        emit_triangle(1, 11, 2);
                        emit_triangle(1, 9, 11);
                        emit_triangle(9, 8, 11);
                        break;

                    case 12:
                        emit_triangle(3, 10, 1);
                        emit_triangle(11, 10, 3);
                        break;

                    case 13:
                        emit_triangle(0, 10, 1);
                        emit_triangle(0, 8, 10);
                        emit_triangle(8, 11, 10);
                        break;

                    case 14:
                        emit_triangle(3, 9, 0);
                        emit_triangle(3, 11, 9);
                        emit_triangle(11, 10, 9);
                        break;

                    case 15:
                        emit_triangle(9, 8, 10);
                        emit_triangle(10, 8, 11);
                        break;

                    case 16:
                        emit_triangle(4, 7, 8);
                        break;

                    case 17:
                        emit_triangle(4, 3, 0);
                        emit_triangle(7, 3, 4);
                        break;

                    case 18:
                        emit_triangle(0, 1, 9);
                        emit_triangle(8, 4, 7);
                        break;

                    case 19:
                        emit_triangle(4, 1, 9);
                        emit_triangle(4, 7, 1);
                        emit_triangle(7, 3, 1);
                        break;

                    case 20:
                        emit_triangle(1, 2, 10);
                        emit_triangle(8, 4, 7);
                        break;

                    case 21:
                        emit_triangle(3, 4, 7);
                        emit_triangle(3, 0, 4);
                        emit_triangle(1, 2, 10);
                        break;

                    case 22:
                        emit_triangle(9, 2, 10);
                        emit_triangle(9, 0, 2);
                        emit_triangle(8, 4, 7);
                        break;

                    case 23:
                        emit_triangle(2, 10, 9);
                        emit_triangle(2, 9, 7);
                        emit_triangle(2, 7, 3);
                        emit_triangle(7, 9, 4);
                        break;

                    case 24:
                        emit_triangle(8, 4, 7);
                        emit_triangle(3, 11, 2);
                        break;

                    case 25:
                        emit_triangle(11, 4, 7);
                        emit_triangle(11, 2, 4);
                        emit_triangle(2, 0, 4);
                        break;

                    case 26:
                        emit_triangle(9, 0, 1);
                        emit_triangle(8, 4, 7);
                        emit_triangle(2, 3, 11);
                        break;

                    case 27:
                        emit_triangle(4, 7, 11);
                        emit_triangle(9, 4, 11);
                        emit_triangle(9, 11, 2);
                        emit_triangle(9, 2, 1);
                        break;

                    case 28:
                        emit_triangle(3, 10, 1);
                        emit_triangle(3, 11, 10);
                        emit_triangle(7, 8, 4);
                        break;

                    case 29:
                        emit_triangle(1, 11, 10);
                        emit_triangle(1, 4, 11);
                        emit_triangle(1, 0, 4);
                        emit_triangle(7, 11, 4);
                        break;

                    case 30:
                        emit_triangle(4, 7, 8);
                        emit_triangle(9, 0, 11);
                        emit_triangle(9, 11, 10);
                        emit_triangle(11, 0, 3);
                        break;

                    case 31:
                        emit_triangle(4, 7, 11);
                        emit_triangle(4, 11, 9);
                        emit_triangle(9, 11, 10);
                        break;

                    case 32:
                        emit_triangle(9, 5, 4);
                        break;

                    case 33:
                        emit_triangle(9, 5, 4);
                        emit_triangle(0, 8, 3);
                        break;

                    case 34:
                        emit_triangle(0, 5, 4);
                        emit_triangle(1, 5, 0);
                        break;

                    case 35:
                        emit_triangle(8, 5, 4);
                        emit_triangle(8, 3, 5);
                        emit_triangle(3, 1, 5);
                        break;

                    case 36:
                        emit_triangle(1, 2, 10);
                        emit_triangle(9, 5, 4);
                        break;

                    case 37:
                        emit_triangle(3, 0, 8);
                        emit_triangle(1, 2, 10);
                        emit_triangle(4, 9, 5);
                        break;

                    case 38:
                        emit_triangle(5, 2, 10);
                        emit_triangle(5, 4, 2);
                        emit_triangle(4, 0, 2);
                        break;

                    case 39:
                        emit_triangle(2, 10, 5);
                        emit_triangle(3, 2, 5);
                        emit_triangle(3, 5, 4);
                        emit_triangle(3, 4, 8);
                        break;

                    case 40:
                        emit_triangle(9, 5, 4);
                        emit_triangle(2, 3, 11);
                        break;

                    case 41:
                        emit_triangle(0, 11, 2);
                        emit_triangle(0, 8, 11);
                        emit_triangle(4, 9, 5);
                        break;

                    case 42:
                        emit_triangle(0, 5, 4);
                        emit_triangle(0, 1, 5);
                        emit_triangle(2, 3, 11);
                        break;

                    case 43:
                        emit_triangle(2, 1, 5);
                        emit_triangle(2, 5, 8);
                        emit_triangle(2, 8, 11);
                        emit_triangle(4, 8, 5);
                        break;

                    case 44:
                        emit_triangle(10, 3, 11);
                        emit_triangle(10, 1, 3);
                        emit_triangle(9, 5, 4);
                        break;

                    case 45:
                        emit_triangle(4, 9, 5);
                        emit_triangle(0, 8, 1);
                        emit_triangle(8, 10, 1);
                        emit_triangle(8, 11, 10);
                        break;

                    case 46:
                        emit_triangle(5, 4, 0);
                        emit_triangle(5, 0, 11);
                        emit_triangle(5, 11, 10);
                        emit_triangle(11, 0, 3);
                        break;

                    case 47:
                        emit_triangle(5, 4, 8);
                        emit_triangle(5, 8, 10);
                        emit_triangle(10, 8, 11);
                        break;

                    case 48:
                        emit_triangle(9, 7, 8);
                        emit_triangle(5, 7, 9);
                        break;

                    case 49:
                        emit_triangle(9, 3, 0);
                        emit_triangle(9, 5, 3);
                        emit_triangle(5, 7, 3);
                        break;

                    case 50:
                        emit_triangle(0, 7, 8);
                        emit_triangle(0, 1, 7);
                        emit_triangle(1, 5, 7);
                        break;

                    case 51:
                        emit_triangle(1, 5, 3);
                        emit_triangle(3, 5, 7);
                        break;

                    case 52:
                        emit_triangle(9, 7, 8);
                        emit_triangle(9, 5, 7);
                        emit_triangle(10, 1, 2);
                        break;

                    case 53:
                        emit_triangle(10, 1, 2);
                        emit_triangle(9, 5, 0);
                        emit_triangle(5, 3, 0);
                        emit_triangle(5, 7, 3);
                        break;

                    case 54:
                        emit_triangle(8, 0, 2);
                        emit_triangle(8, 2, 5);
                        emit_triangle(8, 5, 7);
                        emit_triangle(10, 5, 2);
                        break;

                    case 55:
                        emit_triangle(2, 10, 5);
                        emit_triangle(2, 5, 3);
                        emit_triangle(3, 5, 7);
                        break;

                    case 56:
                        emit_triangle(7, 9, 5);
                        emit_triangle(7, 8, 9);
                        emit_triangle(3, 11, 2);
                        break;

                    case 57:
                        emit_triangle(9, 5, 7);
                        emit_triangle(9, 7, 2);
                        emit_triangle(9, 2, 0);
                        emit_triangle(2, 7, 11);
                        break;

                    case 58:
                        emit_triangle(2, 3, 11);
                        emit_triangle(0, 1, 8);
                        emit_triangle(1, 7, 8);
                        emit_triangle(1, 5, 7);
                        break;

                    case 59:
                        emit_triangle(11, 2, 1);
                        emit_triangle(11, 1, 7);
                        emit_triangle(7, 1, 5);
                        break;

                    case 60:
                        emit_triangle(9, 5, 8);
                        emit_triangle(8, 5, 7);
                        emit_triangle(10, 1, 3);
                        emit_triangle(10, 3, 11);
                        break;

                    case 61:
                        emit_triangle(5, 7, 0);
                        emit_triangle(5, 0, 9);
                        emit_triangle(7, 11, 0);
                        emit_triangle(1, 0, 10);
                        emit_triangle(11, 10, 0);
                        break;

                    case 62:
                        emit_triangle(11, 10, 0);
                        emit_triangle(11, 0, 3);
                        emit_triangle(10, 5, 0);
                        emit_triangle(8, 0, 7);
                        emit_triangle(5, 7, 0);
                        break;

                    case 63:
                        emit_triangle(11, 10, 5);
                        emit_triangle(7, 11, 5);
                        break;

                    case 64:
                        emit_triangle(10, 6, 5);
                        break;

                    case 65:
                        emit_triangle(0, 8, 3);
                        emit_triangle(5, 10, 6);
                        break;

                    case 66:
                        emit_triangle(9, 0, 1);
                        emit_triangle(5, 10, 6);
                        break;

                    case 67:
                        emit_triangle(1, 8, 3);
                        emit_triangle(1, 9, 8);
                        emit_triangle(5, 10, 6);
                        break;

                    case 68:
                        emit_triangle(1, 6, 5);
                        emit_triangle(2, 6, 1);
                        break;

                    case 69:
                        emit_triangle(1, 6, 5);
                        emit_triangle(1, 2, 6);
                        emit_triangle(3, 0, 8);
                        break;

                    case 70:
                        emit_triangle(9, 6, 5);
                        emit_triangle(9, 0, 6);
                        emit_triangle(0, 2, 6);
                        break;

                    case 71:
                        emit_triangle(5, 9, 8);
                        emit_triangle(5, 8, 2);
                        emit_triangle(5, 2, 6);
                        emit_triangle(3, 2, 8);
                        break;

                    case 72:
                        emit_triangle(2, 3, 11);
                        emit_triangle(10, 6, 5);
                        break;

                    case 73:
                        emit_triangle(11, 0, 8);
                        emit_triangle(11, 2, 0);
                        emit_triangle(10, 6, 5);
                        break;

                    case 74:
                        emit_triangle(0, 1, 9);
                        emit_triangle(2, 3, 11);
                        emit_triangle(5, 10, 6);
                        break;

                    case 75:
                        emit_triangle(5, 10, 6);
                        emit_triangle(1, 9, 2);
                        emit_triangle(9, 11, 2);
                        emit_triangle(9, 8, 11);
                        break;

                    case 76:
                        emit_triangle(6, 3, 11);
                        emit_triangle(6, 5, 3);
                        emit_triangle(5, 1, 3);
                        break;

                    case 77:
                        emit_triangle(0, 8, 11);
                        emit_triangle(0, 11, 5);
                        emit_triangle(0, 5, 1);
                        emit_triangle(5, 11, 6);
                        break;

                    case 78:
                        emit_triangle(3, 11, 6);
                        emit_triangle(0, 3, 6);
                        emit_triangle(0, 6, 5);
                        emit_triangle(0, 5, 9);
                        break;

                    case 79:
                        emit_triangle(6, 5, 9);
                        emit_triangle(6, 9, 11);
                        emit_triangle(11, 9, 8);
                        break;

                    case 80:
                        emit_triangle(5, 10, 6);
                        emit_triangle(4, 7, 8);
                        break;

                    case 81:
                        emit_triangle(4, 3, 0);
                        emit_triangle(4, 7, 3);
                        emit_triangle(6, 5, 10);
                        break;

                    case 82:
                        emit_triangle(1, 9, 0);
                        emit_triangle(5, 10, 6);
                        emit_triangle(8, 4, 7);
                        break;

                    case 83:
                        emit_triangle(10, 6, 5);
                        emit_triangle(1, 9, 7);
                        emit_triangle(1, 7, 3);
                        emit_triangle(7, 9, 4);
                        break;

                    case 84:
                        emit_triangle(6, 1, 2);
                        emit_triangle(6, 5, 1);
                        emit_triangle(4, 7, 8);
                        break;

                    case 85:
                        emit_triangle(1, 2, 5);
                        emit_triangle(5, 2, 6);
                        emit_triangle(3, 0, 4);
                        emit_triangle(3, 4, 7);
                        break;

                    case 86:
                        emit_triangle(8, 4, 7);
                        emit_triangle(9, 0, 5);
                        emit_triangle(0, 6, 5);
                        emit_triangle(0, 2, 6);
                        break;

                    case 87:
                        emit_triangle(7, 3, 9);
                        emit_triangle(7, 9, 4);
                        emit_triangle(3, 2, 9);
                        emit_triangle(5, 9, 6);
                        emit_triangle(2, 6, 9);
                        break;

                    case 88:
                        emit_triangle(3, 11, 2);
                        emit_triangle(7, 8, 4);
                        emit_triangle(10, 6, 5);
                        break;

                    case 89:
                        emit_triangle(5, 10, 6);
                        emit_triangle(4, 7, 2);
                        emit_triangle(4, 2, 0);
                        emit_triangle(2, 7, 11);
                        break;

                    case 90:
                        emit_triangle(0, 1, 9);
                        emit_triangle(4, 7, 8);
                        emit_triangle(2, 3, 11);
                        emit_triangle(5, 10, 6);
                        break;

                    case 91:
                        emit_triangle(9, 2, 1);
                        emit_triangle(9, 11, 2);
                        emit_triangle(9, 4, 11);
                        emit_triangle(7, 11, 4);
                        emit_triangle(5, 10, 6);
                        break;

                    case 92:
                        emit_triangle(8, 4, 7);
                        emit_triangle(3, 11, 5);
                        emit_triangle(3, 5, 1);
                        emit_triangle(5, 11, 6);
                        break;

                    case 93:
                        emit_triangle(5, 1, 11);
                        emit_triangle(5, 11, 6);
                        emit_triangle(1, 0, 11);
                        emit_triangle(7, 11, 4);
                        emit_triangle(0, 4, 11);
                        break;

                    case 94:
                        emit_triangle(0, 5, 9);
                        emit_triangle(0, 6, 5);
                        emit_triangle(0, 3, 6);
                        emit_triangle(11, 6, 3);
                        emit_triangle(8, 4, 7);
                        break;

                    case 95:
                        emit_triangle(6, 5, 9);
                        emit_triangle(6, 9, 11);
                        emit_triangle(4, 7, 9);
                        emit_triangle(7, 11, 9);
                        break;

                    case 96:
                        emit_triangle(10, 4, 9);
                        emit_triangle(6, 4, 10);
                        break;

                    case 97:
                        emit_triangle(4, 10, 6);
                        emit_triangle(4, 9, 10);
                        emit_triangle(0, 8, 3);
                        break;

                    case 98:
                        emit_triangle(10, 0, 1);
                        emit_triangle(10, 6, 0);
                        emit_triangle(6, 4, 0);
                        break;

                    case 99:
                        emit_triangle(8, 3, 1);
                        emit_triangle(8, 1, 6);
                        emit_triangle(8, 6, 4);
                        emit_triangle(6, 1, 10);
                        break;

                    case 100:
                        emit_triangle(1, 4, 9);
                        emit_triangle(1, 2, 4);
                        emit_triangle(2, 6, 4);
                        break;

                    case 101:
                        emit_triangle(3, 0, 8);
                        emit_triangle(1, 2, 9);
                        emit_triangle(2, 4, 9);
                        emit_triangle(2, 6, 4);
                        break;

                    case 102:
                        emit_triangle(0, 2, 4);
                        emit_triangle(4, 2, 6);
                        break;

                    case 103:
                        emit_triangle(8, 3, 2);
                        emit_triangle(8, 2, 4);
                        emit_triangle(4, 2, 6);
                        break;

                    case 104:
                        emit_triangle(10, 4, 9);
                        emit_triangle(10, 6, 4);
                        emit_triangle(11, 2, 3);
                        break;

                    case 105:
                        emit_triangle(0, 8, 2);
                        emit_triangle(2, 8, 11);
                        emit_triangle(4, 9, 10);
                        emit_triangle(4, 10, 6);
                        break;

                    case 106:
                        emit_triangle(3, 11, 2);
                        emit_triangle(0, 1, 6);
                        emit_triangle(0, 6, 4);
                        emit_triangle(6, 1, 10);
                        break;

                    case 107:
                        emit_triangle(6, 4, 1);
                        emit_triangle(6, 1, 10);
                        emit_triangle(4, 8, 1);
                        emit_triangle(2, 1, 11);
                        emit_triangle(8, 11, 1);
                        break;

                    case 108:
                        emit_triangle(9, 6, 4);
                        emit_triangle(9, 3, 6);
                        emit_triangle(9, 1, 3);
                        emit_triangle(11, 6, 3);
                        break;

                    case 109:
                        emit_triangle(8, 11, 1);
                        emit_triangle(8, 1, 0);
                        emit_triangle(11, 6, 1);
                        emit_triangle(9, 1, 4);
                        emit_triangle(6, 4, 1);
                        break;

                    case 110:
                        emit_triangle(3, 11, 6);
                        emit_triangle(3, 6, 0);
                        emit_triangle(0, 6, 4);
                        break;

                    case 111:
                        emit_triangle(6, 4, 8);
                        emit_triangle(11, 6, 8);
                        break;

                    case 112:
                        emit_triangle(7, 10, 6);
                        emit_triangle(7, 8, 10);
                        emit_triangle(8, 9, 10);
                        break;

                    case 113:
                        emit_triangle(0, 7, 3);
                        emit_triangle(0, 10, 7);
                        emit_triangle(0, 9, 10);
                        emit_triangle(6, 7, 10);
                        break;

                    case 114:
                        emit_triangle(10, 6, 7);
                        emit_triangle(1, 10, 7);
                        emit_triangle(1, 7, 8);
                        emit_triangle(1, 8, 0);
                        break;

                    case 115:
                        emit_triangle(10, 6, 7);
                        emit_triangle(10, 7, 1);
                        emit_triangle(1, 7, 3);
                        break;

                    case 116:
                        emit_triangle(1, 2, 6);
                        emit_triangle(1, 6, 8);
                        emit_triangle(1, 8, 9);
                        emit_triangle(8, 6, 7);
                        break;

                    case 117:
                        emit_triangle(2, 6, 9);
                        emit_triangle(2, 9, 1);
                        emit_triangle(6, 7, 9);
                        emit_triangle(0, 9, 3);
                        emit_triangle(7, 3, 9);
                        break;

                    case 118:
                        emit_triangle(7, 8, 0);
                        emit_triangle(7, 0, 6);
                        emit_triangle(6, 0, 2);
                        break;

                    case 119:
                        emit_triangle(7, 3, 2);
                        emit_triangle(6, 7, 2);
                        break;

                    case 120:
                        emit_triangle(2, 3, 11);
                        emit_triangle(10, 6, 8);
                        emit_triangle(10, 8, 9);
                        emit_triangle(8, 6, 7);
                        break;

                    case 121:
                        emit_triangle(2, 0, 7);
                        emit_triangle(2, 7, 11);
                        emit_triangle(0, 9, 7);
                        emit_triangle(6, 7, 10);
                        emit_triangle(9, 10, 7);
                        break;

                    case 122:
                        emit_triangle(1, 8, 0);
                        emit_triangle(1, 7, 8);
                        emit_triangle(1, 10, 7);
                        emit_triangle(6, 7, 10);
                        emit_triangle(2, 3, 11);
                        break;

                    case 123:
                        emit_triangle(11, 2, 1);
                        emit_triangle(11, 1, 7);
                        emit_triangle(10, 6, 1);
                        emit_triangle(6, 7, 1);
                        break;

                    case 124:
                        emit_triangle(8, 9, 6);
                        emit_triangle(8, 6, 7);
                        emit_triangle(9, 1, 6);
                        emit_triangle(11, 6, 3);
                        emit_triangle(1, 3, 6);
                        break;

                    case 125:
                        emit_triangle(0, 9, 1);
                        emit_triangle(11, 6, 7);
                        break;

                    case 126:
                        emit_triangle(7, 8, 0);
                        emit_triangle(7, 0, 6);
                        emit_triangle(3, 11, 0);
                        emit_triangle(11, 6, 0);
                        break;

                    case 127:
                        emit_triangle(7, 11, 6);
                        break;

                    case 128:
                        emit_triangle(7, 6, 11);
                        break;

                    case 129:
                        emit_triangle(3, 0, 8);
                        emit_triangle(11, 7, 6);
                        break;

                    case 130:
                        emit_triangle(0, 1, 9);
                        emit_triangle(11, 7, 6);
                        break;

                    case 131:
                        emit_triangle(8, 1, 9);
                        emit_triangle(8, 3, 1);
                        emit_triangle(11, 7, 6);
                        break;

                    case 132:
                        emit_triangle(10, 1, 2);
                        emit_triangle(6, 11, 7);
                        break;

                    case 133:
                        emit_triangle(1, 2, 10);
                        emit_triangle(3, 0, 8);
                        emit_triangle(6, 11, 7);
                        break;

                    case 134:
                        emit_triangle(2, 9, 0);
                        emit_triangle(2, 10, 9);
                        emit_triangle(6, 11, 7);
                        break;

                    case 135:
                        emit_triangle(6, 11, 7);
                        emit_triangle(2, 10, 3);
                        emit_triangle(10, 8, 3);
                        emit_triangle(10, 9, 8);
                        break;

                    case 136:
                        emit_triangle(7, 2, 3);
                        emit_triangle(6, 2, 7);
                        break;

                    case 137:
                        emit_triangle(7, 0, 8);
                        emit_triangle(7, 6, 0);
                        emit_triangle(6, 2, 0);
                        break;

                    case 138:
                        emit_triangle(2, 7, 6);
                        emit_triangle(2, 3, 7);
                        emit_triangle(0, 1, 9);
                        break;

                    case 139:
                        emit_triangle(1, 6, 2);
                        emit_triangle(1, 8, 6);
                        emit_triangle(1, 9, 8);
                        emit_triangle(8, 7, 6);
                        break;

                    case 140:
                        emit_triangle(10, 7, 6);
                        emit_triangle(10, 1, 7);
                        emit_triangle(1, 3, 7);
                        break;

                    case 141:
                        emit_triangle(10, 7, 6);
                        emit_triangle(1, 7, 10);
                        emit_triangle(1, 8, 7);
                        emit_triangle(1, 0, 8);
                        break;

                    case 142:
                        emit_triangle(0, 3, 7);
                        emit_triangle(0, 7, 10);
                        emit_triangle(0, 10, 9);
                        emit_triangle(6, 10, 7);
                        break;

                    case 143:
                        emit_triangle(7, 6, 10);
                        emit_triangle(7, 10, 8);
                        emit_triangle(8, 10, 9);
                        break;

                    case 144:
                        emit_triangle(6, 8, 4);
                        emit_triangle(11, 8, 6);
                        break;

                    case 145:
                        emit_triangle(3, 6, 11);
                        emit_triangle(3, 0, 6);
                        emit_triangle(0, 4, 6);
                        break;

                    case 146:
                        emit_triangle(8, 6, 11);
                        emit_triangle(8, 4, 6);
                        emit_triangle(9, 0, 1);
                        break;

                    case 147:
                        emit_triangle(9, 4, 6);
                        emit_triangle(9, 6, 3);
                        emit_triangle(9, 3, 1);
                        emit_triangle(11, 3, 6);
                        break;

                    case 148:
                        emit_triangle(6, 8, 4);
                        emit_triangle(6, 11, 8);
                        emit_triangle(2, 10, 1);
                        break;

                    case 149:
                        emit_triangle(1, 2, 10);
                        emit_triangle(3, 0, 11);
                        emit_triangle(0, 6, 11);
                        emit_triangle(0, 4, 6);
                        break;

                    case 150:
                        emit_triangle(4, 11, 8);
                        emit_triangle(4, 6, 11);
                        emit_triangle(0, 2, 9);
                        emit_triangle(2, 10, 9);
                        break;

                    case 151:
                        emit_triangle(10, 9, 3);
                        emit_triangle(10, 3, 2);
                        emit_triangle(9, 4, 3);
                        emit_triangle(11, 3, 6);
                        emit_triangle(4, 6, 3);
                        break;

                    case 152:
                        emit_triangle(8, 2, 3);
                        emit_triangle(8, 4, 2);
                        emit_triangle(4, 6, 2);
                        break;

                    case 153:
                        emit_triangle(0, 4, 2);
                        emit_triangle(4, 6, 2);
                        break;

                    case 154:
                        emit_triangle(1, 9, 0);
                        emit_triangle(2, 3, 4);
                        emit_triangle(2, 4, 6);
                        emit_triangle(4, 3, 8);
                        break;

                    case 155:
                        emit_triangle(1, 9, 4);
                        emit_triangle(1, 4, 2);
                        emit_triangle(2, 4, 6);
                        break;

                    case 156:
                        emit_triangle(8, 1, 3);
                        emit_triangle(8, 6, 1);
                        emit_triangle(8, 4, 6);
                        emit_triangle(6, 10, 1);
                        break;

                    case 157:
                        emit_triangle(10, 1, 0);
                        emit_triangle(10, 0, 6);
                        emit_triangle(6, 0, 4);
                        break;

                    case 158:
                        emit_triangle(4, 6, 3);
                        emit_triangle(4, 3, 8);
                        emit_triangle(6, 10, 3);
                        emit_triangle(0, 3, 9);
                        emit_triangle(10, 9, 3);
                        break;

                    case 159:
                        emit_triangle(10, 9, 4);
                        emit_triangle(6, 10, 4);
                        break;

                    case 160:
                        emit_triangle(4, 9, 5);
                        emit_triangle(7, 6, 11);
                        break;

                    case 161:
                        emit_triangle(0, 8, 3);
                        emit_triangle(4, 9, 5);
                        emit_triangle(11, 7, 6);
                        break;

                    case 162:
                        emit_triangle(5, 0, 1);
                        emit_triangle(5, 4, 0);
                        emit_triangle(7, 6, 11);
                        break;

                    case 163:
                        emit_triangle(11, 7, 6);
                        emit_triangle(8, 3, 4);
                        emit_triangle(3, 5, 4);
                        emit_triangle(3, 1, 5);
                        break;

                    case 164:
                        emit_triangle(9, 5, 4);
                        emit_triangle(10, 1, 2);
                        emit_triangle(7, 6, 11);
                        break;

                    case 165:
                        emit_triangle(6, 11, 7);
                        emit_triangle(1, 2, 10);
                        emit_triangle(0, 8, 3);
                        emit_triangle(4, 9, 5);
                        break;

                    case 166:
                        emit_triangle(7, 6, 11);
                        emit_triangle(5, 4, 10);
                        emit_triangle(4, 2, 10);
                        emit_triangle(4, 0, 2);
                        break;

                    case 167:
                        emit_triangle(3, 4, 8);
                        emit_triangle(3, 5, 4);
                        emit_triangle(3, 2, 5);
                        emit_triangle(10, 5, 2);
                        emit_triangle(11, 7, 6);
                        break;

                    case 168:
                        emit_triangle(7, 2, 3);
                        emit_triangle(7, 6, 2);
                        emit_triangle(5, 4, 9);
                        break;

                    case 169:
                        emit_triangle(9, 5, 4);
                        emit_triangle(0, 8, 6);
                        emit_triangle(0, 6, 2);
                        emit_triangle(6, 8, 7);
                        break;

                    case 170:
                        emit_triangle(3, 6, 2);
                        emit_triangle(3, 7, 6);
                        emit_triangle(1, 5, 0);
                        emit_triangle(5, 4, 0);
                        break;

                    case 171:
                        emit_triangle(6, 2, 8);
                        emit_triangle(6, 8, 7);
                        emit_triangle(2, 1, 8);
                        emit_triangle(4, 8, 5);
                        emit_triangle(1, 5, 8);
                        break;

                    case 172:
                        emit_triangle(9, 5, 4);
                        emit_triangle(10, 1, 6);
                        emit_triangle(1, 7, 6);
                        emit_triangle(1, 3, 7);
                        break;

                    case 173:
                        emit_triangle(1, 6, 10);
                        emit_triangle(1, 7, 6);
                        emit_triangle(1, 0, 7);
                        emit_triangle(8, 7, 0);
                        emit_triangle(9, 5, 4);
                        break;

                    case 174:
                        emit_triangle(4, 0, 10);
                        emit_triangle(4, 10, 5);
                        emit_triangle(0, 3, 10);
                        emit_triangle(6, 10, 7);
                        emit_triangle(3, 7, 10);
                        break;

                    case 175:
                        emit_triangle(7, 6, 10);
                        emit_triangle(7, 10, 8);
                        emit_triangle(5, 4, 10);
                        emit_triangle(4, 8, 10);
                        break;

                    case 176:
                        emit_triangle(6, 9, 5);
                        emit_triangle(6, 11, 9);
                        emit_triangle(11, 8, 9);
                        break;

                    case 177:
                        emit_triangle(3, 6, 11);
                        emit_triangle(0, 6, 3);
                        emit_triangle(0, 5, 6);
                        emit_triangle(0, 9, 5);
                        break;

                    case 178:
                        emit_triangle(0, 11, 8);
                        emit_triangle(0, 5, 11);
                        emit_triangle(0, 1, 5);
                        emit_triangle(5, 6, 11);
                        break;

                    case 179:
                        emit_triangle(6, 11, 3);
                        emit_triangle(6, 3, 5);
                        emit_triangle(5, 3, 1);
                        break;

                    case 180:
                        emit_triangle(1, 2, 10);
                        emit_triangle(9, 5, 11);
                        emit_triangle(9, 11, 8);
                        emit_triangle(11, 5, 6);
                        break;

                    case 181:
                        emit_triangle(0, 11, 3);
                        emit_triangle(0, 6, 11);
                        emit_triangle(0, 9, 6);
                        emit_triangle(5, 6, 9);
                        emit_triangle(1, 2, 10);
                        break;

                    case 182:
                        emit_triangle(11, 8, 5);
                        emit_triangle(11, 5, 6);
                        emit_triangle(8, 0, 5);
                        emit_triangle(10, 5, 2);
                        emit_triangle(0, 2, 5);
                        break;

                    case 183:
                        emit_triangle(6, 11, 3);
                        emit_triangle(6, 3, 5);
                        emit_triangle(2, 10, 3);
                        emit_triangle(10, 5, 3);
                        break;

                    case 184:
                        emit_triangle(5, 8, 9);
                        emit_triangle(5, 2, 8);
                        emit_triangle(5, 6, 2);
                        emit_triangle(3, 8, 2);
                        break;

                    case 185:
                        emit_triangle(9, 5, 6);
                        emit_triangle(9, 6, 0);
                        emit_triangle(0, 6, 2);
                        break;

                    case 186:
                        emit_triangle(1, 5, 8);
                        emit_triangle(1, 8, 0);
                        emit_triangle(5, 6, 8);
                        emit_triangle(3, 8, 2);
                        emit_triangle(6, 2, 8);
                        break;

                    case 187:
                        emit_triangle(1, 5, 6);
                        emit_triangle(2, 1, 6);
                        break;

                    case 188:
                        emit_triangle(1, 3, 6);
                        emit_triangle(1, 6, 10);
                        emit_triangle(3, 8, 6);
                        emit_triangle(5, 6, 9);
                        emit_triangle(8, 9, 6);
                        break;

                    case 189:
                        emit_triangle(10, 1, 0);
                        emit_triangle(10, 0, 6);
                        emit_triangle(9, 5, 0);
                        emit_triangle(5, 6, 0);
                        break;

                    case 190:
                        emit_triangle(0, 3, 8);
                        emit_triangle(5, 6, 10);
                        break;

                    case 191:
                        emit_triangle(10, 5, 6);
                        break;

                    case 192:
                        emit_triangle(11, 5, 10);
                        emit_triangle(7, 5, 11);
                        break;

                    case 193:
                        emit_triangle(11, 5, 10);
                        emit_triangle(11, 7, 5);
                        emit_triangle(8, 3, 0);
                        break;

                    case 194:
                        emit_triangle(5, 11, 7);
                        emit_triangle(5, 10, 11);
                        emit_triangle(1, 9, 0);
                        break;

                    case 195:
                        emit_triangle(10, 7, 5);
                        emit_triangle(10, 11, 7);
                        emit_triangle(9, 8, 1);
                        emit_triangle(8, 3, 1);
                        break;

                    case 196:
                        emit_triangle(11, 1, 2);
                        emit_triangle(11, 7, 1);
                        emit_triangle(7, 5, 1);
                        break;

                    case 197:
                        emit_triangle(0, 8, 3);
                        emit_triangle(1, 2, 7);
                        emit_triangle(1, 7, 5);
                        emit_triangle(7, 2, 11);
                        break;

                    case 198:
                        emit_triangle(9, 7, 5);
                        emit_triangle(9, 2, 7);
                        emit_triangle(9, 0, 2);
                        emit_triangle(2, 11, 7);
                        break;

                    case 199:
                        emit_triangle(7, 5, 2);
                        emit_triangle(7, 2, 11);
                        emit_triangle(5, 9, 2);
                        emit_triangle(3, 2, 8);
                        emit_triangle(9, 8, 2);
                        break;

                    case 200:
                        emit_triangle(2, 5, 10);
                        emit_triangle(2, 3, 5);
                        emit_triangle(3, 7, 5);
                        break;

                    case 201:
                        emit_triangle(8, 2, 0);
                        emit_triangle(8, 5, 2);
                        emit_triangle(8, 7, 5);
                        emit_triangle(10, 2, 5);
                        break;

                    case 202:
                        emit_triangle(9, 0, 1);
                        emit_triangle(5, 10, 3);
                        emit_triangle(5, 3, 7);
                        emit_triangle(3, 10, 2);
                        break;

                    case 203:
                        emit_triangle(9, 8, 2);
                        emit_triangle(9, 2, 1);
                        emit_triangle(8, 7, 2);
                        emit_triangle(10, 2, 5);
                        emit_triangle(7, 5, 2);
                        break;

                    case 204:
                        emit_triangle(1, 3, 5);
                        emit_triangle(3, 7, 5);
                        break;

                    case 205:
                        emit_triangle(0, 8, 7);
                        emit_triangle(0, 7, 1);
                        emit_triangle(1, 7, 5);
                        break;

                    case 206:
                        emit_triangle(9, 0, 3);
                        emit_triangle(9, 3, 5);
                        emit_triangle(5, 3, 7);
                        break;

                    case 207:
                        emit_triangle(9, 8, 7);
                        emit_triangle(5, 9, 7);
                        break;

                    case 208:
                        emit_triangle(5, 8, 4);
                        emit_triangle(5, 10, 8);
                        emit_triangle(10, 11, 8);
                        break;

                    case 209:
                        emit_triangle(5, 0, 4);
                        emit_triangle(5, 11, 0);
                        emit_triangle(5, 10, 11);
                        emit_triangle(11, 3, 0);
                        break;

                    case 210:
                        emit_triangle(0, 1, 9);
                        emit_triangle(8, 4, 10);
                        emit_triangle(8, 10, 11);
                        emit_triangle(10, 4, 5);
                        break;

                    case 211:
                        emit_triangle(10, 11, 4);
                        emit_triangle(10, 4, 5);
                        emit_triangle(11, 3, 4);
                        emit_triangle(9, 4, 1);
                        emit_triangle(3, 1, 4);
                        break;

                    case 212:
                        emit_triangle(2, 5, 1);
                        emit_triangle(2, 8, 5);
                        emit_triangle(2, 11, 8);
                        emit_triangle(4, 5, 8);
                        break;

                    case 213:
                        emit_triangle(0, 4, 11);
                        emit_triangle(0, 11, 3);
                        emit_triangle(4, 5, 11);
                        emit_triangle(2, 11, 1);
                        emit_triangle(5, 1, 11);
                        break;

                    case 214:
                        emit_triangle(0, 2, 5);
                        emit_triangle(0, 5, 9);
                        emit_triangle(2, 11, 5);
                        emit_triangle(4, 5, 8);
                        emit_triangle(11, 8, 5);
                        break;

                    case 215:
                        emit_triangle(9, 4, 5);
                        emit_triangle(2, 11, 3);
                        break;

                    case 216:
                        emit_triangle(2, 5, 10);
                        emit_triangle(3, 5, 2);
                        emit_triangle(3, 4, 5);
                        emit_triangle(3, 8, 4);
                        break;

                    case 217:
                        emit_triangle(5, 10, 2);
                        emit_triangle(5, 2, 4);
                        emit_triangle(4, 2, 0);
                        break;

                    case 218:
                        emit_triangle(3, 10, 2);
                        emit_triangle(3, 5, 10);
                        emit_triangle(3, 8, 5);
                        emit_triangle(4, 5, 8);
                        emit_triangle(0, 1, 9);
                        break;

                    case 219:
                        emit_triangle(5, 10, 2);
                        emit_triangle(5, 2, 4);
                        emit_triangle(1, 9, 2);
                        emit_triangle(9, 4, 2);
                        break;

                    case 220:
                        emit_triangle(8, 4, 5);
                        emit_triangle(8, 5, 3);
                        emit_triangle(3, 5, 1);
                        break;

                    case 221:
                        emit_triangle(0, 4, 5);
                        emit_triangle(1, 0, 5);
                        break;

                    case 222:
                        emit_triangle(8, 4, 5);
                        emit_triangle(8, 5, 3);
                        emit_triangle(9, 0, 5);
                        emit_triangle(0, 3, 5);
                        break;

                    case 223:
                        emit_triangle(9, 4, 5);
                        break;

                    case 224:
                        emit_triangle(4, 11, 7);
                        emit_triangle(4, 9, 11);
                        emit_triangle(9, 10, 11);
                        break;

                    case 225:
                        emit_triangle(0, 8, 3);
                        emit_triangle(4, 9, 7);
                        emit_triangle(9, 11, 7);
                        emit_triangle(9, 10, 11);
                        break;

                    case 226:
                        emit_triangle(1, 10, 11);
                        emit_triangle(1, 11, 4);
                        emit_triangle(1, 4, 0);
                        emit_triangle(7, 4, 11);
                        break;

                    case 227:
                        emit_triangle(3, 1, 4);
                        emit_triangle(3, 4, 8);
                        emit_triangle(1, 10, 4);
                        emit_triangle(7, 4, 11);
                        emit_triangle(10, 11, 4);
                        break;

                    case 228:
                        emit_triangle(4, 11, 7);
                        emit_triangle(9, 11, 4);
                        emit_triangle(9, 2, 11);
                        emit_triangle(9, 1, 2);
                        break;

                    case 229:
                        emit_triangle(9, 7, 4);
                        emit_triangle(9, 11, 7);
                        emit_triangle(9, 1, 11);
                        emit_triangle(2, 11, 1);
                        emit_triangle(0, 8, 3);
                        break;

                    case 230:
                        emit_triangle(11, 7, 4);
                        emit_triangle(11, 4, 2);
                        emit_triangle(2, 4, 0);
                        break;

                    case 231:
                        emit_triangle(11, 7, 4);
                        emit_triangle(11, 4, 2);
                        emit_triangle(8, 3, 4);
                        emit_triangle(3, 2, 4);
                        break;

                    case 232:
                        emit_triangle(2, 9, 10);
                        emit_triangle(2, 7, 9);
                        emit_triangle(2, 3, 7);
                        emit_triangle(7, 4, 9);
                        break;

                    case 233:
                        emit_triangle(9, 10, 7);
                        emit_triangle(9, 7, 4);
                        emit_triangle(10, 2, 7);
                        emit_triangle(8, 7, 0);
                        emit_triangle(2, 0, 7);
                        break;

                    case 234:
                        emit_triangle(3, 7, 10);
                        emit_triangle(3, 10, 2);
                        emit_triangle(7, 4, 10);
                        emit_triangle(1, 10, 0);
                        emit_triangle(4, 0, 10);
                        break;

                    case 235:
                        emit_triangle(1, 10, 2);
                        emit_triangle(8, 7, 4);
                        break;

                    case 236:
                        emit_triangle(4, 9, 1);
                        emit_triangle(4, 1, 7);
                        emit_triangle(7, 1, 3);
                        break;

                    case 237:
                        emit_triangle(4, 9, 1);
                        emit_triangle(4, 1, 7);
                        emit_triangle(0, 8, 1);
                        emit_triangle(8, 7, 1);
                        break;

                    case 238:
                        emit_triangle(4, 0, 3);
                        emit_triangle(7, 4, 3);
                        break;

                    case 239:
                        emit_triangle(4, 8, 7);
                        break;

                    case 240:
                        emit_triangle(9, 10, 8);
                        emit_triangle(10, 11, 8);
                        break;

                    case 241:
                        emit_triangle(3, 0, 9);
                        emit_triangle(3, 9, 11);
                        emit_triangle(11, 9, 10);
                        break;

                    case 242:
                        emit_triangle(0, 1, 10);
                        emit_triangle(0, 10, 8);
                        emit_triangle(8, 10, 11);
                        break;

                    case 243:
                        emit_triangle(3, 1, 10);
                        emit_triangle(11, 3, 10);
                        break;

                    case 244:
                        emit_triangle(1, 2, 11);
                        emit_triangle(1, 11, 9);
                        emit_triangle(9, 11, 8);
                        break;

                    case 245:
                        emit_triangle(3, 0, 9);
                        emit_triangle(3, 9, 11);
                        emit_triangle(1, 2, 9);
                        emit_triangle(2, 11, 9);
                        break;

                    case 246:
                        emit_triangle(0, 2, 11);
                        emit_triangle(8, 0, 11);
                        break;

                    case 247:
                        emit_triangle(3, 2, 11);
                        break;

                    case 248:
                        emit_triangle(2, 3, 8);
                        emit_triangle(2, 8, 10);
                        emit_triangle(10, 8, 9);
                        break;

                    case 249:
                        emit_triangle(9, 10, 2);
                        emit_triangle(0, 9, 2);
                        break;

                    case 250:
                        emit_triangle(2, 3, 8);
                        emit_triangle(2, 8, 10);
                        emit_triangle(0, 1, 8);
                        emit_triangle(1, 10, 8);
                        break;

                    case 251:
                        emit_triangle(1, 10, 2);
                        break;

                    case 252:
                        emit_triangle(1, 3, 8);
                        emit_triangle(9, 1, 8);
                        break;

                    case 253:
                        emit_triangle(0, 9, 1);
                        break;

                    case 254:
                        emit_triangle(0, 3, 8);
                        break;

                    case 255:
                        break;

                }

                /*
                for (int i = 0; i < 5; i++) {

                    ivec3 aux = TRIANGLES[cubeindex][i];
                    if (aux.x == -1) break;

                    gl_Position = PVM * vec4(vertices[aux.z], 1);
                    EmitVertex();

                    gl_Position = PVM * vec4(vertices[aux.y], 1);
                    EmitVertex();

                    gl_Position = PVM * vec4(vertices[aux.x], 1);
                    EmitVertex();
                    
                    EndPrimitive();
                }*/
            }
        }
    }

    
}