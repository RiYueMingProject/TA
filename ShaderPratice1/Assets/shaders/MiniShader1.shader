Shader "CS0102/Rim"
{
	Properties
	{
		//_Cutout("Cutout",Range(-0.1,1.1))=0.0
		_MainColor("MainColor",Color)=(1,1,1,1)
		_Speed("Speed",Vector)=(1,1,0,0)
		_Emiss("Emiss",Float)=1.0
		_RimPower("_RimePower",Float)=1.0
		
		_MainTex("MainTex",2D)="white"{}
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode",float)=2

		}
	SubShader{
		Tags{"Queue"="Transparent"}
		Pass {
			Cull Off 
			ZWrite On 
			ColorMask 0
			CGPROGRAM
			float4 _Color;
			#pragma vertex vert 
			#pragma fragment frag

			float4 vert(float4 vertexPos : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertexPos);
			}

			float4 frag(void) : COLOR
			{
				return _Color;
			}
			ENDCG
		}

		Pass{
			ZWrite On
			//Blend SrcAlpha OneMinusSrcAlpha
			Blend SrcAlpha One
			Cull [_CullMode]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata{
				float4 vertex:POSITION;
				float2 texcoord0:TEXCOORD0;
				float3 normal:NORMAL;
				
				};

			struct v2f{
				float4 pos:SV_POSITION;
				float2 uv:TEXCOORD0;//通用储存器，插值器，可以存放任何东西
				float3 normal_world:TEXCOORD1;
				float3 view_world:TEXCOORD2;
				};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainColor;
			float _Emiss;
			float _RimPower;

			v2f vert(appdata v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
				//计算normal值
				o.normal_world=normalize(mul(float4(v.normal,0.0),unity_WorldToObject).xyz);
				//先求出世界空间下的顶点坐标
				float3 pos_world=mul(unity_ObjectToWorld,v.vertex).xyz;
				
				//_WorldSpaceCameraPos:拿到世界空间下摄像机的位置
				//得到视线向量
				o.view_world=normalize(_WorldSpaceCameraPos.xyz-pos_world);

				o.uv=v.texcoord0*_MainTex_ST.xy+_MainTex_ST.zw;
				return o;
				}
			float4 frag(v2f i):SV_Target{
				float3 normal_world=normalize(i.normal_world);
				float3 view_world=normalize(i.view_world);
				float NdotV=saturate(dot(normal_world,view_world));

				float3 col=_MainColor.xyz*_Emiss;

				float fresnel=pow(1.0-NdotV,_RimPower);
				float alpha=saturate(fresnel*_Emiss);

				return float4(col,alpha);
				
				}
			ENDCG
			}
		}

	}

