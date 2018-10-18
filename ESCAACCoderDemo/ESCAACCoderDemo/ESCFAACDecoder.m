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

#define FRAME_MAX_LEN 1024*5
#define BUFFER_MAX_LEN 1024*1024

static unsigned char frame[FRAME_MAX_LEN] = {0};
unsigned int framesize = FRAME_MAX_LEN;

int get_one_ADTS_frame(unsigned char* buffer, size_t buf_size, unsigned char* data ,size_t* data_size);



//检测数据是否合法
int detectFirstPackageData(FAADContext *pParam, unsigned char* bufferAAC, size_t buf_sizeAAC)
{
    size_t size = 0;
    if(get_one_ADTS_frame(bufferAAC, buf_sizeAAC, frame, &size) < 0)
    {
        pParam->m_nFirstPackageAccDataStatus = AccDataStatus_InValid;
        return -1;
    }
    pParam->m_nFirstPackageAccDataStatus  = AccDataStatus_Valid;
    return 0;
}

//获取第一数据包状态
int getFirstPackageAccDataStatus(FAADContext *context)
{
    return context->m_nFirstPackageAccDataStatus;
}
//重置第一数据包状态
void clearFirstPackageAccDataStatus(FAADContext *context, int nAccDataStatus)
{
    context->m_nFirstPackageAccDataStatus = nAccDataStatus;
}






uint32_t _get_frame_length(const unsigned char *aac_header)
{
    uint32_t len = *(uint32_t *)(aac_header + 3);
    len = ntohl(len); //Little Endian
    len = len << 6;
    len = len >> 19;
    return len;
}

FAADContext* faad_decoder_create(int sample_rate, int channels, int bit_rate) {
    
    
    NeAACDecHandle handle = NeAACDecOpen();
    if(!handle){
        printf("NeAACDecOpen failed\n");
        goto error;
    }
    NeAACDecConfigurationPtr conf = NeAACDecGetCurrentConfiguration(handle);
    if(!conf){
        printf("NeAACDecGetCurrentConfiguration failed\n");
        goto error;
    }
    conf->defObjectType = LC;//外加

    conf->defSampleRate = sample_rate;
    conf->outputFormat = FAAD_FMT_16BIT;
    conf->dontUpSampleImplicitSBR = 1;
    unsigned char setresult = NeAACDecSetConfiguration(handle, conf);
    if (setresult == 0) {
        printf("set configuration failed!\n");
        goto error;
    }
    
    FAADContext* ctx = malloc((unsigned long)sizeof(FAADContext));
    ctx->handle = handle;
    ctx->sample_rate = sample_rate;
    ctx->channels = channels;
    ctx->bit_rate = bit_rate;
    ctx->m_nFirstPackageAccDataStatus = AccDataStatus_NotKnown;
    ctx->m_bNeAACDecInit = false;
    
    
    
    
    
    return ctx;
    
error:
    if(handle){
        NeAACDecClose(handle);
    }
    return NULL;
}

int faad_decode_frame(FAADContext *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen) {
    
    if (1) {
        detectFirstPackageData(pParam, pData, nLen);
        if (pParam->m_nFirstPackageAccDataStatus != AccDataStatus_Valid)
            return -1;
        
        size_t size = 0;
        unsigned char* pcm_data = NULL;
        while(get_one_ADTS_frame(pData, nLen, frame, &size) == 0)
        {
            // printf("frame size %d\n", size);
            //decode ADTS frame
            pcm_data = (unsigned char*)NeAACDecDecode(pParam->handle, &pParam->frame_info, frame, size);
            
            if(pParam->frame_info.error > 0)
            {
                printf("%s\n",NeAACDecGetErrorMessage(pParam->frame_info.error));
                return -1;
            }
            else if(pcm_data && pParam->frame_info.samples > 0)
            {
                printf("frame info: bytesconsumed %d, channels %d, header_type %d\
                       object_type %d, samples %d, samplerate %d\n",
                       pParam->frame_info.bytesconsumed,
                       pParam->frame_info.channels, pParam->frame_info.header_type,
                       pParam->frame_info.object_type, pParam->frame_info.samples,
                       pParam->frame_info.samplerate);
                
                *outLen = pParam->frame_info.samples * pParam->frame_info.channels;
                /*
                 //从双声道的数据中提取单通道
                 for (int i = 0, j = 0; i<4096 && j<2048; i += 4, j += 2)
                 {
                 bufferPCM[j] = pcm_data[i];
                 bufferPCM[j + 1] = pcm_data[i + 1];
                 }
                 */
                memcpy(pPCM,pcm_data,*outLen);
            }
            pData -= size;
            nLen += size;
        }
        
    }else {
        unsigned char* pcm_data = NULL;
        if (!pParam->m_bNeAACDecInit)
        {
            //initialize decoder
            NeAACDecInit(pParam->handle, pData, nLen, (unsigned long*)&pParam->sample_rate, (unsigned long*)&pParam->channels);
            printf("samplerate %d, channels %d\n", pParam->sample_rate, pParam->channels);
            pParam->m_bNeAACDecInit = true;
        }
        //decode ADTS frame
        pcm_data = (unsigned char*)NeAACDecDecode(pParam->handle, &pParam->frame_info, pData, nLen);
        
        if (pParam->frame_info.error > 0)
        {
            printf("%s\n", NeAACDecGetErrorMessage(pParam->frame_info.error));
            return -1;
        }
        else if (pcm_data && pParam->frame_info.samples > 0)
        {
            printf("frame info: bytesconsumed %d, channels %d, header_type %d\
                   object_type %d, samples %d, samplerate %d\n",
                   pParam->frame_info.bytesconsumed,
                   pParam->frame_info.channels, pParam->frame_info.header_type,
                   pParam->frame_info.object_type, pParam->frame_info.samples,
                   pParam->frame_info.samplerate);
            
            *outLen = pParam->frame_info.samples * pParam->frame_info.channels;
            /*
             //从双声道的数据中提取单通道
             for (int i = 0, j = 0; i<4096 && i<buf_sizePCM && j<2048; i += 4, j += 2)
             {
             bufferPCM[j] = pcm_data[i];
             bufferPCM[j + 1] = pcm_data[i + 1];
             }
             */
            memcpy(pPCM,pcm_data,*outLen);
            /*
             float in[4096] = { 0 };
             float out[4096] = { 0 };
             for (int j = 0; j < 4096 && j < buf_sizePCM; j++)
             {
             in[j] = pcm_data[j];
             }
             SRC_DATA dataResample;
             dataResample.data_in = in;
             dataResample.data_out = out;
             dataResample.input_frames = frame_info.samples;
             dataResample.output_frames = frame_info.samples;
             dataResample.src_ratio =  8000.0/frame_info.samplerate;
             int nRetResample = src_simple(&dataResample, SRC_SINC_FASTEST, 2);
             buf_sizePCM = dataResample.output_frames_gen * frame_info.channels;
             memcpy(bufferPCM, dataResample.data_out, buf_sizePCM);
             */
            
            return 0;
        }
        
        return -1;
    }
    
    
    
    
    
    FAADContext* pCtx = (FAADContext*)pParam;
    NeAACDecHandle handle = pCtx->handle;
    long res = NeAACDecInit(handle, pData, nLen, (unsigned long*)&pCtx->sample_rate, (unsigned char*)&pCtx->channels);
    if (res < 0) {
        printf("NeAACDecInit failed\n");
        return -1;
    }
    NeAACDecFrameInfo info;
    uint32_t framelen = _get_frame_length(pData);
    unsigned char *buf = (unsigned char *)NeAACDecDecode(handle, &info, pData, nLen);
    if (buf && info.error == 0) {
        if (info.samplerate == 44100) {
            //src: 2048 samples, 4096 bytes
            //dst: 2048 samples, 4096 bytes
            int tmplen = (int)info.samples * 16 / 8;
            printf("%d====tmplen == %d\n",info.samples,tmplen);
            memcpy(pPCM,buf,tmplen);
            *outLen = tmplen;
        } else if (info.samplerate == 22050) {
            //src: 1024 samples, 2048 bytes
            //dst: 2048 samples, 4096 bytes
            short *ori = (short*)buf;
            short tmpbuf[info.samples * 2];
            int tmplen = (int)info.samples * 16 / 8 * 2;
            for (int32_t i = 0, j = 0; i < info.samples; i += 2) {
                tmpbuf[j++] = ori[i];
                tmpbuf[j++] = ori[i + 1];
                tmpbuf[j++] = ori[i];
                tmpbuf[j++] = ori[i + 1];
            }
            memcpy(pPCM,tmpbuf,tmplen);
            *outLen = tmplen;
        }else if(info.samplerate == 8000){
            //从双声道的数据中提取单通道
            for(int i=0,j=0; i<4096 && j<2048; i+=4, j+=2)
            {
                pPCM[j]= buf[i];
                pPCM[j+1]=buf[i+1];
            }
            *outLen = (unsigned int)info.samples;
        }
    } else {
        printf("NeAACDecDecode failed\n");
        return -1;
    }
    return 0;
}

void faad_decode_close(FAADContext *pParam) {
    if(!pParam){
        return;
    }
    FAADContext* pCtx = (FAADContext*)pParam;
    if(pCtx->handle){
        NeAACDecClose(pCtx->handle);
    }
    free(pCtx);
}













/**
 * fetch one ADTS frame
 */
int get_one_ADTS_frame(unsigned char* buffer, size_t buf_size, unsigned char* data ,size_t* data_size) {
    size_t size = 0;
    
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
            
            size |= (((buffer[3] & 0x03)) << 11);//high 2 bit
            size |= (buffer[4] << 3);//middle 8 bit
            size |= ((buffer[5] & 0xe0) >> 5);//low 3bit
            
            printf("len1=%x\n", (buffer[3] & 0x03));
            printf("len2=%x\n", buffer[4]);
            printf("len3=%x\n", (buffer[5] & 0xe0) >> 5);
            printf("size=%d\r\n", (int)size);
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




//转换
int convert(FAADContext *context, unsigned char* bufferAAC, size_t buf_sizeAAC,unsigned char* bufferPCM, size_t *buf_sizePCM)
{
//    if (context->m_nFirstPackageAccDataStatus != AccDataStatus_Valid)
//        return -1;
//
//    size_t size = 0;
//    unsigned char* pcm_data = NULL;
//    while(get_one_ADTS_frame(bufferAAC, buf_sizeAAC, frame, &size) == 0)
//    {
//        // printf("frame size %d\n", size);
//        //decode ADTS frame
//        pcm_data = (unsigned char*)NeAACDecDecode(decoder, &frame_info, frame, size);
//
//        if(frame_info.error > 0)
//        {
//            printf("%s\n",NeAACDecGetErrorMessage(frame_info.error));
//            return -1;
//        }
//        else if(pcm_data && frame_info.samples > 0)
//        {
//            printf("frame info: bytesconsumed %d, channels %d, header_type %d\
//                   object_type %d, samples %d, samplerate %d\n",
//                   frame_info.bytesconsumed,
//                   frame_info.channels, frame_info.header_type,
//                   frame_info.object_type, frame_info.samples,
//                   frame_info.samplerate);
//
//            buf_sizePCM = frame_info.samples * frame_info.channels;
//            /*
//             //从双声道的数据中提取单通道
//             for (int i = 0, j = 0; i<4096 && j<2048; i += 4, j += 2)
//             {
//             bufferPCM[j] = pcm_data[i];
//             bufferPCM[j + 1] = pcm_data[i + 1];
//             }
//             */
//            memcpy(bufferPCM,pcm_data,buf_sizePCM);
//        }
//        bufferAAC -= size;
//        buf_sizeAAC += size;
//    }
    
    return 0;
}

int convert2(unsigned char* bufferAAC, size_t buf_sizeAAC, unsigned char* bufferPCM, size_t * buf_sizePCM)
{
//    unsigned char* pcm_data = NULL;
//    if (!m_bNeAACDecInit)
//    {
//        //initialize decoder
//        NeAACDecInit(decoder, bufferAAC, buf_sizeAAC, &samplerate, &channels);
//        printf("samplerate %d, channels %d\n", samplerate, channels);
//        m_bNeAACDecInit = true;
//    }
//    //decode ADTS frame
//    pcm_data = (unsigned char*)NeAACDecDecode(decoder, &frame_info, bufferAAC, buf_sizeAAC);
//
//    if (frame_info.error > 0)
//    {
//        printf("%s\n", NeAACDecGetErrorMessage(frame_info.error));
//        return -1;
//    }
//    else if (pcm_data && frame_info.samples > 0)
//    {
//        printf("frame info: bytesconsumed %d, channels %d, header_type %d\
//               object_type %d, samples %d, samplerate %d\n",
//               frame_info.bytesconsumed,
//               frame_info.channels, frame_info.header_type,
//               frame_info.object_type, frame_info.samples,
//               frame_info.samplerate);
//
//        buf_sizePCM = frame_info.samples * frame_info.channels;
//        /*
//         //从双声道的数据中提取单通道
//         for (int i = 0, j = 0; i<4096 && i<buf_sizePCM && j<2048; i += 4, j += 2)
//         {
//         bufferPCM[j] = pcm_data[i];
//         bufferPCM[j + 1] = pcm_data[i + 1];
//         }
//         */
//        memcpy(bufferPCM,pcm_data,buf_sizePCM);
//        /*
//         float in[4096] = { 0 };
//         float out[4096] = { 0 };
//         for (int j = 0; j < 4096 && j < buf_sizePCM; j++)
//         {
//         in[j] = pcm_data[j];
//         }
//         SRC_DATA dataResample;
//         dataResample.data_in = in;
//         dataResample.data_out = out;
//         dataResample.input_frames = frame_info.samples;
//         dataResample.output_frames = frame_info.samples;
//         dataResample.src_ratio =  8000.0/frame_info.samplerate;
//         int nRetResample = src_simple(&dataResample, SRC_SINC_FASTEST, 2);
//         buf_sizePCM = dataResample.output_frames_gen * frame_info.channels;
//         memcpy(bufferPCM, dataResample.data_out, buf_sizePCM);
//         */
//
//        return 0;
//    }
//
    return -1;
}
