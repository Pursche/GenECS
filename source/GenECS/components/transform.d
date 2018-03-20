module GenECS.components.transform;

public import GenECS.utils;

@Component(512)
struct TransformComponent
{
    float[3] position = [0,0,0];
    float[4] rotation = [0,0,0,1];
    float[3] scale = [1,1,1];

    @Internal float[4] matWorld;
}