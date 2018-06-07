/*
http://www.icare3d.org/codes-and-projects/codes/opengl_geometry_shader_marching_cubes.html
*/

#version 430
//New G80 extensions
#extension GL_EXT_geometry_shader4 : enable
#extension GL_EXT_gpu_shader4 : enable

//Volume data field texture
uniform sampler3D grid;

//Global iso level
uniform float isolevel = 0.0f;

//Marching cubes vertices decal
float voxelHalfSize = 0.5;
float xmin = -voxelHalfSize; float xmax = +voxelHalfSize;
float ymin = -voxelHalfSize; float ymax = +voxelHalfSize;
float zmin = -voxelHalfSize; float zmax = +voxelHalfSize;

vec3 vertDecals[8] = {
	vec3(xmax, ymin, zmin), vec3(xmax, ymin, zmax),
	vec3(xmax, ymax, zmax), vec3(xmax, ymax, zmin),
	vec3(xmin, ymin, zmin), vec3(xmin, ymin, zmax),
	vec3(xmin, ymax, zmax), vec3(xmin, ymax, zmin)
};

/*
layout(std430, binding = 1) buffer edgesBuffer {
    int edgeTableTex[256][1];
};*/

layout(std430, binding = 2) buffer trianglesBuffer {
    int triTableTex[256][16];
};

uniform mat4 PVM;
uniform int level = 0;

//Get vertex i position within current marching cube
vec3 cubePos(int i){
	return gl_PositionIn[0].xyz + vertDecals[i];
}

//Get vertex i value within current marching cube
float cubeVal(int i){
	//return texelFetch(grid, ivec3((cubePos(i)+1.0f)/2.0f), level).a;
	return texture3D(isampler3D(grid), (cubePos(i)+1.0f)/2.0f).a;
}

//Get triangle table value
int triTableValue(int i, int j){
	return triTableTex[i][j];
}

//Compute interpolated vertex along an edge
vec3 vertexInterp(float isolevel, vec3 v0, float l0, vec3 v1, float l1){
	return mix(v0, v1, (isolevel-l0)/(l1-l0));
}

//Geometry Shader entry point
void main(void) {

	int cubeindex = 0;

	float cubeVal0 = cubeVal(0);
	float cubeVal1 = cubeVal(1);
	float cubeVal2 = cubeVal(2);
	float cubeVal3 = cubeVal(3);
	float cubeVal4 = cubeVal(4);
	float cubeVal5 = cubeVal(5);
	float cubeVal6 = cubeVal(6);
	float cubeVal7 = cubeVal(7);

	//Determine the index into the edge table which
	//tells us which vertices are inside of the surface
	cubeindex = int(cubeVal0 < isolevel);
	cubeindex += int(cubeVal1 < isolevel)*2;
	cubeindex += int(cubeVal2 < isolevel)*4;
	cubeindex += int(cubeVal3 < isolevel)*8;
	cubeindex += int(cubeVal4 < isolevel)*16;
	cubeindex += int(cubeVal5 < isolevel)*32;
	cubeindex += int(cubeVal6 < isolevel)*64;
	cubeindex += int(cubeVal7 < isolevel)*128;

	//Cube is entirely in/out of the surface
	if (cubeindex ==0 || cubeindex == 255)
		return;

	vec3 vertlist[12];

	//Find the vertices where the surface intersects the cube
	vertlist[0] = vertexInterp(isolevel, cubePos(0), cubeVal0, cubePos(1), cubeVal1);
	vertlist[1] = vertexInterp(isolevel, cubePos(1), cubeVal1, cubePos(2), cubeVal2);
	vertlist[2] = vertexInterp(isolevel, cubePos(2), cubeVal2, cubePos(3), cubeVal3);
	vertlist[3] = vertexInterp(isolevel, cubePos(3), cubeVal3, cubePos(0), cubeVal0);
	vertlist[4] = vertexInterp(isolevel, cubePos(4), cubeVal4, cubePos(5), cubeVal5);
	vertlist[5] = vertexInterp(isolevel, cubePos(5), cubeVal5, cubePos(6), cubeVal6);
	vertlist[6] = vertexInterp(isolevel, cubePos(6), cubeVal6, cubePos(7), cubeVal7);
	vertlist[7] = vertexInterp(isolevel, cubePos(7), cubeVal7, cubePos(4), cubeVal4);
	vertlist[8] = vertexInterp(isolevel, cubePos(0), cubeVal0, cubePos(4), cubeVal4);
	vertlist[9] = vertexInterp(isolevel, cubePos(1), cubeVal1, cubePos(5), cubeVal5);
	vertlist[10] = vertexInterp(isolevel, cubePos(2), cubeVal2, cubePos(6), cubeVal6);
	vertlist[11] = vertexInterp(isolevel, cubePos(3), cubeVal3, cubePos(7), cubeVal7);
	
	int i=0;
	
	//Strange bug with this way, uncomment to test
	//for (i=0; triTableValue(cubeindex, i)!=-1; i+=3) {
	while(true) {
		if(triTableValue(cubeindex, i)!=-1) {
		//Generate first vertex of triangle//
		//Fill position varying attribute for fragment shader
		//Fill gl_Position attribute for vertex raster space position
		gl_Position = PVM * vec4(vertlist[triTableValue(cubeindex, i)], 1);;
		EmitVertex();

		//Generate second vertex of triangle//
		//Fill position varying attribute for fragment shader
		//Fill gl_Position attribute for vertex raster space position
		gl_Position = PVM * vec4(vertlist[triTableValue(cubeindex, i+1)], 1);
		EmitVertex();

		//Generate last vertex of triangle//
		//Fill position varying attribute for fragment shader
		//Fill gl_Position attribute for vertex raster space position
		gl_Position = vec4(vertlist[triTableValue(cubeindex, i+2)], 1);
		EmitVertex();

		//End triangle strip at firts triangle
		EndPrimitive();
		} else {
			break;
		}

		i=i+3; //Comment it for testing the strange bug
	}
}