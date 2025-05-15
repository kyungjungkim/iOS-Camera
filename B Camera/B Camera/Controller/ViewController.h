//
//  ViewController.h
//  B Camera
//
//  Created by Kyungjung Kim on 2022/12/09.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "AVCamPhotoCaptureDelegate.h"
#import <Photos/Photos.h>



typedef NS_ENUM(NSInteger, AVCamCheckResult) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

typedef NS_ENUM(NSInteger, ISPreviewExpandOrientation) {
    ISPreviewExpandOrientationPortait,
    ISPreviewExpandOrientationLandscape
};

typedef NS_ENUM(NSInteger, AVCamLivePhotoMode) {
    AVCamLivePhotoModeOn,
    AVCamLivePhotoModeOff
};

typedef NS_ENUM(NSInteger, AVCamDepthDataDeliveryMode) {
    AVCamDepthDataDeliveryModeOn,
    AVCamDepthDataDeliveryModeOff
};

typedef NS_ENUM(NSInteger, AVCamPortraitEffectsMatteDeliveryMode) {
    AVCamPortraitEffectsMatteDeliveryModeOn,
    AVCamPortraitEffectsMatteDeliveryModeOff
};

@interface ViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

// Session management.
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic) AVCamCheckResult checkResult;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (strong, nonatomic) AVCaptureDeviceInput *videoDeviceInput;

// Device configuration.
@property (nonatomic) NSArray<AVCaptureDeviceType> *deviceTypes;
@property (nonatomic) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@property (strong, nonatomic) AVCaptureDevice *activeDevice0;
@property (strong, nonatomic) AVCaptureDevice *activeDevice1;

// Capturing photos.
@property (nonatomic) AVCamDepthDataDeliveryMode depthDataDeliveryMode;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOuput;
@property (nonatomic) AVCamLivePhotoMode livePhotoMode;
@property (nonatomic) AVCamPortraitEffectsMatteDeliveryMode portraitEffectsMatteDeliveryMode;
@property (nonatomic) AVCapturePhotoQualityPrioritization photoQualityPrioritizationMode;

@property (assign, nonatomic) ISPreviewExpandOrientation expandOrientation;

@property (nonatomic) AVCapturePhotoOutput *photoOutput;
@property (nonatomic) NSArray<AVSemanticSegmentationMatteType> *selectedSemanticSegmentationMatteTypes;
@property (nonatomic) NSMutableDictionary<NSNumber *, AVCamPhotoCaptureDelegate *> *inProgressPhotoCaptureDelegates;
@property (nonatomic) NSInteger inProgressLivePhotoCapturesCount;

@property (nonatomic) CLLocationManager *locationManager;

@property (nonatomic, retain) UIActivityIndicatorView *spinner;

@property (nonatomic) BOOL isRotate;
@property (assign, nonatomic) NSInteger imageFrameWidth;
@property (assign, nonatomic) NSInteger imageFrameHeight;

- (void)checkPhotoPermission;
- (void)requestPhoto;
- (PHFetchResult *)requestPHFetchResult;
- (BOOL)configureSession;
- (void)setupVideoDeviceTypes;
- (AVCaptureDevice *)selectVideoDevice;
- (void)selectSessionPreset;
- (void)addVideoPreviewLayer;
- (void)captureSessionStartRunning;
- (BOOL)savaPhoto;

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (weak, nonatomic) IBOutlet UIButton *capturePhotoBtn;
@property (weak, nonatomic) IBOutlet UIButton *cameraRotateBtn;

- (IBAction)photoBtn:(UIButton *)sender;
- (IBAction)capturePhotoBtn:(UIButton *)sender;
- (IBAction)cameraRotateBtn:(UIButton *)sender;

@end

