//
//  ESCFAACDecoder.h
//  ESCAACCoderDemo
//
//  Created by xiang on 2018/10/9.
//  Copyright © 2018年 xiang. All rights reserved.
//

#ifndef ESCFAACDecoder_h
#define ESCFAACDecoder_h
#import <Foundation/Foundation.h>

@interface ESCFAACDecoder : NSObject

- (BOOL)setupDecoderWithSampleRate:(int)sampleRate channels:(int)channels bitRate:(int)bitRate;

- (NSData *)decodeAACDataWithAACData:(NSData *)aacData;

- (void)closeDecoder;

@end


#endif /* ESCFAACDecoder_h */




