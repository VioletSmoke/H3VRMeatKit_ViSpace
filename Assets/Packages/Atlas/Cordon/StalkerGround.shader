Shader "Custom/StalkerGroundEdgeBlended10"
{
    Properties
    {
        _MainTex ("Texture 0", 2D) = "white" {}
        _Textures1 ("Texture 1", 2D) = "white" {}
        _Textures2 ("Texture 2", 2D) = "white" {}
        _Textures3 ("Texture 3", 2D) = "white" {}
        _Textures4 ("Texture 4", 2D) = "white" {}
        _Textures5 ("Texture 5", 2D) = "white" {}
        _Textures6 ("Texture 6", 2D) = "white" {}
        _Textures7 ("Texture 7", 2D) = "white" {}
        _Textures8 ("Texture 8", 2D) = "white" {}
        _Textures9 ("Texture 9", 2D) = "white" {}

        _Color0 ("Blend Color 0", Color) = (1,0,0,1)
        _Color1 ("Blend Color 1", Color) = (0,1,0,1)
        _Color2 ("Blend Color 2", Color) = (0,0,1,1)
        _Color3 ("Blend Color 3", Color) = (1,1,0,1)
        _Color4 ("Blend Color 4", Color) = (1,0,1,1)
        _Color5 ("Blend Color 5", Color) = (0,1,1,1)
        _Color6 ("Blend Color 6", Color) = (0.5,0.5,0.5,1)
        _Color7 ("Blend Color 7", Color) = (1,0.5,0,1)
        _Color8 ("Blend Color 8", Color) = (0,0.5,1,1)
        _Color9 ("Blend Color 9", Color) = (0.5,1,0,1)
        _TexturesToUse ("Textures to Use ", Range(1,10) ) = 10
        _Tiling ("Tiling", Float) = 10
        _EdgeThreshold ("Edge Blend Threshold", Float) = 0.1
        _HueWeight ("Hue Weight", Float) = 1
        _BrightnessWeight ("Brightness Weight", Float) = 0.5
        _SaturationWeight ("Saturation Weight", Float) = 0.2
        _FallbackDistance ("Fallback Distance", Float) = 700.0 // Distance threshold
        _TransitionDistance ("Transition Distance", Float) = 100.0 // Distance threshold
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #include "UnityCG.cginc"
        #pragma surface surf Standard fullforwardshadows

        sampler2D _MainTex, _Textures1, _Textures2, _Textures3, _Textures4;
        sampler2D _Textures5, _Textures6, _Textures7, _Textures8, _Textures9;

        float4 _Color0, _Color1, _Color2, _Color3, _Color4;
        float4 _Color5, _Color6, _Color7, _Color8, _Color9;
        int _TexturesToUse;
        float _Tiling;
        float _EdgeThreshold;
        float _HueWeight;
        float _SaturationWeight;  // Use a smaller value for saturation
        float _BrightnessWeight;  // Use an even smaller value for brightness
        float _FallbackDistance;
        float _TransitionDistance;
        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos : TEXCOORD0;
            fixed4 color : COLOR;
        };

        float3 RGBToHSV(float3 color)
        {
            float cmax = max(max(color.r, color.g), color.b);
            float cmin = min(min(color.r, color.g), color.b);
            float delta = cmax - cmin;

            float h = 0.0;
            if (delta != 0.0)
            {
                if (cmax == color.r) 
                    h = (color.g - color.b) / delta;
                else if (cmax == color.g) 
                    h = (color.b - color.r) / delta + 2.0;
                else if (cmax == color.b) 
                    h = (color.r - color.g) / delta + 4.0;
            }

            h = fmod(h, 6.0);
            h = (h < 0.0) ? h + 6.0 : h;

            float s = (cmax == 0.0) ? 0.0 : delta / cmax;
            float v = cmax;

            return float3(h, s, v);
        }
        float CompareHSV(float3 hsv1, float3 hsv2)
        {
            // Compute the hue difference with wrap-around.
            // Our hue is in [0,6), so if the difference is more than half (i.e. >3),
            // then we take the shorter way around the circle.
            float dh = abs(hsv1.x - hsv2.x);
            if (dh > 3.0)
            {
                dh = 6.0 - dh;
            }
    
            // Compute the differences for saturation and brightness.
            float ds = abs(hsv1.y - hsv2.y);
            float dv = abs(hsv1.z - hsv2.z);
    
            // Now compute a weighted Euclidean distance.
            // _HueWeight, _SaturationWeight, and _BrightnessWeight are global variables.
            return  (_HueWeight * dh) +
                         (_SaturationWeight * ds) +
                         (_BrightnessWeight * dv) ;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {

            float3 vertexColor = RGBToHSV(IN.color.rgb);
            
            float3 colorsHSV[10] = {
                RGBToHSV(_Color0.rgb), RGBToHSV(_Color1.rgb), RGBToHSV(_Color2.rgb),
                RGBToHSV(_Color3.rgb), RGBToHSV(_Color4.rgb), RGBToHSV(_Color5.rgb),
                RGBToHSV(_Color6.rgb), RGBToHSV(_Color7.rgb), RGBToHSV(_Color8.rgb),
                RGBToHSV(_Color9.rgb)
            };
            /*
            float3 colorsHSV[10] = {
                _Color0.rgb, _Color1.rgb, _Color2.rgb,
                _Color3.rgb, _Color4.rgb, _Color5.rgb,
                _Color6.rgb, _Color7.rgb, _Color8.rgb,
                _Color9.rgb
            };*/
            float distances[10];
            for (int i = 0; i < _TexturesToUse; i++)
                distances[i] = CompareHSV(vertexColor, colorsHSV[i]);

            // Find the closest and second closest textures
            int closestIdx = 0, secondIdx = 1;
            if (distances[1] < distances[0]) { closestIdx = 1; secondIdx = 0; }

            for (int i = 2; i < _TexturesToUse; i++)
            {
                if (distances[i] < distances[closestIdx])
                {
                    secondIdx = closestIdx;
                    closestIdx = i;
                }
                else if (distances[i] < distances[secondIdx])
                {
                    secondIdx = i;
                }
            }

            float2 uvTiled = IN.uv_MainTex * _Tiling;

            fixed4 textures[10] = {
                tex2D(_MainTex, uvTiled), tex2D(_Textures1, uvTiled),
                tex2D(_Textures2, uvTiled), tex2D(_Textures3, uvTiled),
                tex2D(_Textures4, uvTiled), tex2D(_Textures5, uvTiled),
                tex2D(_Textures6, uvTiled), tex2D(_Textures7, uvTiled),
                tex2D(_Textures8, uvTiled), tex2D(_Textures9, uvTiled)
            };

            // Default to the closest texture.


            float distDiff = distances[secondIdx] - distances[closestIdx];

            fixed4 selectedTex = textures[closestIdx]; // default: use the closest texture



            if (distDiff < _EdgeThreshold)
            {
                // Normalize the difference: when distDiff==0, u is 0; when distDiff equals _EdgeThreshold, u is 1.
                float u = saturate(distDiff / _EdgeThreshold);
                // When u==0, we want a 50/50 blend (t=0.5).
                // When u==1, we want 100% of the closest texture (t==1.0).
                float t = lerp(0.5, 1.0, u);
                selectedTex = lerp(textures[secondIdx], textures[closestIdx], t);
            }
            float cameraDistance = length(_WorldSpaceCameraPos - IN.worldPos);

            // If the object is too far from the camera, fallback to vertex color
            if (cameraDistance > _FallbackDistance - _TransitionDistance)
            {
                // Interpolate between texture color and vertex color based on distance
                
                selectedTex.rgb = lerp(selectedTex.rgb, IN.color.rgb,  smoothstep(_FallbackDistance - _TransitionDistance, _FallbackDistance, cameraDistance));
            }
            o.Albedo = selectedTex.rgb;
            o.Alpha = selectedTex.a;

        }

        ENDCG
    }
    FallBack "Diffuse"
}
