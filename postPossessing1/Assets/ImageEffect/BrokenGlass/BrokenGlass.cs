using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//加上这个语句之后就能实时看到预览结果了
[ExecuteInEditMode()]
public class BrokenGlass : MonoBehaviour
{
    public Material material;
    

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
        
        //对传进来的source图像用material这个材质球渲染，结果放入destination
        Graphics.Blit(src,dest,material,0);
    }
}
