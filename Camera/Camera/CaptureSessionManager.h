//
//  CaptureSessionManager.h
//  AVFoundation
//
//  Created by kyungjung kim on 2016. 8. 8..
//  Copyright © 2016년 kyungjung kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@interface CaptureSessionManager : NSObject

typedef NS_ENUM(NSInteger, ISPreviewExpandOrientation) {
    ISPreviewExpandOrientationPortait,
    ISPreviewExpandOrientationLandscape
};

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDevice *activeDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *cameraDeviceInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOuput;

@property (strong, nonatomic) UIView *rootView;
@property (assign, nonatomic) NSInteger imageFrameWidth;
@property (assign, nonatomic) NSInteger imageFrameHeight;
@property (assign, nonatomic) ISPreviewExpandOrientation expandOrientation;


- (BOOL)initiateCaptureSessionForCamera;
- (void)addVideoPreviewLayer;

@end
