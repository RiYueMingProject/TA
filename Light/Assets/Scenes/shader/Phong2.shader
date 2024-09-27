Shader "lit/Phong2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AOTex ("AOTex", 2D) = "white" {}
        _SpecMask ("SpecMask", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _ParallaxMap ("ParallaxMap", 2D) = "white" {}
        _Shineness("Shineness",Range(0.01,100))=1.0
        _ParallaxIntensity("ParallaxIntensity",Range(0.01,100))=1.0
        _AmbientColor("AmbientColor",Color)=(0,0,0,0)
        _SpecIntensity("SpecIntensity",Range(0.0,10))=1
        _NormalIntensity("NormalIntensity",Range(0.0,10))=1.0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //ForwardBase的pass
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
                float3 normal:NORMAL;

                //获取物体表面的切线
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;

                //获取世界空间下的法线信息和顶点信息
                float3 normal_world:TEXCOORD1;
                float3 pos_world:TEXCOORD2;

                //获取切线和副法线
                float3 tangent_world:TEXCOORD3;
                float3 binormal:TEXCOORD4;

                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            sampler2D _AOTex;
            sampler2D _SpecMask;
            sampler2D _NormalMap;
            sampler2D _ParallaxMap;
            float4 _MainTex_ST;
            float4 _LightColor0;
            //控制高光半径，_Shineness越大高光半径越小
            float _Shineness;
            float _NormalIntensity;
            float _ParallaxIntensity;

            float _SpecIntensity;
            //设置环境光照颜色
            half4 _AmbientColor;

            float3 ACESFilm(float3 x){
                float a=2.51f;
                float b=0.03f;
                float c=2.43f;
                float d=0.59f;
                float e=0.14f;
                return saturate((x*(a*x+b))/(x*(c*x+d)+e));
            }


            v2f vert (appdata v)
            {
                v2f o;
                //裁剪空间下的顶点信息
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                o.normal_world=normalize(mul(v.normal,unity_WorldToObject).xyz);
                o.pos_world=mul(unity_ObjectToWorld,v.vertex);
                
                o.tangent_world=normalize(mul(unity_ObjectToWorld,v.tangent));
                //v.tangent.w是为了处理不同平台中的副法线翻转问题
                o.binormal=normalize(cross(o.normal_world,o.tangent_world))*v.tangent.w;

                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half shadow=SHADOW_ATTENUATION(i);

                //因为光栅化之后法线长度很可能改变所以他必须normalize一下
                half3 normal_dir=normalize(i.normal_world);
                half3 tangent_dir=normalize(i.tangent_world);
                half3 binormal_dir=normalize(i.binormal);

                //构造BTN矩阵方便计算
                float3x3 TBN=float3x3(tangent_dir,binormal_dir,normal_dir);
                
                //计算观察方向
                half3 view_dir=normalize(_WorldSpaceCameraPos.xyz-i.pos_world);

                //计算视差贴图的偏移方向，他应该沿着视线方向偏移
                half3 view_tangentspace=normalize(mul(TBN,view_dir));
                //计算偏移后的uv，向下凹陷所以是1-height
                half2 uv_parallax=i.uv;

                //循环迭代
                for(int j=0;j<5;j++){
                    //采样高度图
                    half4 height=tex2D(_ParallaxMap,uv_parallax);

                    uv_parallax=uv_parallax-(1-height)*(view_tangentspace.xy/view_tangentspace.z)*_ParallaxIntensity*0.01;
                }

                
                //传入数据
                half4 base_color=tex2D(_MainTex, uv_parallax);
                base_color=pow(base_color,2.2);

                half4 aoTex=tex2D(_AOTex,uv_parallax);
                half4 specMask=tex2D(_SpecMask,uv_parallax);
                //传入法线贴图并解码
                half4 normal_color=tex2D(_NormalMap,uv_parallax);
                half3 normal_data=UnpackNormal(normal_color);
                normal_data.xy=normal_data.xy*_NormalIntensity;
                //计算被法线贴图扰动之后的法线
                normal_dir=normalize(mul(normal_data,TBN));


                
                //计算diffuse
                    //获取主方向光
                    half3 light_dir=normalize(_WorldSpaceLightPos0);
                    half3 diff_term=min(shadow,max(0.0,dot(normal_dir,light_dir)));
                    half3 diffuse=diff_term*_LightColor0.xyz*base_color.xyz;
                
                //计算specular
                    //获取半程向量
                    half3 half_dir=normalize(light_dir+view_dir);
                    //计算法线和半程向量的夹角
                    half3 NdotH=dot(normal_dir,half_dir);
                    //计算高光
                    half3 specular=pow(max(0.0,NdotH),_Shineness)*_LightColor0.xyz*_SpecIntensity*specMask.rgb*diff_term;

                //计算ambient color
                    half3 ambient=UNITY_LIGHTMODEL_AMBIENT.rgb*base_color.xyz;
                
                //合成
                half3 final_color=(diffuse+specular+ambient)*aoTex;

                half3 tone_color=ACESFilm(final_color);
                tone_color=pow(tone_color,1.0/2.2);

                
                return half4(tone_color,1.0);
            }
            ENDCG
        }
        //ForwardAdd的pass
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
                float3 normal:NORMAL;

                //获取物体表面的切线
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;

                //获取世界空间下的法线信息和顶点信息
                float3 normal_world:TEXCOORD1;
                float3 pos_world:TEXCOORD2;

                //获取切线和副法线
                float3 tangent_world:TEXCOORD3;
                float3 binormal:TEXCOORD4;

                LIGHTING_COORDS(5,6)
            };

            sampler2D _MainTex;
            sampler2D _AOTex;
            sampler2D _SpecMask;
            sampler2D _NormalMap;
            sampler2D _ParallaxMap;
            float4 _MainTex_ST;
            float4 _LightColor0;
            //控制高光半径，_Shineness越大高光半径越小
            float _Shineness;
            float _NormalIntensity;
            float _ParallaxIntensity;

            float _SpecIntensity;
            //设置环境光照颜色
            half4 _AmbientColor;
            

            float3 ACESFilm(float3 x){
                float a=2.51f;
                float b=0.03f;
                float c=2.43f;
                float d=0.59f;
                float e=0.14f;
                return saturate((x*(a*x+b))/(x*(c*x+d)+e));
            }


            v2f vert (appdata v)
            {
                v2f o;
                //裁剪空间下的顶点信息
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                o.normal_world=normalize(mul(v.normal,unity_WorldToObject).xyz);
                o.pos_world=mul(unity_ObjectToWorld,v.vertex);
                
                o.tangent_world=normalize(mul(unity_ObjectToWorld,v.tangent));
                //v.tangent.w是为了处理不同平台中的副法线翻转问题
                o.binormal=normalize(cross(o.normal_world,o.tangent_world))*v.tangent.w;

                TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float attenuation;
                half atten=LIGHT_ATTENUATION(i);

                //因为光栅化之后法线长度很可能改变所以他必须normalize一下
                half3 normal_dir=normalize(i.normal_world);
                half3 tangent_dir=normalize(i.tangent_world);
                half3 binormal_dir=normalize(i.binormal);

                //构造BTN矩阵方便计算
                float3x3 TBN=float3x3(tangent_dir,binormal_dir,normal_dir);
                
                //计算观察方向
                half3 view_dir=normalize(_WorldSpaceCameraPos.xyz-i.pos_world);

                //计算视差贴图的偏移方向，他应该沿着视线方向偏移
                half3 view_tangentspace=normalize(mul(TBN,view_dir));
                //计算偏移后的uv，向下凹陷所以是1-height
                half2 uv_parallax=i.uv;

                //循环迭代
                for(int j=0;j<5;j++){
                    //采样高度图
                    half4 height=tex2D(_ParallaxMap,uv_parallax);

                    uv_parallax=uv_parallax-(1-height)*(view_tangentspace.xy/view_tangentspace.z)*_ParallaxIntensity*0.01;
                }

                
                //传入数据
                half4 base_color=tex2D(_MainTex, uv_parallax);
                base_color=pow(base_color,2.2);

                half4 aoTex=tex2D(_AOTex,uv_parallax);
                half4 specMask=tex2D(_SpecMask,uv_parallax);
                //传入法线贴图并解码
                half4 normal_color=tex2D(_NormalMap,uv_parallax);
                half3 normal_data=UnpackNormal(normal_color);
                normal_data.xy=normal_data.xy*_NormalIntensity;
                //计算被法线贴图扰动之后的法线
                normal_dir=normalize(mul(normal_data,TBN));


                
                //计算diffuse
                    //获取主方向光
                    #if defined(DIRECTIONAL)
                        half3 light_dir=normalize(_WorldSpaceLightPos0);
                        attenuation=1;
                    #elif defined(POINT)
                        half3 light_dir=normalize(_WorldSpaceLightPos0-i.pos_world);
                        half distance=length(_WorldSpaceLightPos0-i.pos_world);
                        half range=1.0/unity_WorldToLight[0][0];
                        attenuation=saturate(range-distance)/range;

                    #endif
                    half3 diff_term=min(atten,max(0.0,dot(normal_dir,light_dir)));
                    half3 diffuse=diff_term*_LightColor0.xyz*base_color.xyz*attenuation;
                
                //计算specular
                    //获取半程向量
                    half3 half_dir=normalize(light_dir+view_dir);
                    //计算法线和半程向量的夹角
                    half3 NdotH=dot(normal_dir,half_dir);
                    //计算高光
                    half3 specular=pow(max(0.0,NdotH),_Shineness)*_LightColor0.xyz*_SpecIntensity*specMask.rgb*diff_term*attenuation;

                //计算ambient color
                    half3 ambient=UNITY_LIGHTMODEL_AMBIENT.rgb*base_color.xyz;
                
                //合成
                half3 final_color=(diffuse+specular)*aoTex;

                half3 tone_color=ACESFilm(final_color);
                tone_color=pow(tone_color,1.0/2.2);

                
                return half4(tone_color,1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
