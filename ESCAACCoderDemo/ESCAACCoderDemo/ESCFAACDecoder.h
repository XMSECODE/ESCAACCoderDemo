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

typedef struct {
    NeAACDecHandle handle;
    int sample_rate;
    int channels;
    int bit_rate;
}FAADContext;

FAADContext* faad_decoder_create(int sample_rate, int channels, int bit_rate);
int faad_decode_frame(FAADContext *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen);
void faad_decode_close(FAADContext *pParam);

#endif /* ESCFAACDecoder_h */
