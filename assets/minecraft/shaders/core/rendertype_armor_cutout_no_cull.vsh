#version 150

#moj_import <light.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 tintColor;
out vec4 lightColor;
out vec4 overlayColor;
out vec2 uv;
out vec4 normal;
out vec3 screenLocation;
flat out vec2 size;
flat out int n;
flat out int i;

int toint(vec3 c) {
    ivec3 v = ivec3(c*255);
    return (v.r<<16)+(v.g<<8)+v.b;
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexDistance = fog_distance(ModelViewMat, Position, FogShape);
    tintColor = Color;
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, vec4(1));
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    uv = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
    screenLocation = gl_Position.xyw;

    //number of armors from texture size
    size = textureSize(Sampler0, 0);
    n = int(2*size.y/size.x);
    i = toint(Color.rgb);
    //if theres more than 1 custom armor
    if (n > 1 && size.x < 256) {
        //divide uv by number of armors, it is now on the first armor
        uv.y /= n;
        //if color index is within number of armors
        if (i < n) {
            //move uv down to index
            uv.y += (1+i)*size.x/size.y/2.;
            //remove tint color
            tintColor = vec4(1);
        } else {
            //move uv down for non tint
            uv.y += size.x/size.y/2.;
        }
    }
}
