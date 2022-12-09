//
//  CaptureSessionManager.m
//  AVFoundation
//
//  Created by kyungjung kim on 2016. 8. 8..
//  Copyright © 2016년 kyungjung kim. All rights reserved.
//

#import "CaptureSessionManager.h"


@implementation CaptureSessionManager

@synthesize activeDevice, videoDataOuput, previewLayer, captureSession, rootView, expandOrientation, cameraDeviceInput, imageFrameWidth, imageFrameHeight;


#pragma mark - Capture Session Configuration


// Instance Methods

- (id)init {
    if ((self = [super init])) {
        [self setCaptureSession:[AVCaptureSession new]];
        // captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        
        
        NSLog(@"captureSessionPreset: %@", captureSession.sessionPreset);
        
        // 1920*1080 is the suggested size if it is supported by device.
        if ([captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
            
            [captureSession setSessionPreset:AVCaptureSessionPreset3840x2160];
            imageFrameWidth = 3840;
            imageFrameHeight = 2160;
        } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            // NSLog(@"AVCaptureSessionPreset1920x1080");
            
            [captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
            imageFrameWidth = 1920;
            imageFrameHeight = 1080;
        } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
            // NSLog(@"AVCaptureSessionPreset640x480");
            
            [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
            imageFrameWidth = 640;
            imageFrameHeight = 480;
        } else  if ([captureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
            // NSLog(@"AVCaptureSessionPreset352x288");
            
            [captureSession setSessionPreset:AVCaptureSessionPreset352x288];
            imageFrameHeight = 352;
            imageFrameWidth = 288;
        } else {
            NSLog(@"failed setSessionPreset");
        }
    }
    
    return self;
}

- (BOOL)initiateCaptureSessionForCamera {
    NSError *error = nil;
    
    // Select a video device
    activeDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
    // Make a video data input
    cameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:activeDevice error:&error];
    
   
    if ([captureSession canAddInput:cameraDeviceInput]) {
        [captureSession addInput:cameraDeviceInput];
    } else {
        NSLog(@"%@: 단말기가 카메라를 지원하지 않습니다", error);
        
        return false;
    }
    
    
    // Make a video data output
    videoDataOuput = [AVCaptureVideoDataOutput new];
    
    
    // We want YUV, both CoreGraphics and OpenGL work well with 'YUV'
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [videoDataOuput setVideoSettings:rgbOutputSettings];
    [videoDataOuput setAlwaysDiscardsLateVideoFrames:YES];
    
    
    if ([captureSession canAddOutput:videoDataOuput]) {
        [captureSession addOutput:videoDataOuput];
    } else
        NSLog(@"%@", error);
    
    [[videoDataOuput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    return true;
}

- (void)addVideoPreviewLayer {
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResize];
    
    
    // Apply animation effect to the camera's preview layer
    CATransition *applicationLoadViewIn = [CATransition animation];
    [applicationLoadViewIn setDuration:0.6f];
    [applicationLoadViewIn setType:kCATransitionReveal];
    [applicationLoadViewIn setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [previewLayer addAnimation:applicationLoadViewIn forKey:kCATransitionReveal];
}

@end
