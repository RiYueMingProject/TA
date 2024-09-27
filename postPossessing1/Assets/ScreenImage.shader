Shader "CS05/ScreenImage"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                
                float4 pos : SV_POSITION;
                //定义屏幕空间坐标
                float4 screen_pos:TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_HDR;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv=v.texcoord;

                o.screen_pos=o.pos;
                //_ProjectionParams.x解决平台不同导致的uv翻转问题
                o.screen_pos.y=o.screen_pos.y*_ProjectionParams.x;

                //unity自带的根据设备转屏幕空间uv,和上面的uv翻转是一样的
                //o.screen_pos=ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //做透视除法，xy都除以w，就能得到NDC标准化设备坐标
                    //这样得到的结果是在-1到1之间
                    //这段代码只能在片元shader里写，因为如果在顶点shader里写，他就不是个线性的值，光栅化插值会产生不好的影响
                    //记得规避除数为0的情况
                    half2 screen_uv=i.screen_pos.xy/(i.screen_pos.w+0.000001);
                    //把他规范到0-1
                    screen_uv=(screen_uv+1)/2;

                //对屏幕空间uv采样
                fixed4 col = tex2D(_MainTex, screen_uv);
                
                //HDR解码
                col.rgb=DecodeHDR(col,_MainTex_HDR);
                return col;
            }
            ENDCG
        }
    }
}
