// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
Shader "CS0102/MiniShader1"
{
	Properties
	{
		//_Cutout("Cutout",Range(-0.1,1.1))=0.0
		_MainColor("MainColor",Color)=(1,1,1,1)
		_Speed("Speed",Vector)=(1,1,0,0)
		_Emiss("Emiss",Float)=1.0
		//_NoiseTex("Noise Tex",2D)="white"{}

		// _value("value",Float)=0.0
		// _Range("Range",Range(0.0,1.0))=0.0
		// _Vector("Vector",Vector)=(1,1,1,1)
		// _Color("Color",Color)=(1,1,1,1)
		_MainTex("MainTex",2D)="white"{}
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode",float)=2

		}
	SubShader{
		Tags{"Queue"="Transparent"}
		Pass{
			ZWrite Off
			//Blend SrcAlpha OneMinusSrcAlpha
			Blend SrcAlpha One
			Cull [_CullMode]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata{
				float4 vertex:POSITION;
				float2 uv:TEXCOORD0;//第一套uv
				//float3 normal:NORMAL;
				//float4 color:COLOR;
				};

			struct v2f{
				float4 pos:SV_POSITION;
				float2 uv:TEXCOORD0;//通用储存器，插值器，可以存放任何东西
				float2 pos_uv:TEXCOORD1;
				};

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Cutout;
			float4 _Speed;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float4 _MainColor;
			float _Emiss;

			v2f vert(appdata v){
				v2f o;
				// float4 pos_world=mul(unity_ObjectToWorld,v.vertex);//模型空间转世界空间
				// float4 pos_view=mul(UNITY_MATRIX_V,pos_world);//世界空间转相机空间
				// float4 pos_clip=mul(UNITY_MATRIX_P,pos_view);//转化到裁剪空间
				o.pos=UnityObjectToClipPos(v.vertex);
				// o.pos=pos_clip;
				//让_MainTex_ST的xy分量参与到计算当中，zw分量进行偏移
				o.uv=v.uv*_MainTex_ST.xy+_MainTex_ST.zw;

				o.pos_uv=v.vertex.xy*_MainTex_ST.xy+_MainTex_ST.zw;
				return o;
				}
			float4 frag(v2f i):SV_Target{
				// half gradient=tex2D(_MainTex,i.uv+_Time.y*_Speed.xy).r;
				// half noise=tex2D(_NoiseTex,i.uv+_Time.y*_Speed.zw).r;
				// clip(gradient-noise-_Cutout);
				half3 col=_MainColor.xyz*_Emiss;
				half alpha=saturate(tex2D(_MainTex,i.uv).r*_MainColor.a*_Emiss);

				return float4(col,alpha);
				}
			ENDCG
			}
		}

	}

