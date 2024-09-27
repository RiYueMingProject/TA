using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()]
public class GaussianBlur : MonoBehaviour
{
    
    public Material material;
    [Range(0,10)]public int _Iteration=4;
    [Range(0,15)]public float _BlurRadius=5.0f;

    [Range(1,10)]public float _DonwSample=2.0f;

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

        //新建两个图像
        int width=(int)(src.width/_DonwSample);
        int height=(int)(src.height/_DonwSample);
        RenderTexture RT1=RenderTexture.GetTemporary(width,height);
        RenderTexture RT2=RenderTexture.GetTemporary(width,height);

        //把原图像传到RT1
        Graphics.Blit(src,RT1);

        material.SetVector("_BlurOffset", new Vector4(_BlurRadius / src.width, _BlurRadius / src.height, 0,0));
        //迭代模糊
        for(int i=0;i<_Iteration;i++){
            //对传进来的图像用material这个材质球渲染，结果放入destination
            Graphics.Blit(RT1,RT2,material,0);
            Graphics.Blit(RT2,RT1,material,1);
        }

        Graphics.Blit(RT1,dest);

        //释放图像
        RenderTexture.ReleaseTemporary(RT1);
        RenderTexture.ReleaseTemporary(RT2);
    }
}