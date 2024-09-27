 using UnityEngine;
 using System.Collections;
 
 [RequireComponent(typeof(Camera))]
 public class DepthRenderer : MonoBehaviour {
 
     GameObject depthCamera=null;
     Shader replacementShader=null;
 
     // Use this for initialization
     void Start () 
     {
         depthCamera=new GameObject();
         depthCamera.AddComponent<Camera>();
         depthCamera.GetComponent<Camera>().enabled=true;
         depthCamera.hideFlags=HideFlags.HideAndDontSave;
         
         depthCamera.GetComponent<Camera>().CopyFrom(GetComponent<Camera>());
         depthCamera.GetComponent<Camera>().cullingMask=1<<0; // default layer for now
         depthCamera.GetComponent<Camera>().clearFlags=CameraClearFlags.Depth;
 
         replacementShader=Shader.Find("RenderDepth");
         if (replacementShader==null)
         {
             Debug.LogError("could not find 'RenderDepth' shader");
         }
     }
     
     // Update is called once per frame
     void OnPreRender () 
     {
         if (replacementShader!=null)
         {
             Camera camCopy=depthCamera.GetComponent<Camera>();
 
             // copy position and location;
             camCopy.transform.position=GetComponent<Camera>().transform.position;
             camCopy.transform.rotation=GetComponent<Camera>().transform.rotation;
             
             camCopy.RenderWithShader(replacementShader, "RenderType");
         }
     }
 }