// CoarseInsctr.fx:
// Renders coarse unshadowed inscattering for EVERY epipolar sample and computes extinction.
// Coarse inscattering is used to refine sampling, while extinction is then transformed to 
// screen space, if extinction evaluation mode is EXTINCTION_EVAL_MODE_EPIPOLAR

#include "AtmosphereShadersCommon.fxh"

cbuffer cbParticipatingMediaScatteringParams
{
    AirScatteringAttribs g_MediaParams;
}

cbuffer cbCameraAttribs
{
    CameraAttribs g_CameraAttribs;
}

cbuffer cbLightParams
{
    LightAttribs g_LightAttribs;
}

cbuffer cbPostProcessingAttribs
{
    PostProcessingAttribs g_PPAttribs;
};

cbuffer cbMiscDynamicParams
{
    MiscDynamicParams g_MiscParams;
}

Texture2D<float2> g_tex2DOccludedNetDensityToAtmTop;
SamplerState g_tex2DOccludedNetDensityToAtmTop_sampler;

Texture2D<float>  g_tex2DEpipolarCamSpaceZ;

Texture2D<float4> g_tex2DSliceUVDirAndOrigin;

Texture2D<float2> g_tex2DMinMaxLightSpaceDepth;

Texture2DArray<float> g_tex2DLightSpaceDepthMap;
SamplerComparisonState g_tex2DLightSpaceDepthMap_sampler;

Texture2D<float2> g_tex2DCoordinates;

Texture3D<float3> g_tex3DSingleSctrLUT;
SamplerState g_tex3DSingleSctrLUT_sampler;

Texture3D<float3> g_tex3DHighOrderSctrLUT;
SamplerState g_tex3DHighOrderSctrLUT_sampler;

Texture3D<float3> g_tex3DMultipleSctrLUT;
SamplerState g_tex3DMultipleSctrLUT_sampler;

#include "LookUpTables.fxh"
#include "ScatteringIntegrals.fxh"
#include "UnshadowedScattering.fxh"

void ShaderFunctionInternal(in float4 f4Pos,
                            out float3 f3Inscattering, 
                            out float3 f3Extinction)
{
    // Compute unshadowed inscattering from the camera to the ray end point using few steps
    float fCamSpaceZ =  g_tex2DEpipolarCamSpaceZ.Load( uint3(f4Pos.xy, 0) );
    float2 f2SampleLocation = g_tex2DCoordinates.Load( uint3(f4Pos.xy, 0) );

    ComputeUnshadowedInscattering(f2SampleLocation, fCamSpaceZ, 
                                  7.0, // Use hard-coded constant here so that compiler can optimize the code
                                       // more efficiently
                                  f3Inscattering, f3Extinction);
    f3Inscattering *= g_LightAttribs.f4ExtraterrestrialSunColor.rgb;
}

// Render inscattering only
void RenderCoarseUnshadowedInsctrPS(ScreenSizeQuadVSOutput VSOut, 
                                    // IMPORTANT: non-system generated pixel shader input
                                    // arguments must have the exact same name as vertex shader 
                                    // outputs and must go in the same order.
                                    // Moreover, even if the shader is not using the argument,
                                    // it still must be declared.

                                    in float4 f4Pos : SV_Position,
                                    out float3 f3Inscattering : SV_Target0) 
{
    float3 f3Extinction = F3ONE;
    ShaderFunctionInternal(f4Pos, f3Inscattering, f3Extinction );
}

// Render inscattering and extinction
void RenderCoarseUnshadowedInsctrAndExtinctionPS(ScreenSizeQuadVSOutput VSOut,
                                                 in float4 f4Pos : SV_Position,
                                                 out float3 f3Inscattering : SV_Target0,
                                                 out float3 f3Extinction   : SV_Target1) 
{
    ShaderFunctionInternal(f4Pos, f3Inscattering, f3Extinction );
}
