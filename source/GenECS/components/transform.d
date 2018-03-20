module GenECS.components.transform;

public import GenECS.utils;

@Component(512)
struct TransformComponent
{
    float[2] position = [0,0];
    float rotation = 0.0f;
}