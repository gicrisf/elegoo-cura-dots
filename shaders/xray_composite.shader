[shaders]
vertex =
    uniform highp mat4 u_modelViewProjectionMatrix;
    attribute highp vec4 a_vertex;
    attribute highp vec2 a_uvs;

    varying highp vec2 v_uvs;

    void main()
    {
        gl_Position = u_modelViewProjectionMatrix * a_vertex;
        v_uvs = a_uvs;
    }

fragment =
    #ifdef GL_ES
        #ifdef GL_FRAGMENT_PRECISION_HIGH
            precision highp float;
        #else
            precision mediump float;
        #endif // GL_FRAGMENT_PRECISION_HIGH
    #endif // GL_ES
    uniform sampler2D u_layer0; //Default pass.
    uniform sampler2D u_layer1; //Selection pass.
    uniform sampler2D u_layer2; //X-ray pass.

    uniform vec2 u_offset[9];

    uniform float u_outline_strength;
    uniform vec4 u_outline_color;
    uniform vec4 u_background_color;
    uniform float u_xray_error_strength;
    uniform float u_flat_error_color_mix;

    const vec3 x_axis = vec3(1.0, 0.0, 0.0);
    const vec3 y_axis = vec3(0.0, 1.0, 0.0);
    const vec3 z_axis = vec3(0.0, 0.0, 1.0);

    varying vec2 v_uvs;

    float kernel[9];

    vec3 shiftHue(vec3 color, float hue)
    {
        // Make sure colors are distinct when grey-scale is used too:
        if ((max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b)) < 0.1)
        {
            color = vec3(1.0, 0.0, 0.0);
        }

        // The actual hue shift:
        const vec3 k = vec3(0.57735, 0.57735, 0.57735);
        float cosAngle = cos(hue);
        return vec3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
    }

    void main()
    {
        kernel[0] = 0.0; kernel[1] = 1.0; kernel[2] = 0.0;
        kernel[3] = 1.0; kernel[4] = -4.0; kernel[5] = 1.0;
        kernel[6] = 0.0; kernel[7] = 1.0; kernel[8] = 0.0;

        vec4 result = u_background_color;
        vec4 layer0 = texture2D(u_layer0, v_uvs);

        float hue_shift = (layer0.a - 0.333) * 6.2831853;
        if (layer0.a > 0.5)
        {
            layer0.a = 1.0;
        }
        result = mix(result, layer0, layer0.a);

        float intersection_count = texture2D(u_layer2, v_uvs).r * 51.0; // (1 / .02) + 1 (+1 magically fixes issues with high intersection count models)
        float rest = mod(intersection_count + .01, 2.0);
        if (rest > 1.0 && rest < 1.5 && intersection_count < 49.0)
        {
            result = mix(vec4(shiftHue(layer0.rgb, hue_shift), result.a), vec4(1.,0.,0.,1.), u_flat_error_color_mix);
        }

        vec4 sum = vec4(0.0);
        for (int i = 0; i < 9; i++)
        {
            vec4 color = vec4(texture2D(u_layer1, v_uvs.xy + u_offset[i]).a);
            sum += color * (kernel[i] / u_outline_strength);
        }

        vec4 layer1 = texture2D(u_layer1, v_uvs);
        if((layer1.rgb == x_axis || layer1.rgb == y_axis || layer1.rgb == z_axis))
        {
            gl_FragColor = result;
        }
        else
        {
            gl_FragColor = mix(result, u_outline_color, abs(sum.a));
        }

        gl_FragColor.a = gl_FragColor.a > 0.5 ? 1.0 : 0.0;
    }

vertex41core =
    #version 410
    uniform highp mat4 u_modelViewProjectionMatrix;
    in highp vec4 a_vertex;
    in highp vec2 a_uvs;

    out highp vec2 v_uvs;

    void main()
    {
        gl_Position = u_modelViewProjectionMatrix * a_vertex;
        v_uvs = a_uvs;
    }

fragment41core =
    #version 410
    uniform sampler2D u_layer0; //Default pass.
    uniform sampler2D u_layer1; //Selection pass.
    uniform sampler2D u_layer2; //X-ray pass.

    uniform vec2 u_offset[9];

    uniform float u_outline_strength;
    uniform vec4 u_outline_color;
    uniform vec4 u_background_color;
    uniform float u_xray_error_strength;
    uniform float u_flat_error_color_mix;

    const vec3 x_axis = vec3(1.0, 0.0, 0.0);
    const vec3 y_axis = vec3(0.0, 1.0, 0.0);
    const vec3 z_axis = vec3(0.0, 0.0, 1.0);

    in vec2 v_uvs;
    out vec4 frag_color;

    float kernel[9];

    vec3 shiftHue(vec3 color, float hue)
    {
        // Make sure colors are distinct when grey-scale is used too:
        if ((max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b)) < 0.1)
        {
            color = vec3(1.0, 0.0, 0.0);
        }

        // The actual hue shift:
        const vec3 k = vec3(0.57735, 0.57735, 0.57735);
        float cosAngle = cos(hue);
        return vec3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
    }

    void main()
    {
        kernel[0] = 0.0; kernel[1] = 1.0; kernel[2] = 0.0;
        kernel[3] = 1.0; kernel[4] = -4.0; kernel[5] = 1.0;
        kernel[6] = 0.0; kernel[7] = 1.0; kernel[8] = 0.0;

        vec4 result = u_background_color;
        vec4 layer0 = texture(u_layer0, v_uvs);

        float hue_shift = (layer0.a - 0.333) * 6.2831853;
        if (layer0.a > 0.5)
        {
            layer0.a = 1.0;
        }
        result = mix(result, layer0, layer0.a);

        float intersection_count = texture(u_layer2, v_uvs).r * 51; // (1 / .02) + 1 (+1 magically fixes issues with high intersection count models)
        float rest = mod(intersection_count + .01, 2.0);
        if (rest > 1.0 && rest < 1.5 && intersection_count < 49)
        {
            result = mix(vec4(shiftHue(layer0.rgb, hue_shift), result.a), vec4(1.,0.,0.,1.), u_flat_error_color_mix);
        }

        vec4 sum = vec4(0.0);
        for (int i = 0; i < 9; i++)
        {
            vec4 color = vec4(texture(u_layer1, v_uvs.xy + u_offset[i]).a);
            sum += color * (kernel[i] / u_outline_strength);
        }

        vec4 layer1 = texture(u_layer1, v_uvs);
        if((layer1.rgb == x_axis || layer1.rgb == y_axis || layer1.rgb == z_axis))
        {
            frag_color = result;
        }
        else
        {
            frag_color = mix(result, u_outline_color, abs(sum.a));
        }

        frag_color.a = frag_color.a > 0.5 ? 1.0 : 0.0;
    }

[defaults]
u_layer0 = 0
u_layer1 = 1
u_layer2 = 2
u_background_color = [0.965, 0.965, 0.965, 1.0]
u_outline_strength = 1.0
u_outline_color = [0.05, 0.66, 0.89, 1.0]
u_flat_error_color_mix = 0.5

[bindings]

[attributes]
a_vertex = vertex
a_uvs = uv

