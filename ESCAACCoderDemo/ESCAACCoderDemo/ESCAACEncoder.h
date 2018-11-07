//
//  ESCAACEncoder.h
//  ESCAACCoderDemo
//
//  Created by xiang on 2018/10/9.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESCAACEncoder : NSObject

- (void)setupEncoderWithSampleRate:(int)sampleRate channels:(int)channels sampleBit:(int)sampleBit;

- (NSData *)encodePCMDataWithPCMData:(NSData *)pcmData;

- (void)closeEncoder;


@end

NS_ASSUME_NONNULL_END
