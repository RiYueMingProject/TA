using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()]
public class CustomBloom : MonoBehaviour
{
    public Material material;
    [Range(0,10)]public float _Threshold=0;
     [Range(0,10)]public int _Iteration=4;
    [Range(0,15)]public float _BlurRadius=5.0f;

    [Range(1,10)]public float _DonwSample=2.0f;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest) {
        material.SetFloat("_Threshold",_Threshold);

        //双重模糊
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
                //降采样
                RenderTexture.ReleaseTemporary(RT2);
                width=width/2;
                height=height/2;
                RT2=RenderTexture.GetTemporary(width,height);
                Graphics.Blit(RT1,RT2,material,1);


                RenderTexture.ReleaseTemporary(RT1);
                width=width/2;
                height=height/2;
                RT1=RenderTexture.GetTemporary(width,height);
                Graphics.Blit(RT2,RT1,material,2);
            }

            for(int i=0;i<_Iteration;i++){
                //升采样
                RenderTexture.ReleaseTemporary(RT2);
                width=width*2;
                height=height*2;
                RT2=RenderTexture.GetTemporary(width,height);
                Graphics.Blit(RT1,RT2,material,1);


                RenderTexture.ReleaseTemporary(RT1);
                width=width*2;
                height=height*2;
                RT1=RenderTexture.GetTemporary(width,height);
                Graphics.Blit(RT2,RT1,material,2);
            }
            Graphics.Blit(RT1,dest);

            //释放图像
            RenderTexture.ReleaseTemporary(RT1);
            RenderTexture.ReleaseTemporary(RT2);
    }
}
