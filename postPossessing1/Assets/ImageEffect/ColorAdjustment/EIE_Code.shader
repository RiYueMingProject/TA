Shader "Hidden/EIE_Code"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Brightness("Brightness",Float)=1
        _Saturation("Saturate",Range(0,1))=0
        _Contrast("Contrast",Float)=1
        _HueShift("HueShift",Range(0,1))=0
        _VignetteIntensity("VignetteIntensity",Range(0.05,3))=1.5
        _VignetteRoundness("VignetteRoundness",Range(0.05,5))=5
        _VignetteSmoothness("VignetteSmoothness",Range(0.05,5))=5
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


            //复制的ASE的HSV和RGB互相转化的函数
                float3 HSVToRGB( float3 c )
                {
                    float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
                    float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
                    return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
                }
                
                float3 RGBToHSV(float3 c)
                {
                    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                    float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
                    float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
                    float d = q.x - min( q.w, q.y );
                    float e = 1.0e-10;
                    return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
                }

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

            
            float _Brightness;
            float _Saturate;
            float _Contrast;
            float _HueShift;
            float _VignetteIntensity;
            float _VignetteRoundness;
            float _VignetteSmoothness;

            sampler2D _MainTex;

            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                //调整亮度
                    fixed3 final_color=col.rgb*_Brightness;

                //计算饱和度灰度图
                    float lumin=dot(final_color,float3(0.22,0.707,0.071));
                //调整饱和度
                    final_color=lerp(final_color,lumin,0-_Saturate);

                //调整对比度，本质就是和rgb都为0.5的灰色图做插值
                    final_color=lerp(float3(0.5,0.5,0.5),final_color,_Contrast);

                //调整色相
                    float3 hsv_col=RGBToHSV(final_color);
                    hsv_col.x=hsv_col.x+_HueShift;
                    final_color=HSVToRGB(hsv_col);

                //暗角晕影效果模拟人眼
                    //左加右减，让他的uv向右移动0.5个单位然后取绝对值，这样一来他的四个角就绝对是白色
                    //我们希望上下也能呈现这样的效果，所以把他变成二维变量，然后对y同理
                    //VignetteIntensity控制uv的强度,VignetteIntensity越大，遮罩图中白色的部分就越大
                    
                    float2 shift_uv=abs(i.uv-float2(0.5,0.5))*_VignetteIntensity;
                    //用VignetteRoundness控制晕影范围，因为uv是从0到1的，所以VignetteRoundness越大其中接近0的部分就越多，所以就越黑
                    shift_uv=pow(saturate(shift_uv),_VignetteRoundness);

                    //shift_uv是个二维变量，把他变成一维，就求他的模长,结果会是四个角全白，中间方框黑色
                    float dist=length(shift_uv);
                    //结合uv的x和y
                    //这里dist*dist是为了让他的效果更加柔和
                    //最终1-dist*dist让他反相，同时使用幂函数来调整渐变的平滑度，值越高过渡越平滑
                    float shadow=pow(saturate(1.0-dist*dist),_VignetteSmoothness);

                    //应用晕影效果
                    final_color=final_color*shadow;

                return fixed4(final_color,col.a);
                //return dist;
            }
            ENDCG
        }
    }
}
