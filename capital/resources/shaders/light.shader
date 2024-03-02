#version 330

precision mediump float;

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

struct Spot {
  vec2 pos;
  float inner;
  float radius;
};

uniform Spot spot;
uniform float screenWidth;

void main() {
  float alpha = 1.0;

}
