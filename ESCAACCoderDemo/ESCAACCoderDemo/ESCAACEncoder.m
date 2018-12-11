//
//  ESCAACEncoder.m
//  ESCAACCoderDemo
//
//  Created by xiang on 2018/10/9.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ESCAACEncoder.h"
#import "faac/include/faac.h"

@interface ESCAACEncoder ()

@property(nonatomic,assign)faacEncHandle encoder;

@property(nonatomic,assign)    faacEncConfigurationPtr pConfiguration;//aac设置指针

@property(nonatomic,assign)int inputSamples;

@property(nonatomic,assign)int inputBytes;

@property(nonatomic,assign)int maxOutputBytes;

@end

@implementation ESCAACEncoder

- (void)setupEncoderWithSampleRate:(int)sampleRate channels:(int)channels sampleBit:(int)sampleBit{
    unsigned long inputSamples;
    unsigned long maxOutputBytes;
    //初始化aac句柄，同时获取最大输入样本，及编码所需最小字节
    faacEncHandle encoder = faacEncOpen(sampleRate, channels, &inputSamples, &maxOutputBytes);
    self.encoder = encoder;
    
    self.inputSamples = (int)inputSamples;
    self.maxOutputBytes = (int)maxOutputBytes;
    
    int nMaxInputBytes = (int)inputSamples * sampleBit / 8;
    self.inputBytes = nMaxInputBytes;
    
    // (2.1) Get current encoding configuration
    self.pConfiguration = faacEncGetCurrentConfiguration(self.encoder);//获取配置结构指针
    self.pConfiguration->inputFormat = FAAC_INPUT_16BIT;
    self.pConfiguration->outputFormat=1;
    self.pConfiguration->useTns=true;
    self.pConfiguration->useLfe=false;
    self.pConfiguration->aacObjectType=LOW;
    self.pConfiguration->shortctl=SHORTCTL_NORMAL;
    self.pConfiguration->quantqual=100;
    self.pConfiguration->bandWidth=0;
    self.pConfiguration->bitRate=0;
    // (2.2) Set encoding configuration
    int nRet = faacEncSetConfiguration(self.encoder, self.pConfiguration);//设置配置，根据不同设置，耗时不一样

    if (nRet < 0) {
        NSLog(@"set failed!");
    }
    

}

- (NSData *)encodePCMDataWithPCMData:(NSData *)pcmData {
    
    int8_t *pPcmData = [pcmData bytes];
    unsigned char *outputBuffer[self.maxOutputBytes];
    
    NSMutableData *temData = [NSMutableData data];
    int i = 0;
    while (1) {
        //读取
        int32_t *inputBuffer = &pPcmData[i];
        //编码
        int outLength = faacEncEncode(self.encoder, inputBuffer, self.inputSamples, outputBuffer, self.maxOutputBytes);
        //组装数据
        if (outLength > 0) {
            [temData appendBytes:outputBuffer length:outLength];
            NSLog(@"%d",outLength);
        }else {
            NSLog(@"no data");
        }
        i += self.inputBytes;
        //判断是否结束
        if (i > pcmData.length - 1) {
            NSLog(@"读取数据结束");
            break;
        }
    }
    //读取缓冲区数据
    while (1) {
        int outLength = faacEncEncode(self.encoder, NULL, 0, outputBuffer, self.maxOutputBytes);
        if (outLength > 0) {
            [temData appendBytes:outputBuffer length:outLength];
            NSLog(@"%d",outLength);
        }else {
            break;
        }
    }
    
    return temData;
}

- (void)closeEncoder {
    faacEncClose(self.encoder);
}

@end
