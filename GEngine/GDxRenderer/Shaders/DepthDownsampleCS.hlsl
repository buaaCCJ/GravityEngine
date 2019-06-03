
#ifndef CLUSTERED_DEFERRED_CS_HLSL
#define CLUSTERED_DEFERRED_CS_HLSL


#include "ShaderDefinition.h"
#include "MainPassCB.hlsli"

Texture2D gDepthBuffer : register(t0);

RWStructuredBuffer<float> gDepthDownsampleBuffer : register(u0);

static const float2 gDepthReadbackBufferSize = float2(DEPTH_READBACK_BUFFER_SIZE_X, DEPTH_READBACK_BUFFER_SIZE_Y);

SamplerState gSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

[numthreads(8, 8, 1)]
void main(
	uint3 groupId          : SV_GroupID,
	uint3 dispatchThreadId : SV_DispatchThreadID,
	uint3 groupThreadId : SV_GroupThreadID
	)
{
    uint groupIndex = dispatchThreadId.y * DEPTH_READBACK_BUFFER_SIZE_X + dispatchThreadId.x;

    uint2 globalCoords = dispatchThreadId.xy;
	float2 uv = globalCoords / gDepthReadbackBufferSize;

	float2 offset = (gRenderTargetSize / gDepthReadbackBufferSize) / 3;
	float2 uvOffset = offset / gDepthReadbackBufferSize;

	float depthFromTexture;
	float2 sampUV;
	float maxDepth = 0.0f;

	for (int x = -1; x < 2; x++)
	{
		for (int y = -1; y < 2; y++)
		{
			sampUV = saturate(uv + float2(x, y) * uvOffset);

			depthFromTexture = gDepthBuffer.SampleLevel(gSampler, sampUV, 0).r;

#if USE_REVERSE_Z
			depthFromTexture = 1 - depthFromTexture;
#endif

			if (depthFromTexture > maxDepth)
			{
				maxDepth = depthFromTexture;
			}
		}
	}

	gDepthDownsampleBuffer[groupIndex] = maxDepth;

}


#endif



