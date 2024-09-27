Shader "Hidden/BrokenGlass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GlassCrack("GlassCrack",Float)=1
        _GlassMask("GlassMask",2D)="black"{}
        _GlassNormal("GlassNormal",2D)="bump"{}
        _Distort("Distort",Float)=1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _GlassMask;
            float4 _GlassMask_ST;
            float _GlassCrack;
            sampler2D _MainTex;
            sampler2D _GlassNormal;
            float _Distort;

            fixed4 frag (v2f_img i) : SV_Target
            {
                
                //计算屏幕的宽高比
                float aspect=_ScreenParams.x/_ScreenParams.y;

                //计算玻璃贴图的uv
                half2 glass_uv=i.uv*_GlassMask_ST.xy+_GlassMask_ST.zw;
                glass_uv.x=glass_uv.x*aspect;
                
                //设置法线贴图
                fixed3 glass_normal=UnpackNormal(tex2D(_GlassNormal,glass_uv));
                


                //smoothstep平滑埃尔米特插值，lerp是线性插值
                //smoothstep会在接近结束时减慢速度
                float2 shadow=1-smoothstep(0.95,1,abs(i.uv*2-1));
                float vfactor=shadow.x*shadow.y;

                //设置uv扭曲
                half2 uv_distort=i.uv+glass_normal.xy*_Distort*vfactor;
                //用扭曲后的uv采样maintex
                fixed4 col=tex2D(_MainTex,uv_distort);

                fixed3 final_col=col.rgb;

                //把图中白色的部分抠出来
                half glass_opacity=tex2D(_GlassMask,glass_uv).r;
                //用glass_opacity控制lerp的系数，作为遮罩，其中黑色的部分就是原本的颜色，白色的部分直接用(1,1,1)填充
                //这里因为我使用的贴图里面黑色的部分才是玻璃裂纹，所以使用的是1-glass_opacity
                final_col=lerp(final_col,_GlassCrack.xxx,1-glass_opacity);

                //return shadow.xxxx;
                return fixed4(final_col,col.a);
            }
            ENDCG
        }
    }
}
