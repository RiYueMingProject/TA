Shader "Unlit/Nephrite Dragon"
{
    Properties
    {
        _Distort("Distort",Float)=1
        _Power("Power",Float)=1
        _Scale("Scale",Float)=2
        _ThicknessMap("ThicknessMap",2D)="white"{}
        _CubeMap("Cubemap",Cube)="white"{}
        _EnvRotate("EnvRotate",Range(0,360))=0
        _DiffColor("DiffColor",Color)=(0,0,0,0)
        _AddColor("AddColor",Color)=(0,0,0,0)
        _SkyLightOpacity("SkyLightOpacity",Range(0,1))=1
        _BackLightColor("BackLightColor",Color)=(0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //ForwardBase
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_world:TEXCOORD1;
                float3 pos_world:TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _ThicknessMap;
            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;
            float4 _MainTex_ST;
            float4 _LightColor0;
            float _Distort;
            float _Power;
            float _Scale;
            float _EnvRotate;
            float4 _DiffColor;
            float4 _AddColor;
            float _SkyLightOpacity;
            float4 _BackLightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                o.normal_world=normalize(mul(v.normal,unity_WorldToObject));
                o.pos_world=mul(unity_ObjectToWorld,v.vertex);
                
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 normal_dir=normalize(i.normal_world);
                half3 pos_dir=normalize(i.pos_world);
                half3 light_dir=normalize(_WorldSpaceLightPos0.xyz);
                half3 view_dir=normalize(_WorldSpaceCameraPos.xyz-i.pos_world);
                //计算漫反射
                    half NdotL=max(0.0,dot(normal_dir,light_dir));
                    //模拟球形天光，限制在0,1范围内
                    half3 skylight_col=(dot(normal_dir,half3(0,1,0))+1)*0.5;
                    half3 diff_term=NdotL*_LightColor0.xyz*_DiffColor.xyz+_AddColor.xyz+skylight_col*_SkyLightOpacity;
                //计算透射光
                    //给光线方向添加法线方向的扰动，这样他就会随着结构变化
                    half3 backlight_dir=-normalize(light_dir+normal_dir*_Distort);                
                    //VdotL计算视线向量和光线方向的夹角，光线是从物体顶点出发的，所以需要加个负号
                    half VdotB=max(0.0,dot(view_dir,backlight_dir));
                    //使用pow限制范围
                    half backlight_term=max(0.0,pow(VdotB,_Power))*_Scale;

                    //读取厚度图，因为是黑白图所以只要一个通道就行，记得还要反相一下
                    half thickness=1.0-tex2D(_ThicknessMap,i.uv).r;

                    float3 backlight=backlight_term*_LightColor0.xyz*thickness*_BackLightColor.xyz;
                //计算光泽反射
                    //转换为弧度角
                    float rotate_angle=_EnvRotate*UNITY_PI/180;
                    //构造旋转矩阵
                    float2x2 rotater=float2x2(cos(rotate_angle),-sin(rotate_angle),sin(rotate_angle),cos(rotate_angle));
                    half3 reflect_dir=reflect(light_dir,normal_dir);
                    //只对xz旋转，y保持不变
                    half2 rotated=mul(rotater,reflect_dir.xz);
                    reflect_dir=half3(rotated.x,reflect_dir.y,rotated.y);
                    half4 hdr_col=texCUBE(_CubeMap,reflect_dir);
                    //解码hdr
                    half3 env_col=DecodeHDR(hdr_col,_CubeMap_HDR);
                //计算菲涅尔，记得让他保持大于0而且要反向
                    half NdotV=1-max(0.0,dot(normal_dir,view_dir));
                    env_col=env_col*NdotV;
                
                half3 final_color=diff_term+backlight+env_col;

                
                return half4(final_color,1.0);
            }
            ENDCG
        }

        //ForwardAdd
        Pass
        {
            Tags{"LightMode"="ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_world:TEXCOORD1;
                float3 pos_world:TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };

            sampler2D _MainTex;
            sampler2D _ThicknessMap;
            samplerCUBE _CubeMap;
            float4 _CubeMap_HDR;
            float4 _MainTex_ST;
            float4 _LightColor0;
            float _Distort;
            float _Power;
            float _Scale;
            float _EnvRotate;
            float4 _DiffColor;
            float4 _AddColor;
            float _SkyLightOpacity;
            float4 _BackLightColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

                o.normal_world=normalize(mul(v.normal,unity_WorldToObject));
                o.pos_world=mul(unity_ObjectToWorld,v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 normal_dir=normalize(i.normal_world);
                half3 pos_dir=normalize(i.pos_world);
                half3 light_dir=normalize(_WorldSpaceLightPos0.xyz);
                half3 light_dirOther=normalize(_WorldSpaceLightPos0-i.pos_world);
                //用_WorldSpaceLightPos0.w判断他是点光还是平行光
                light_dir=lerp(light_dir,light_dirOther,_WorldSpaceLightPos0.w);
                half3 view_dir=normalize(_WorldSpaceCameraPos.xyz-i.pos_world);

                half atten=LIGHT_ATTENUATION(i);
                
                //计算透射光
                    //给光线方向添加法线方向的扰动，这样他就会随着结构变化
                    half3 backlight_dir=-normalize(light_dir+normal_dir*_Distort);                
                    //VdotL计算视线向量和光线方向的夹角，光线是从物体顶点出发的，所以需要加个负号
                    half VdotB=max(0.0,dot(view_dir,backlight_dir));
                    //使用pow限制范围
                    half backlight_term=max(0.0,pow(VdotB,_Power))*_Scale;

                    //读取厚度图，因为是黑白图所以只要一个通道就行，记得还要反相一下
                    half thickness=1.0-tex2D(_ThicknessMap,i.uv).r;

                    float3 backlight=backlight_term*_LightColor0.xyz*thickness*_BackLightColor.xyz*atten;
          
                half3 final_color=backlight;

                
                return half4(final_color,1.0);
            }
            ENDCG
        }
        
    }
    Fallback "Diffuse"
}
