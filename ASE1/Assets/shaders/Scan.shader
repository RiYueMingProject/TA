// Made with Amplify Shader Editor v1.9.6
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Scan/one"
{
	Properties
	{
		_MainText("MainText", 2D) = "white" {}
		_FlowEmiss("FlowEmiss", 2D) = "white" {}
		_RimMin("RimMin", Range( 0 , 1)) = 0.2348889
		_RimMax("RimMax", Range( 0 , 2)) = 0.810531
		_RimIntensity("RimIntensity", Range( 0 , 2)) = 0.3854907
		_Vector0("Vector 0", Vector) = (0,0,0,0)
		_flowIntensity("flowIntensity", Float) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Pass
		{
			ColorMask 0
			ZWrite On
		}

		Tags{ "RenderType" = "Custom"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		Blend SrcAlpha One
		
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float3 worldNormal;
			float3 viewDir;
			float2 uv_texcoord;
			float3 worldPos;
		};

		uniform float _RimIntensity;
		uniform float _RimMin;
		uniform float _RimMax;
		uniform sampler2D _MainText;
		uniform float4 _MainText_ST;
		uniform sampler2D _FlowEmiss;
		uniform float3 _Vector0;
		uniform float _flowIntensity;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float4 color4 = IsGammaSpace() ? float4(0.7169812,0.5387905,0.3618726,0.5607843) : float4(0.4725527,0.2517178,0.1076966,0.5607843);
			float4 color22 = IsGammaSpace() ? float4(0,0.9615137,0.9811321,1) : float4(0,0.9146731,0.957614,1);
			float3 ase_worldNormal = i.worldNormal;
			float dotResult7 = dot( ase_worldNormal , i.viewDir );
			float clampResult8 = clamp( dotResult7 , 0.0 , 1.0 );
			float smoothstepResult18 = smoothstep( _RimMin , _RimMax , ( 1.0 - clampResult8 ));
			float2 uv_MainText = i.uv_texcoord * _MainText_ST.xy + _MainText_ST.zw;
			float clampResult47 = clamp( ( smoothstepResult18 + pow( tex2D( _MainText, uv_MainText ).r , 0.8 ) ) , 0.0 , 1.0 );
			float4 lerpResult23 = lerp( color4 , ( color22 * _RimIntensity ) , clampResult47);
			float3 ase_worldPos = i.worldPos;
			float4 appendResult35 = (float4(ase_worldPos.x , ase_worldPos.y , 0.0 , 0.0));
			float3 objToWorld36 = mul( unity_ObjectToWorld, float4( _Vector0, 1 ) ).xyz;
			float4 appendResult38 = (float4(objToWorld36.x , objToWorld36.y , 0.0 , 0.0));
			float4 tex2DNode26 = tex2D( _FlowEmiss, ( ( ( appendResult35 - appendResult38 ) * float4( float2( 2,1 ), 0.0 , 0.0 ) ) + float4( ( float2( 0,1 ) * _Time.y ), 0.0 , 0.0 ) ).xy );
			float4 flow52 = tex2DNode26;
			o.Emission = ( lerpResult23 + flow52 ).rgb;
			float flowAlpha54 = tex2DNode26.a;
			float clampResult48 = clamp( ( clampResult47 + ( flowAlpha54 * _flowIntensity ) ) , 0.0 , 1.0 );
			o.Alpha = clampResult48;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = worldViewDir;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutput o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutput, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19600
Node;AmplifyShaderEditor.CommentaryNode;57;-1632,1230;Inherit;False;1844;611;流光;15;37;34;36;35;38;30;32;39;51;31;50;28;26;54;52;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector3Node;37;-1582,1488;Inherit;False;Property;_Vector0;Vector 0;6;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;34;-1454,1280;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;36;-1390,1504;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;35;-1166,1296;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;38;-1166,1504;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;6;-1152,704;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;5;-1120,544;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;30;-910,1728;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;32;-782,1600;Inherit;False;Constant;_Speed;Speed;3;0;Create;True;0;0;0;False;0;False;0,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleSubtractOpNode;39;-958,1312;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Vector2Node;51;-974,1520;Inherit;False;Constant;_FlowTilling;FlowTilling;8;0;Create;True;0;0;0;False;0;False;2,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DotProductOpNode;7;-768,688;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-558,1664;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-798,1408;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ClampOpNode;8;-624,672;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-622,1296;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;9;-416,720;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-672,816;Inherit;False;Property;_RimMin;RimMin;3;0;Create;True;0;0;0;False;0;False;0.2348889;0.2348889;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-672,944;Inherit;False;Property;_RimMax;RimMax;4;0;Create;True;0;0;0;False;0;False;0.810531;0.810531;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-992,128;Inherit;True;Property;_MainText;MainText;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RangedFloatNode;45;-848,352;Inherit;False;Constant;_TextPower;TextPower;8;0;Create;True;0;0;0;False;0;False;0.8;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;26;-494,1328;Inherit;True;Property;_FlowEmiss;FlowEmiss;2;0;Create;True;0;0;0;False;0;False;-1;4b437af2554f8c549bd596e8626defc5;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.PowerNode;44;-544,160;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;18;-256,736;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-30,1568;Inherit;False;flowAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-432,576;Inherit;False;Property;_RimIntensity;RimIntensity;5;0;Create;True;0;0;0;False;0;False;0.3854907;0.3854907;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;46;-160,144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;55;-64,848;Inherit;False;54;flowAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-112,960;Inherit;False;Property;_flowIntensity;flowIntensity;7;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;22;-704,432;Inherit;False;Constant;_RimColor;RimColor;7;0;Create;True;0;0;0;False;0;False;0,0.9615137,0.9811321,1;0.1966002,0.6213474,0.8867924,1;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-176,400;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;47;32,208;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;240,912;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;4;-576,304;Inherit;False;Constant;_InnerColor;InnerColor;8;0;Create;True;0;0;0;False;0;False;0.7169812,0.5387905,0.3618726,0.5607843;0.7169812,0.5387905,0.3618726,0.5607843;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RegisterLocalVarNode;52;-126,1344;Inherit;False;flow;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;23;80,336;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;41;288,640;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;53;-16,528;Inherit;False;52;flow;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;3;-736,-288;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;40;256,320;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;48;448,560;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;608,320;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;Scan/one;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;True;0;Custom;0.5;True;True;0;False;Custom;;Transparent;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;8;5;False;;1;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;16;FLOAT4;0,0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;36;0;37;0
WireConnection;35;0;34;1
WireConnection;35;1;34;2
WireConnection;38;0;36;1
WireConnection;38;1;36;2
WireConnection;39;0;35;0
WireConnection;39;1;38;0
WireConnection;7;0;5;0
WireConnection;7;1;6;0
WireConnection;31;0;32;0
WireConnection;31;1;30;0
WireConnection;50;0;39;0
WireConnection;50;1;51;0
WireConnection;8;0;7;0
WireConnection;28;0;50;0
WireConnection;28;1;31;0
WireConnection;9;0;8;0
WireConnection;26;1;28;0
WireConnection;44;0;1;1
WireConnection;44;1;45;0
WireConnection;18;0;9;0
WireConnection;18;1;19;0
WireConnection;18;2;20;0
WireConnection;54;0;26;4
WireConnection;46;0;18;0
WireConnection;46;1;44;0
WireConnection;24;0;22;0
WireConnection;24;1;25;0
WireConnection;47;0;46;0
WireConnection;42;0;55;0
WireConnection;42;1;43;0
WireConnection;52;0;26;0
WireConnection;23;0;4;0
WireConnection;23;1;24;0
WireConnection;23;2;47;0
WireConnection;41;0;47;0
WireConnection;41;1;42;0
WireConnection;40;0;23;0
WireConnection;40;1;53;0
WireConnection;48;0;41;0
WireConnection;0;2;40;0
WireConnection;0;9;48;0
ASEEND*/
//CHKSM=925FC9CE0F4FD5CE275D77E38404D496E26643E6