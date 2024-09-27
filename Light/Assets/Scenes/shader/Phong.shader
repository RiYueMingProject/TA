Shader "lit/Phong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AOMap ("AO", 2D) = "white" {}
        _SpecMask ("SpecMask", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _ParallaxMap ("ParallaxMap", 2D) = "white" {}
        _Shineness("Shineness",Range(0.01,100))=1.0
        _AmbientColor("Ambient Color",Color)=(0,0,0,0)
        _SpecIntensity("SpecIntensity",Range(0.01,5))=1.0
        _NormalIntensity("Normal Intensity",range(0.0,5.0))=1.0
        _Parallax("Parallax",Float)=2.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //ForwardBase的pass
        Pass
        {
            //这个pass用于计算主方向灯和顶点灯光
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //函数库和头文件
            #pragma multi_compile_fwdbase
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal:NORMAL;
                //获取切线方向
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal_dir:TEXCOORD1;
                float3 pos_world:TEXCOORD2;

                //切线方向和副法线方向
                float3 tangent_dir:TEXCOORD3;
                float3 binormal_dir:TEXCOORD4;

                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            sampler2D _AOMap;
            sampler2D _SpecMask;
            sampler2D _NormalMap;
            sampler2D _ParallaxMap;
            float4 _MainTex_ST;
            float4 _LightColor0;
            float _Shineness;
            float _NormalIntensity;
            float4 _AmbientColor;
            float _Parallax;
            //控制亮度
            float _SpecIntensity;

            float3 ACESFilem(float3 x){
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
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                //模型空间转世界空间

                    //这里因为如果模型不是等比例缩放的话法线会偏移，因为缩放会改变法线的方向和长度，所以要取unity_ObjectToWorld的逆矩阵unity_WorldToObject而且进行转置
                    o.normal_dir=normalize(mul(float4(v.normal,0.0),unity_WorldToObject).xyz);

                    //把切线方向转换到世界空间
                    o.tangent_dir=normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0))).xyz;

                    //叉乘求出副法线方向，v.tangent.w是为了处理不同平台中的副法线翻转问题
                    o.binormal_dir=normalize(cross(o.normal_dir,o.tangent_dir))*v.tangent.w;

                    //世界空间下的位置坐标不会因为缩放而影响，所以正常乘就行
                    o.pos_world=mul(unity_ObjectToWorld,v.vertex).xyz;

                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half shadow=SHADOW_ATTENUATION(i);

                //传递数据
                half3 normal_dir=normalize(i.normal_dir);
                half3 tangent_dir=normalize(i.tangent_dir);
                half3 binormal_dir=normalize(i.binormal_dir);

                //构造3*3矩阵方便计算
                float3x3 TBN=float3x3(tangent_dir,binormal_dir,normal_dir);


                //视差贴图技术
                    //计算观察方向
                    half3 view_dir=normalize(_WorldSpaceCameraPos.xyz-i.pos_world);

                    //view_tangentspace是法线根据视线平移的方向
                    half3 view_tangentspace=normalize(mul(TBN,view_dir));
                    
                    half2 uv_parallax=i.uv;

                    //循环多步执行偏移值迭代
                    for(int j=0;j<5;j++){
                        //采样高度图
                        half height=tex2D(_ParallaxMap,uv_parallax);

                        //因为是凹陷下去的所以是0.5-height，这代表着深度值，减去深度值也就意味着让他向下凹陷
                        uv_parallax=uv_parallax-(0.5-height)*(view_tangentspace.xy/view_tangentspace.z)*_Parallax*0.01;
                    }

                //diffuse贴图
                half4 base_color = tex2D(_MainTex, uv_parallax);
                //线性空间转换
                base_color=pow(base_color,2.2);
                //ao贴图
                half4 ao_color=tex2D(_AOMap,uv_parallax);
                //高光贴图
                half4 spec_mask=tex2D(_SpecMask,uv_parallax);
                //法线贴图
                half4 normal_map=tex2D(_NormalMap,uv_parallax);
                //解码法线贴图,用_NormalIntensity控制强度
                half3 normal_data=UnpackNormal(normal_map);
                normal_data.xy=normal_data.xy*_NormalIntensity;

                //计算出新的法线
                //normal_dir=normalize(tangent_dir*normal_data.x+binormal_dir*normal_data.y+normal_dir*normal_data.z);
                //注意这里normal_data.xyz和TBN的顺序不能反过来
                normal_dir=normalize(mul(normal_data.xyz,TBN));


                

                //计算diffuse=max(N*L,0.0)
                    //获取主方向光方向
                    half3 light_dir=normalize(_WorldSpaceLightPos0.xyz);
                    //计算主方向光和物体法线的点乘，拿到他们夹角的cos
                    half diff_term = min(shadow,max(0.0,dot(normal_dir, light_dir)));
                    //小于0的部分要舍弃，还要乘以光的颜色
                    half3 diffuse_color=diff_term*_LightColor0.xyz*base_color.xyz;
                //计算高光项specular=pow(max(R*V,0.0),smoothness)，R是光的反射方向
                    //计算R，注意这里要把lightdir反相
                    // half3 reflect_dir=reflect(-light_dir,normal_dir);
                    // half3 RdotV=dot(reflect_dir,view_dir);

                    //定义半程向量
                    half3 half_dir=normalize(light_dir+view_dir);
                    //用NdotH代替RdotV，消耗会小很多
                    half NdotH=dot(normal_dir,half_dir);
                    //_Shineness控制的是高光的大小，_Shineness越大高光大小越小
                    half3 spec_color=pow(max(NdotH,0.0),_Shineness)*diff_term*_LightColor0.xyz*_SpecIntensity*spec_mask.rgb;

                //全局环境光
                half3 ambient_color=UNITY_LIGHTMODEL_AMBIENT.rgb*base_color.xyz;
                //漫射光+高光+环境光，然后整体再乘以ao贴图
                half3 final_color=(diffuse_color+spec_color+ambient_color)*ao_color;

                //使用色调映射（这个建议还是在后处理的阶段用）
                half3 tone_color=ACESFilem(final_color);
                //线性空间转换到伽马空间
                tone_color=pow(tone_color,1.0/2.2);

                
                //return half4(shadow.xxx,1.0);
                 return half4(tone_color,1.0);
                // return half4(final_color,1.0);
            }
            ENDCG
        }

        //ForwardAdd的pass
        Pass
        {
            //这个pass用于计算主方向灯和顶点灯光
            Tags{"LightMode"="ForwardAdd"}
            //设置混合
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //函数库和头文件
            #pragma multi_compile_fwdadd
            #include "AutoLight.cginc"


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal_dir:TEXCOORD1;
                float3 pos_world:TEXCOORD2;
                float3 tangent_dir : TEXCOORD3;
                float3 binormal_dir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _LightColor0;
            float _Shineness;
            float4 _AmbientColor;
            float _SpecIntensity;
            sampler2D _AOMap;
            sampler2D _SpecMask;
            sampler2D _NormalMap;
            float _NormalIntensity;
            sampler2D _ParallaxMap;
            float _Parallax;

            float3 ACESFilm(float3 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return saturate((x*(a*x + b)) / (x*(c*x + d) + e));
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                //模型空间转世界空间
                //这里因为如果模型不是等比例缩放的话法线会偏移，因为缩放会改变法线的方向和长度，所以要取unity_ObjectToWorld的逆矩阵unity_WorldToObject而且进行转置
                o.normal_dir=normalize(mul(float4(v.normal,0.0),unity_WorldToObject).xyz);

                o.tangent_dir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.binormal_dir = normalize(cross(o.normal_dir,o.tangent_dir)) * v.tangent.w;
                //世界空间下的位置坐标不会因为缩放而影响，所以正常乘就行
                o.pos_world=mul(unity_ObjectToWorld,v.vertex).xyz;

                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half atten = LIGHT_ATTENUATION(i);
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                half3 normal_dir = normalize(i.normal_dir);
                half3 tangent_dir = normalize(i.tangent_dir);
                half3 binormal_dir = normalize(i.binormal_dir);
                float3x3 TBN = float3x3(tangent_dir, binormal_dir, normal_dir);
                half3 view_tangentspace = normalize(mul(TBN, view_dir));
                half2 uv_parallax = i.uv;

                for (int j = 0; j < 10; j++)
                {
                half height = tex2D(_ParallaxMap, uv_parallax);
                uv_parallax = uv_parallax - (0.5 - height) * view_tangentspace.xy * _Parallax * 0.01f;
                }

                half4 base_color = tex2D(_MainTex, uv_parallax);
                half4 ao_color = tex2D(_AOMap, uv_parallax);
                half4 spec_mask = tex2D(_SpecMask, uv_parallax);
                half4 normalmap = tex2D(_NormalMap, uv_parallax);
                half3 normal_data = UnpackNormal(normalmap);
                normal_data.xy = normal_data.xy * _NormalIntensity;
                normal_dir = normalize(mul(normal_data.xyz, TBN));
                //normal_dir = normalize(tangent_dir * normal_data.x * _NormalIntensity + binormal_dir * normal_data.y * _NormalIntensity + normal_dir * normal_data.z);

                half3 light_dir_point = normalize(_WorldSpaceLightPos0.xyz - i.pos_world);
                half3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                light_dir = lerp(light_dir, light_dir_point, _WorldSpaceLightPos0.w);
                half diff_term = min(atten,max(0.0,dot(normal_dir, light_dir)));
                half3 diffuse_color = diff_term * _LightColor0.xyz * base_color.xyz;

                half3 half_dir = normalize(light_dir + view_dir);
                half NdotH = dot(normal_dir, half_dir);
                half3 spec_color = pow(max(0.0, NdotH),_Shineness)
                * diff_term * _LightColor0.xyz * _SpecIntensity * spec_mask.rgb;

                half3 final_color = (diffuse_color + spec_color) * ao_color;
                return half4(final_color,1.0);
            }
            ENDCG
        }
    
    }
    //shadow caster的pass
    Fallback "Diffuse"
}
