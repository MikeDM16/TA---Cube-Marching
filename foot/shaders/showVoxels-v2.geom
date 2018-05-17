#version 440

/*
https://pastebin.com/DQ4Xjn7t
*/

layout(points) in;
layout(triangle_strip, max_vertices = 100) out;

layout(std140, binding = 1) buffer edgesBuffer {
    int EDGES[256];
};

layout(std140, binding = 2) buffer trianglesBuffer {
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

vec3 interpolation(vec3 p1, vec3 p2, float valp1, float valp2) {
    float mu;
    vec3 p; 

    mu = (ISO_LEVEL - valp1) / (valp2 - valp1);
    p.x = p1.x + mu * float(p2.x - p1.x);
    p.y = p1.y + mu * float(p2.y - p1.y);
    p.z = p1.z + mu * float(p2.z - p1.z);

    return p;
}

void main() {
    //int mul = int(pow(2, lod));
    int mul = int(4/2);

    for (int x = 0; x < 4; x += mul) {
        for (int y = 0; y < 4; y += mul) {
            for (int z = 0; z < 4; z += mul) {

                int cubeindex = 0;

                corners[0] = ivec4(x, y, z, 1);                        norm_corners[0] = PVM * corners[0];
                corners[1] = ivec4(x + mul, y, z, 1);                  norm_corners[1] = PVM * corners[1];
                corners[2] = ivec4(x + mul, y, z + mul, 1);            norm_corners[2] = PVM * corners[2];
                corners[3] = ivec4(x, y, z + mul, 1);                  norm_corners[3] = PVM * corners[3];
                corners[4] = ivec4(x, y + mul, z, 1);                  norm_corners[4] = PVM * corners[4];
                corners[5] = ivec4(x + mul, y + mul, z, 1);            norm_corners[5] = PVM * corners[5];
                corners[6] = ivec4(x + mul, y + mul, z + mul, 1);      norm_corners[6] = PVM * corners[6];
                corners[7] = ivec4(x, y + mul, z + mul, 1);            norm_corners[7] = PVM * corners[7];
                
                for (int face = 0; face < 6; face++)
                    emit_face(face);

                /*
                for (int i = 0; i < corners.length; i++){
                    gl_Position = PVM * gl_in[0].gl_Position + vec4(corners[0], 1);
                    EmitVertex();
                    gl_Position = PVM * gl_in[0].gl_Position + vec4(corners[4], 1);
                    EmitVertex();
                    gl_Position = PVM * gl_in[0].gl_Position + vec4(corners[7], 1);
                    EmitVertex();
                }*/

                /*
                for (int i = 0; i < corners.length; i++){
                    //densities[i] = texelFetch(grid, ivec3(corners[i] * GridSize/pow(2.0,level)), level).r;
                    densities[i] = texelFetch(grid, ivec3(corners[i]), level).r;
                }

                
                //the |= operator performs a bitwise logical OR operation on integral operands
                if (densities[0] < ISO_LEVEL) cubeindex |= 1;
                if (densities[1] < ISO_LEVEL) cubeindex |= 2;
                if (densities[2] < ISO_LEVEL) cubeindex |= 4;
                if (densities[3] < ISO_LEVEL) cubeindex |= 8;
                if (densities[4] < ISO_LEVEL) cubeindex |= 16;
                if (densities[5] < ISO_LEVEL) cubeindex |= 32;
                if (densities[6] < ISO_LEVEL) cubeindex |= 64;
                if (densities[7] < ISO_LEVEL) cubeindex |= 128;
            
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
                */
                
            }
        }
    }
}