Shader "Hidden/GaussianBlur"
{

    CGINCLUDE
    #include "UnityCG.cginc"

    sampler2D _MainTex;
    
    //获取每个像素的偏移量
    //x=1/width,y=1/height,z=width,w=height
    float4 _MainTex_TexelSize;
    //采样偏移值
    float4 _BlurOffset;


    fixed4 frag_HorizontalBlur (v2f_img i) : SV_Target
    {
        fixed4 s=0;
        //采样横轴
        half2 uv1=i.uv+_BlurOffset.xy*half2(1,0)*-2.0;
        half2 uv2=i.uv+_BlurOffset.xy*half2(1,0)*-1.0;
        half2 uv3=i.uv;
        half2 uv4=i.uv+_BlurOffset.xy*half2(1,0)*1.0;
        half2 uv5=i.uv+_BlurOffset.xy*half2(1,0)*2.0;

        //乘以权重
        s+=tex2D(_MainTex,uv1)*0.05;
        s+=tex2D(_MainTex,uv2)*0.25;
        s+=tex2D(_MainTex,uv3)*0.40;
        s+=tex2D(_MainTex,uv4)*0.25;
        s+=tex2D(_MainTex,uv5)*0.05;
        
        return s;
    }

    fixed4 frag_VerticalBlur (v2f_img i) : SV_Target
    {
        fixed4 s=0;
        //采样纵轴
        half2 uv1=i.uv+_BlurOffset.xy*half2(0,1)*-2.0;
        half2 uv2=i.uv+_BlurOffset.xy*half2(0,1)*-1.0;
        half2 uv3=i.uv;
        half2 uv4=i.uv+_BlurOffset.xy*half2(0,1)*1.0;
        half2 uv5=i.uv+_BlurOffset.xy*half2(0,1)*2.0;

        //乘以权重
        s+=tex2D(_MainTex,uv1)*0.05;
        s+=tex2D(_MainTex,uv2)*0.25;
        s+=tex2D(_MainTex,uv3)*0.40;
        s+=tex2D(_MainTex,uv4)*0.25;
        s+=tex2D(_MainTex,uv5)*0.05;
        
        return s;
    }
    ENDCG
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurOffset("BlurOffset",Float)=1
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_HorizontalBlur
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_VerticalBlur
            ENDCG
        }
    }
}