//
//  ESCFAACDecoder.h
//  ESCAACCoderDemo
//
//  Created by xiang on 2018/10/9.
//  Copyright © 2018年 xiang. All rights reserved.
//

#ifndef ESCFAACDecoder_h
#define ESCFAACDecoder_h
#import "faad.h"

#include <stdio.h>

//aac数据状态
typedef enum fAccDataStatus
{
    AccDataStatus_NotKnown            =        0x00,            //未知
    AccDataStatus_InValid            =        0x01,            //非法
    AccDataStatus_Valid                =        0x02,            //合法
};

typedef struct {
    NeAACDecHandle handle;
    int sample_rate;
    int channels;
    int bit_rate;
    NeAACDecFrameInfo frame_info;
    int m_nFirstPackageAccDataStatus;        //第一数据包状态
    int m_bNeAACDecInit;
}FAADContext;

FAADContext* faad_decoder_create(int sample_rate, int channels, int bit_rate);
int faad_decode_frame(FAADContext *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen);
void faad_decode_close(FAADContext *pParam);

#endif /* ESCFAACDecoder_h */




