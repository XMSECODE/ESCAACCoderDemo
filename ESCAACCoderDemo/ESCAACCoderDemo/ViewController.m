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
    
    [self AACToPCM];
}


- (void)PCMToAAC {
    ULONG nSampleRate = 44100;  // 采样率
    UINT nChannels = 2;         // 声道数
    UINT nBit = 16;             // 单样本位数
    ULONG nInputSamples = 0; //输入样本数
    ULONG nMaxOutputBytes = 0; //输出所需最大空间
    ULONG nMaxInputBytes=0;     //输入最大字节
    NSInteger nRet;
    faacEncHandle hEncoder; //aac句柄
    faacEncConfigurationPtr pConfiguration;//aac设置指针
    
    BYTE* pbPCMBuffer;
    BYTE* pbAACBuffer;
    
    FILE* fpIn; // PCM file for input
    FILE* fpOut; // AAC file for output
    
    
    NSString *pcmPath = [[NSBundle mainBundle] pathForResource:@"vocal.pcm" ofType:nil];
    fpIn = fopen([pcmPath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
    
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *aacPath = [NSString stringWithFormat:@"%@/vocal.aac",cachesPath];
    
    fpOut = fopen([aacPath cStringUsingEncoding:NSUTF8StringEncoding], "wb");
    if (fpIn==NULL) {
        printf("can't find myvoice!\n");
        return;
    }
    // (1) Open FAAC engine
    //初始化aac句柄，同时获取最大输入样本，及编码所需最小字节
    hEncoder = faacEncOpen(nSampleRate, nChannels, &nInputSamples, &nMaxOutputBytes);
    //计算最大输入字节,跟据最大输入样本数
    nMaxInputBytes=nInputSamples * nBit / 8;
    printf("nInputSamples:%lu nMaxInputBytes:%lu nMaxOutputBytes:%lu\n", nInputSamples, nMaxInputBytes,nMaxOutputBytes);
    if(hEncoder == NULL) {
        printf("[ERROR] Failed to call faacEncOpen()\n");
        return;
    }
    
    BYTE pcmbuffer[nMaxInputBytes];
    BYTE aacbuffer[nMaxOutputBytes];
    
    pbPCMBuffer = pcmbuffer;
    pbAACBuffer = aacbuffer;
    
    // (2.1) Get current encoding configuration
    pConfiguration = faacEncGetCurrentConfiguration(hEncoder);//获取配置结构指针
    pConfiguration->inputFormat = FAAC_INPUT_16BIT;
    pConfiguration->outputFormat=1;
    pConfiguration->useTns=true;
    pConfiguration->useLfe=false;
    pConfiguration->aacObjectType=LOW;
    pConfiguration->shortctl=SHORTCTL_NORMAL;
    pConfiguration->quantqual=100;
    pConfiguration->bandWidth=0;
    pConfiguration->bitRate=0;
    // (2.2) Set encoding configuration
    nRet = faacEncSetConfiguration(hEncoder, pConfiguration);//设置配置，根据不同设置，耗时不一样
    unsigned long temp1=clock();
    while(true) {
        nRet=0;
        nRet = fread(pbPCMBuffer, 1, nMaxInputBytes, fpIn);
        if(nRet < 1) {
            break;
        }
        // 计算实际输入样本数，
        nInputSamples = nRet/ (nBit / 8);
        // (3) Encode
        nRet = faacEncEncode(hEncoder, (int*) pbPCMBuffer, (unsigned int)nInputSamples, pbAACBuffer, (unsigned int)nMaxOutputBytes);
        if (nRet<1) {
            continue;
        }
        fwrite(pbAACBuffer, 1, nRet, fpOut);
    }
    while( (nRet = faacEncEncode(hEncoder, NULL, 0, pbAACBuffer, (unsigned int)nMaxOutputBytes)) > 0 ) {
        fwrite(pbAACBuffer, 1, nRet, fpOut);
    }
    printf("usetime:%lu\n",clock()-temp1);
    // (4) Close FAAC engine 关闭acc句柄
    nRet = faacEncClose(hEncoder);
    fclose(fpIn);
    fclose(fpOut);
    
}

- (void)AACToPCM {
    
    FAADContext *context = faad_decoder_create(44100, 2, 1024);
    
    NSString *aacPath = [[NSBundle mainBundle] pathForResource:@"vocal.aac" ofType:nil];
    NSData *aacData = [NSData dataWithContentsOfFile:aacPath];
    unsigned char *pAACData = aacData.bytes;
    
    unsigned char *pcmData;
    unsigned int pcmLen = 0;
    faad_decode_frame(context, pAACData, aacData.length, pcmData, &pcmLen);
    faad_decode_close(context);
    
    if (pcmLen > 0) {
        NSData *pcmdata = [NSData dataWithBytes:pcmData length:pcmLen];
        NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
        NSString *pcmPath = [NSString stringWithFormat:@"%@/vocal.pcm",cachesPath];
        [pcmdata writeToFile:pcmPath atomically:YES];
    }
    
}

@end
