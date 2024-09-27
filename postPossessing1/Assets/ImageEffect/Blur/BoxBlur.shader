Shader "Hidden/BoxBlur"
{

    CGINCLUDE
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    
    //获取每个像素的偏移量
    //x=1/width,y=1/height,z=width,w=height
    float4 _MainTex_TexelSize;
    //采样偏移值
    float _BlurOffset;


    fixed4 frag_BoxFilter_4Tap (v2f_img i) : SV_Target
    {
        fixed4 s=0;
        //采样偏移值，采样上下左右四个角的像素
        fixed4 d=_MainTex_TexelSize.xyxy*half4(-1,-1,1,1)*_BlurOffset;
        s+=tex2D(_MainTex,i.uv+d.zw);
        s+=tex2D(_MainTex,i.uv+d.zy);
        s+=tex2D(_MainTex,i.uv+d.xw);
        s+=tex2D(_MainTex,i.uv+d.xy);

        s/=4;
        return s;
    }

    fixed4 frag_BoxFilter_9Tap (v2f_img i) : SV_Target
    {
        fixed4 s=0;
        //采样偏移值，采样上下左右四个角的像素
        fixed4 d=_MainTex_TexelSize.xyxy*half4(-1,-1,1,1)*_BlurOffset;

        s+=tex2D(_MainTex,i.uv+d.zw);
        s+=tex2D(_MainTex,i.uv+d.zy);
        s+=tex2D(_MainTex,i.uv+d.xw);
        s+=tex2D(_MainTex,i.uv+d.xy);

        s+=tex2D(_MainTex,i.uv+half2(0.0,d.w));
        s+=tex2D(_MainTex,i.uv+half2(0.0,d.y));
        s+=tex2D(_MainTex,i.uv+half2(d.z,0.0));
        s+=tex2D(_MainTex,i.uv+half2(d.x,0.0));

        s/=9.0;
        return s;
    }
    ENDCG
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurOffset("BlurOffset",Float)=0
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_BoxFilter_4Tap
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_BoxFilter_9Tap
            ENDCG
        }
    }
}
