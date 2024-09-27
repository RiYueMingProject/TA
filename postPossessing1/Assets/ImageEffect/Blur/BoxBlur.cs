using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

//加上这个语句之后就能实时看到预览结果了
[ExecuteInEditMode()]
public class BoxBlur : MonoBehaviour
{
    public Material material;
    [Range(1,10)]public int _Iteration=0;
    [Range(1,10)]public float _BlurOffset=0;

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

        material.SetFloat("_BlurOffset",_BlurOffset);

        //新建两个图像
        int width=(int)(src.width/_DonwSample);
        int height=(int)(src.height/_DonwSample);
        RenderTexture RT1=RenderTexture.GetTemporary(width,height);
        RenderTexture RT2=RenderTexture.GetTemporary(width,height);

        //把原图像传到RT1
        Graphics.Blit(src,RT1);

        //迭代模糊
        for(int i=0;i<_Iteration;i++){
            //对传进来的图像用material这个材质球渲染，结果放入destination
            Graphics.Blit(RT1,RT2,material,1);
            Graphics.Blit(RT2,RT1,material,1);
        }

        Graphics.Blit(RT1,dest);

        //释放图像
        RenderTexture.ReleaseTemporary(RT1);
        RenderTexture.ReleaseTemporary(RT2);
    }
}
