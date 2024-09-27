Shader "AS0104/LonghornCode"
{
    Properties
    {
        _DiffuseTex("DiffuseTex",2D)="white"{}
        _DiffuseIntensity("DiffuseIntensity",Float)=1.0
        _Matcap("Matcap",2D)="white"{}
        _MatcapIntensity("MatcapIntensity",Float)=1.0
        _RampTex("Ramp Tex",2D)="white"{}
        _MatcapAdd("MatcapAdd",2D)="white"{}
        _MatcapAddIntensity("MatcapAddIntensity",Float)=1.0
        _NormalMap("NormalMap",2D)="white"{}
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                
                //存储法线
                float3 normal:NORMAL;
            };

            
            struct v2f
            {
                //System-Value Semantic系统值语义，表示顶点在裁剪空间中的位置，也就是经过模型变换，视图变换，投影变换之后的最终位置
                //我们要把这个最终位置传递给片元着色器
                float4 vertex:SV_POSITION;
                float2 uv : TEXCOORD0;
                //传递世界空间中的法线和位置信息
                float3 normal_world:TEXCOORD1;
                float3 pos_world:TEXCOORD2;
            };

            //定义变量--------------------
                
                //定义matcap贴图和matcap强度
                sampler2D _Matcap;
                float _MatcapIntensity;
                //存储干涉贴图
                sampler2D _RampTex;
                //存储diffuse贴图
                sampler2D _DiffuseTex;
                float _DiffuseIntensity;
                //存储法线贴图
                sampler2D _NormalMap;
                //matcap重复质感和强度
                sampler2D _MatcapAdd;
                float _MatcapAddIntensity;
            //------------------------------

            //顶点shader
            v2f vert (appdata v)
            {
                v2f o;
                //转换到裁剪空间
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                
                //进行法线转换
                //unity_WorldToObject是unity_ObjectToWorld 的逆矩阵
                //这里让float4(v.normal,0.0)乘unity_WorldToObject其实相当于(B^T)*(A^T),相当于让这个法线乘以这个矩阵的转置
                float3 normal_world=mul(float4(v.normal,0.0),unity_WorldToObject);
                o.normal_world=normal_world;

                //传递顶点在世界空间中的位置
                o.pos_world=mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            //片元shder
            fixed4 frag (v2f i) : SV_Target
            {
                //世界环境下的法线归一化
                half3 normal_world=normalize(i.normal_world);
                half3 normal_color=tex2D(_NormalMap,i.uv);
                
                //normal_world.Normal=normal_color;

                //base matcap--------------------
                
                //把他转换为相机空间
                    half3 normal_viewspace=mul(UNITY_MATRIX_V,float4(normal_world,0.0)).xyz;

                    //计算matcap的uv，因为normal_viewspace是从-1到1的，我们希望他是从0到1，所以就给他+1然后*0.5
                    //而且因为uv是二维的所以float2就够了
                    half2 uv_matcap=(normal_viewspace+float2(1.0,1.0))*0.5;

                    //这里用uv对matcap贴图取样,因为要传出RGBA所以是4维
                    half4 matcap_color=tex2D(_Matcap,uv_matcap)*_MatcapIntensity;

                    //对diffuse采样
                    half4 diffuse_color=tex2D(_DiffuseTex,i.uv)*_DiffuseIntensity;
                //-------------------------------------

                //Gradient干涉效果----------------------------
                    //求视线向量，用对应的顶点减去相机的位置，就是实现向量，同时进行归一化
                    half3 view_dir=normalize(_WorldSpaceCameraPos.xyz-i.pos_world);
                    //执行NdotV,同时用saturate把他限制在0,1范围内
                    half NdotV=saturate(mul(i.normal_world,view_dir));
                    //计算菲涅尔，菲涅尔就是NdotV反过来，就用1减他
                    half fresnel=1.0-NdotV;

                    half2 uv_Gradient=half2(fresnel,0.5);
                    half4 Gradient_color=tex2D(_RampTex,uv_Gradient);
                //-------------------------------------

                //再加一层matcap增加效果--------------
                    half4 matcap_add_color=tex2D(_MatcapAdd,uv_matcap)*_MatcapAddIntensity;
                //------------------------------------

                //把上面的结果乘起来
                half4 combined_color=diffuse_color*matcap_color*Gradient_color+matcap_add_color;

                return combined_color;
            }
            ENDCG
        }
    }
}
