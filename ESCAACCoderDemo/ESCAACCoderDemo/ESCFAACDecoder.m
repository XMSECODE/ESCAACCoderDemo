//
//  ESCFAACDecoder.c
//  ESCAACCoderDemo
//
//  Created by xiang on 2018/10/9.
//  Copyright © 2018年 xiang. All rights reserved.
//

#include "ESCFAACDecoder.h"
#import "faad.h"
#import <Foundation/Foundation.h>

@interface ESCFAACDecoder ()

@property(nonatomic,assign)NeAACDecHandle decoder;

@property(nonatomic,assign)NeAACDecFrameInfo frame_info;

@property(nonatomic,assign)int sampleRate;

@property(nonatomic,assign)int channels;

@property(nonatomic,assign)int bitRate;

@property(nonatomic,assign)int m_nFirstPackageAccDataStatus;

@property(nonatomic,assign)BOOL m_bNeAACDecInit;

@end


@implementation ESCFAACDecoder

- (BOOL)createDecoderWithSampleRate:(int)sampleRate channels:(int)channels bitRate:(int)bitRate {
    
    NeAACDecHandle handle = NeAACDecOpen();
    if(!handle){
        printf("NeAACDecOpen failed\n");
        return NO;
    }
    
    NeAACDecConfigurationPtr conf = NeAACDecGetCurrentConfiguration(handle);
    if(!conf){
        printf("NeAACDecGetCurrentConfiguration failed\n");
        if(handle){
            NeAACDecClose(handle);
        }
        return NO;
    }
    conf->defObjectType = LC;//外加
    
    conf->defSampleRate = sampleRate;
    conf->outputFormat = FAAD_FMT_16BIT;
    conf->dontUpSampleImplicitSBR = 1;
    unsigned char setresult = NeAACDecSetConfiguration(handle, conf);
    if (setresult == 0) {
        printf("set configuration failed!\n");
        if(handle){
            NeAACDecClose(handle);
        }
        return NO;
    }
    
    self.decoder = handle;
    self.sampleRate = sampleRate;
    self.channels = channels;
    self.bitRate = bitRate;
    self.m_nFirstPackageAccDataStatus = AccDataStatus_NotKnown;
    self.m_bNeAACDecInit = NO;
    
    return YES;
    
}

- (NSData *)decodeAACDataWithAACData:(NSData *)aacData {
    
    unsigned char *pData = [aacData bytes];
    int nLen = aacData.length;
    
    [self detectFirstPackageData:aacData];
    if (self.m_nFirstPackageAccDataStatus != AccDataStatus_Valid) {
        printf("valid!\n");
        return nil;
    }
    if (self.m_bNeAACDecInit == NO) {
        //initialize decoder
        unsigned long sample_rate = 0;
        unsigned long channels = 0;
        NeAACDecInit(self.decoder, pData, nLen, &sample_rate, &channels);
        printf("samplerate %ld, channels %ld\n", sample_rate, channels);
        self.m_bNeAACDecInit = YES;
    }
    
    int size = 0;
    unsigned char* pcm_data = NULL;
    NSMutableData *resultData = [NSMutableData data];
    int total = 0;
    
    unsigned char frame[1024 * 15] = {0};
    
    while ([ESCFAACDecoder getOneADTSFrame:pData buf_size:nLen frame:frame data_size:&size] == 0) {
        total += size;
        //        NSData *temframe = [NSData dataWithBytes:frame length:size];
        //        NSLog(@"%@",temframe);
        printf("%d===frame size %d\n", total, size);
        //decode ADTS frame
        pcm_data = (unsigned char*)NeAACDecDecode(self.decoder, &_frame_info, frame, size);
        
        if(self.frame_info.error > 0) {
            printf("error == %s\n",NeAACDecGetErrorMessage(self.frame_info.error));
            return resultData;
        }else if(pcm_data && self.frame_info.samples > 0){
            printf("frame info: bytesconsumed %d, channels %d, header_type %d\
                   object_type %d, samples %d, samplerate %d\n",
                   self.frame_info.bytesconsumed,
                   self.frame_info.channels, self.frame_info.header_type,
                   self.frame_info.object_type, self.frame_info.samples,
                   self.frame_info.samplerate);
            
            unsigned int length;
            length = self.frame_info.samples * self.frame_info.channels;
            
            NSData *temPcmData = [NSData dataWithBytes:pcm_data length:length];
            [resultData appendData:temPcmData];
        }
        pData += size;
        nLen -= size;
    }
    
    return resultData;
}

- (void)closeDecoder {
    if(self.decoder == NULL){
        return;
    }
    NeAACDecClose(self.decoder);
}

- (BOOL)detectFirstPackageData:(NSData *)aacData {
    int size = 0;
    unsigned char *bufferAAC = [aacData bytes];
    
    unsigned char frame[1024 * 15] = {0};
    if ([ESCFAACDecoder getOneADTSFrame:bufferAAC buf_size:aacData.length frame:frame data_size:&size] < 0) {
        self.m_nFirstPackageAccDataStatus = AccDataStatus_InValid;
        return NO;
    }
    self.m_nFirstPackageAccDataStatus  = AccDataStatus_Valid;
    return YES;
}

+ (int)getOneADTSFrame:(unsigned char *)buffer buf_size:(int)buf_size frame:(unsigned char *)data data_size:(int *)data_size {
    int size = 0;
    
    if(!buffer || !data || !data_size ) {
        return -1;
    }
    
    while(1){
        if(buf_size  < 7 ) {
            return -1;
        }
        
        if ((buffer[0] == 0xff) && ((buffer[1] & 0xf0) == 0xf0))
        {
            // profile; 2 uimsbf
            // sampling_frequency_index; 4 uimsbf
            // private_bit; 1 bslbf
            // channel_configuration; 3 uimsbf
            // original/copy; 1 bslbf
            // home; 1 bslbf
            // copyright_identification_bit; 1 bslbf
            // copyright_identification_start; 1 bslbf
            // frame_length; 13 bslbf
            
            int size_1 = buffer[3] & 0x03;
            int size_2 = buffer[4];
            int size_3 = buffer[5] & 0xe0;
            
            //            NSLog(@"%d==%d=%d=%d",buffer[3],size_1,size_2,size_3);
            
            size = size | (size_1 << 11);
            size = size | (size_2 << 3);
            size = size | (size_3 >> 5);
            
            //            size |= (((buffer[3] & 0x03)) << 11);//high 2 bit
            //            size |= (buffer[4] << 3);//middle 8 bit
            //            size |= ((buffer[5] & 0xe0) >> 5);//low 3bit
            
            //            printf("len1=%x\n", (buffer[3] & 0x03));
            //            printf("len2=%x\n", buffer[4]);
            //            printf("len3=%x\n", (buffer[5] & 0xe0) >> 5);
            //            printf("size=%d\r\n", (int)size);
            
            //            int8_t fullness = 0;
            //
            //            fullness |= buffer[5] & 0x1f << 6;
            //            fullness |= buffer[6] & 0xfc >> 2;
            //            NSLog(@"%d==%d",fullness,size);
            
            break;
        }
        --buf_size;
        ++buffer;
    }
    
    if(buf_size < size)
    {
        return -1;
    }
    
    memcpy(data, buffer, size);
    *data_size = size;
    
    return 0;
}

@end
