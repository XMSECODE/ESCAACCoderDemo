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
#import <Foundation/Foundation.h>

//aac数据状态
typedef enum {
    AccDataStatus_NotKnown            =        0x00,            //未知
    AccDataStatus_InValid            =        0x01,            //非法
    AccDataStatus_Valid                =        0x02,            //合法
}fAccDataStatus;

@interface ESCFAACDecoder : NSObject

- (BOOL)createDecoderWithSampleRate:(int)sampleRate channels:(int)channels bitRate:(int)bitRate;

- (NSData *)decodeAACDataWithAACData:(NSData *)aacData;

- (void)closeDecoder;

@end


#endif /* ESCFAACDecoder_h */




