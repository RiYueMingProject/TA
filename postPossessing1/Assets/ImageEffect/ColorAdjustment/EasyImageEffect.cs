using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//加上这个语句之后就能实时看到预览结果了
[ExecuteInEditMode()]
public class EasyImageEffect : MonoBehaviour
{
    public Material material;
    public float _Brightness=1;
    
    public float _Contrast=1;
    [Range(-1,1)] public float _Saturate=0;
    [Range(-1,1)] public float _Hueshift=0;
    [Range(0.05f,3)] public float _VignetteIntensity=1.5f;
    [Range(0.05f,5)] public float _VignetteRoundness=5;
    [Range(0.05f,5)] public float _VignetteSmoothness=5;

    // Start is called before the first frame update
    [System.Obsolete]
    void Start()
    {
        //判断材质是否有效
        if(material==null||SystemInfo.supportsImageEffects==false||material.shader==null||material.shader.isSupported==false){
            enabled=false;
            return;
        }
    }
    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        material.SetFloat("_Brightness",_Brightness);
        material.SetFloat("_Saturate",_Saturate);
        material.SetFloat("_Contrast",_Contrast);
        material.SetFloat("_HueShift",_Hueshift);
        material.SetFloat("_VignetteIntensity",_VignetteIntensity);
        material.SetFloat("_VignetteRoundness",_VignetteRoundness);
        material.SetFloat("_VignetteSmoothness",_VignetteSmoothness);
        //对传进来的source图像用material这个材质球渲染，结果放入destination
        Graphics.Blit(src,dest,material,0);
    }
}
