Shader "CS0105/vine_code"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Expand("Expand",Float)=0
        _Scale("Scale",Float)=0
        _Grow("Grow",Range(-2,2))=0
        _GrowMin("GrowMin",Range(0,1))=0
        _GrowMax("GrowMax",Range(0,1.5))=0
        _EndMin("EndMin",Range(0,1))=0
        _EndMax("EndMax",Range(0,1.5))=0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Tags{"Queue"="AlphaTest"}
        Pass
        {
            Cull Off
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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                
                float4 vertex : SV_POSITION;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            

            float _Expand;
            float _Scale;
            float _Grow;
            float _GrowMin;
            float _GrowMax;
            float _EndMin;
            float _EndMax;

            v2f vert (appdata v)
            {
                v2f o;
                
                
                //用grow控制y轴uv
                //v.uv.y=v.uv.y-_Grow;

                //weight_expand主要是使用smoothstep对黑白关系进行插值，让他更加平滑
                float weight_expand=smoothstep(_GrowMin,_GrowMax,v.uv.y-_Grow);

                //通过weight_end限制他尖端最长生长到哪
                float weight_end=smoothstep(_EndMin,_EndMax,v.uv.y);
                
                //限定了max之后，随着grow增大，藤蔓就不会一直增长，而是停在了weight_end这里
                float max_len=max(weight_end,weight_expand);
            
                
                //法相顶点偏移
                float3 LocalVertexOffset=v.normal*_Expand*0.1*max_len;
                
                //法相顶点缩放
                float3 LocalVertexScale=v.normal*_Scale*0.1;

                //对顶点应用这些法相缩放和偏移
                float3 final_offset=LocalVertexOffset+LocalVertexScale;
                v.vertex.xyz=v.vertex.xyz+final_offset;
                
                //转换到裁剪空间
                o.vertex=UnityObjectToClipPos(v.vertex);
                o.uv=v.uv;
                
                

                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex,i.uv);

                //相当于opacity mask，反相之后把其中小于0的部分都去掉
                clip(1-(i.uv.y-_Grow));
                float col2=1-i.uv.y;
                
                return col;
            }
            ENDCG
        }
    }
}
