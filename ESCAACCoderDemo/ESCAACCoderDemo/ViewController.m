//
//  ViewController.m
//  ESCAACCoderDemo
//
//  Created by xiang on 2018/10/9.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ViewController.h"
#import "faac/include/faac.h"
#import "ESCFAACDecoder.h"
#import "ESCAACEncoder.h"


typedef unsigned long   ULONG;
typedef unsigned int    UINT;
typedef unsigned char   BYTE;
typedef char            _TCHAR;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self PCMToAAC];
    
    [self PCMToAAC2];
    
    [self AACToPCM];
    
    [self AACToPCM2];
}

- (void)PCMToAAC2 {
    ESCAACEncoder *aacEncoder = [[ESCAACEncoder alloc] init];
    [aacEncoder setupEncoderWithSampleRate:8000 channels:1 sampleBit:16];
    
    NSString *pcmPath = [[NSBundle mainBundle] pathForResource:@"8000_16_1_1.pcm" ofType:nil];
    
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *aacPath = [NSString stringWithFormat:@"%@/8000_16_1_1.aac",cachesPath];
    
    NSData *pcmData = [NSData dataWithContentsOfFile:pcmPath];
    NSData *aacData = [aacEncoder encodePCMDataWithPCMData:pcmData];
    
    if (aacData.length > 0) {
        [aacData writeToFile:aacPath atomically:YES];
    }
    [aacEncoder closeEncoder];
    
}

- (void)PCMToAAC {
    
    ESCAACEncoder *aacEncoder = [[ESCAACEncoder alloc] init];
    [aacEncoder setupEncoderWithSampleRate:44100 channels:2 sampleBit:16];
    
    NSString *pcmPath = [[NSBundle mainBundle] pathForResource:@"vocal.pcm" ofType:nil];
    
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *aacPath = [NSString stringWithFormat:@"%@/vocal.aac",cachesPath];
    
    NSData *pcmData = [NSData dataWithContentsOfFile:pcmPath];
    NSData *aacData = [aacEncoder encodePCMDataWithPCMData:pcmData];
    
    if (aacData.length > 0) {
        [aacData writeToFile:aacPath atomically:YES];
    }
    [aacEncoder closeEncoder];
}

- (void)AACToPCM {
        
    ESCFAACDecoder *aacDecoder = [[ESCFAACDecoder alloc] init];
    [aacDecoder setupDecoderWithSampleRate:44100 channels:2 bitRate:20480];
    
    NSString *aacPath = [[NSBundle mainBundle] pathForResource:@"vocal.aac" ofType:nil];
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *pcmPath = [NSString stringWithFormat:@"%@/vocal.pcm",cachesPath];
    
    
    NSData *aacData = [NSData dataWithContentsOfFile:aacPath];
    if (aacData == nil || aacData.length <= 0) {
        [aacDecoder closeDecoder];
        NSLog(@"读取数据失败");
        return;
    }
    
    NSData *pcmdata = [aacDecoder decodeAACDataWithAACData:aacData];
    [aacDecoder closeDecoder];
    
    if (pcmdata.length > 0) {
        [pcmdata writeToFile:pcmPath atomically:YES];
    }else{
        NSLog(@"aac to pcm failed!");
    }
}

- (void)AACToPCM2 {
    
    ESCFAACDecoder *aacDecoder = [[ESCFAACDecoder alloc] init];
    [aacDecoder setupDecoderWithSampleRate:8000 channels:1 bitRate:20480];
    
    NSString *aacPath = [[NSBundle mainBundle] pathForResource:@"8000_16_1.aac" ofType:nil];
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *pcmPath = [NSString stringWithFormat:@"%@/8000_16_1.pcm",cachesPath];
    
    NSData *aacData = [NSData dataWithContentsOfFile:aacPath];
    if (aacData == nil || aacData.length <= 0) {
        [aacDecoder closeDecoder];
        NSLog(@"读取数据失败");
        return;
    }
    NSData *pcmdata = [aacDecoder decodeAACDataWithAACData:aacData];
    [aacDecoder closeDecoder];
    if (pcmdata.length > 0) {
        [pcmdata writeToFile:pcmPath atomically:YES];
    }else{
        NSLog(@"aac to pcm failed!");
    }
}

@end
