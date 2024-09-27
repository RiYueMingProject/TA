Shader "Hidden/CustomBloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float4 _MainTex_TexelSize;
        float _Threshold;

        fixed4 frag_PreFilter (v2f_img i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv);
            
            //把图像中最亮的部分提取出来
            float br=max(max(col.r,col.g),col.b);

            //用_Threshold控制阈值，再除以一个br防止他过亮
            //用max运算保证他的亮度不为负数，同时保证除数不为0
            br=max(0.0f,(br-_Threshold))/max(br,0.00001f);

            //增加亮度
            col.rgb*=br;
            
            return col;
        }

        fixed4 frag_HorizontalBlur (v2f_img i) : SV_Target
    {
        fixed4 s=0;
        //采样横轴
        half2 uv1=i.uv+_MainTex_TexelSize.xy*half2(1,0)*-2.0;
        half2 uv2=i.uv+_MainTex_TexelSize.xy*half2(1,0)*-1.0;
        half2 uv3=i.uv;
        half2 uv4=i.uv+_MainTex_TexelSize.xy*half2(1,0)*1.0;
        half2 uv5=i.uv+_MainTex_TexelSize.xy*half2(1,0)*2.0;

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
        half2 uv1=i.uv+_MainTex_TexelSize.xy*half2(0,1)*-2.0;
        half2 uv2=i.uv+_MainTex_TexelSize.xy*half2(0,1)*-1.0;
        half2 uv3=i.uv;
        half2 uv4=i.uv+_MainTex_TexelSize.xy*half2(0,1)*1.0;
        half2 uv5=i.uv+_MainTex_TexelSize.xy*half2(0,1)*2.0;

        //乘以权重
        s+=tex2D(_MainTex,uv1)*0.05;
        s+=tex2D(_MainTex,uv2)*0.25;
        s+=tex2D(_MainTex,uv3)*0.40;
        s+=tex2D(_MainTex,uv4)*0.25;
        s+=tex2D(_MainTex,uv5)*0.05;
        
        return s;
    }
        ENDCG
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag_PreFilter
            
            ENDCG
        }

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

        //合并
        // pass{
        //     CGPROGRAM
        //     #pragma vertex vert_img
        //     #pragma fragment frag_UpGaussian
            
        //     ENDCG
        // }
    }
}
