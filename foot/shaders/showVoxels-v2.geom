#version 440

/*
https://pastebin.com/DQ4Xjn7t
*/

layout(points) in;
layout(triangle_strip, max_vertices = 256) out;

/*
layout(binding = 1) buffer edgesBuffer {
    int EDGES[256];
};*/

layout(std140, binding = 2) buffer triangles {
    int TRIANGLES[256][16];
};

uniform mat4 PVM;
uniform sampler3D grid;
uniform int GridSize;
uniform int level = 0;

float ISO_LEVEL = 0.0f;
int lod = 1;

float densities[8];

ivec4 corners[8];
vec4 norm_corners[8];

vec3 vertices[12] = {vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0),
                     vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0), 
                     vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0)};

                     
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
    gl_Position = norm_corners[vert];
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

vec3 interpolation(ivec4 p1, ivec4 p2, float valp1, float valp2) {
    float mu;
    vec3 p; 

    mu = (ISO_LEVEL - valp1) / (valp2 - valp1);
    p.x = p1.x + mu * float(p2.x - p1.x);
    p.y = p1.y + mu * float(p2.y - p1.y);
    p.z = p1.z + mu * float(p2.z - p1.z);

    return vec3(p);
}

void main() {
    //int mul = int(pow(2, lod));
    int end = 10;
    int mul = 1;

    ivec3 tex_size = textureSize(grid, 0);

    for (int x = 0; x < end; x += mul) {
        for (int y = 0; y < end; y += mul) {
            for (int z = 0; z < end; z += mul) {

                int cubeindex = 0;

                corners[0] = ivec4(x, y, z, 1);                        norm_corners[0] = PVM * corners[0];
                corners[1] = ivec4(x + mul, y, z, 1);                  norm_corners[1] = PVM * corners[1];
                corners[2] = ivec4(x + mul, y, z + mul, 1);            norm_corners[2] = PVM * corners[2];
                corners[3] = ivec4(x, y, z + mul, 1);                  norm_corners[3] = PVM * corners[3];
                corners[4] = ivec4(x, y + mul, z, 1);                  norm_corners[4] = PVM * corners[4];
                corners[5] = ivec4(x + mul, y + mul, z, 1);            norm_corners[5] = PVM * corners[5];
                corners[6] = ivec4(x + mul, y + mul, z + mul, 1);      norm_corners[6] = PVM * corners[6];
                corners[7] = ivec4(x, y + mul, z + mul, 1);            norm_corners[7] = PVM * corners[7];
                    
                for (int i = 0; i < corners.length; i++)
                    densities[i] = texelFetch(grid, ivec3((vec3(corners[i])/end) * GridSize/pow(2.0,level)), level).r;
                    
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
                    vertices[0] = interpolation(corners[0], corners[1], densities[0], densities[1]);
                if ((EDGES[cubeindex] & 2) == 2)
                    vertices[1] = interpolation(corners[1], corners[2], densities[1], densities[2]);
                if ((EDGES[cubeindex] & 4) == 4)
                    vertices[2] = interpolation(corners[2], corners[3], densities[2], densities[3]);
                if ((EDGES[cubeindex] & 8) == 8)
                    vertices[3] = interpolation(corners[3], corners[0], densities[3], densities[0]);
                if ((EDGES[cubeindex] & 16) == 16)
                    vertices[4] = interpolation(corners[4], corners[5], densities[4], densities[5]);
                if ((EDGES[cubeindex] & 32) == 32)
                    vertices[5] = interpolation(corners[5], corners[6], densities[5], densities[6]);
                if ((EDGES[cubeindex] & 64) == 64)
                    vertices[6] = interpolation(corners[6], corners[7], densities[6], densities[7]);
                if ((EDGES[cubeindex] & 128) == 128)
                    vertices[7] = interpolation(corners[7], corners[4], densities[7], densities[4]);
                if ((EDGES[cubeindex] & 256) == 256)
                    vertices[8] = interpolation(corners[0], corners[4], densities[0], densities[4]);
                if ((EDGES[cubeindex] & 512) == 512)
                    vertices[9] = interpolation(corners[1], corners[5], densities[1], densities[5]);
                if ((EDGES[cubeindex] & 1024) == 1024)
                    vertices[10] = interpolation(corners[2], corners[6], densities[2], densities[6]);
                if ((EDGES[cubeindex] & 2048) == 2048)
                    vertices[11] = interpolation(corners[3], corners[7], densities[3], densities[7]);
                
                for (int i = 0; TRIANGLES[cubeindex][i] != -1; i += 3) {
                    
                    gl_Position = PVM * vec4(vertices[TRIANGLES[cubeindex][i+2]], 1);
                    EmitVertex();

                    gl_Position = PVM * vec4(vertices[TRIANGLES[cubeindex][i+1]], 1);
                    EmitVertex();

                    gl_Position = PVM * vec4(vertices[TRIANGLES[cubeindex][i]], 1);
                    EmitVertex();
                    
                    EndPrimitive();
                }
            }
        }
    }

    
}