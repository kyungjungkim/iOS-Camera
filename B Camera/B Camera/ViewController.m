//
//  ViewController.m
//  B Camera
//
//  Created by Kyungjung Kim on 2022/12/09.
//

#import "ViewController.h"

extern int selectedIndex;
extern UIImage *personalImage;
extern PHFetchResult<PHAsset *> *fetchPhotos;

@interface ViewController ()

@end


@implementation ViewController

@synthesize activeDevice0, activeDevice1, videoDataOuput, previewLayer, captureSession, expandOrientation, videoDeviceInput, imageFrameWidth, imageFrameHeight,
inProgressPhotoCaptureDelegates, photoQualityPrioritizationMode, inProgressLivePhotoCapturesCount, spinner, photoBtn, capturePhotoBtn, cameraRotateBtn;

@synthesize cameraView, sessionQueue, checkResult, sessionRunning, videoDeviceDiscoverySession, photoOutput, livePhotoMode, depthDataDeliveryMode,
portraitEffectsMatteDeliveryMode, selectedSemanticSegmentationMatteTypes, deviceTypes;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    _isRotate = false;
    
    // Create the AVCaptureSession.
    captureSession = [AVCaptureSession new];
    previewLayer = [AVCaptureVideoPreviewLayer new];
    [self addVideoPreviewLayer];
    
    
    // Communicate with the session and other session objects on this queue.
    self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    
    self.checkResult = AVCamSetupResultCameraNotAuthorized;
    
    
    // Request location authorization so photos and videos can be tagged with their location.
    self.locationManager = [CLLocationManager new];
    if (kCLAuthorizationStatusNotDetermined == self.locationManager.authorizationStatus) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self checkPhotoPermission];
}

- (void)viewDidDisappear:(BOOL)animated {
    dispatch_async(self.sessionQueue, ^{
        if (true == self->captureSession.isRunning) {
            [self->captureSession stopRunning];
            
            NSLog(@"B Camera: stopRunning");
//            [self removeObservers];
        } else
            return;
    });
    
    captureSession = NULL;
    [self.previewLayer removeFromSuperlayer];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}


#pragma mark - Instance Methods

- (void)requestPhoto {
    PHFetchResult *fetchResult = [self requestPHFetchResult];
//    NSMutableArray<PHAsset *> *assets = [NSMutableArray array];
//    [result enumerateObjectsUsingBlock:^(id _Nonnull object, NSUInteger idx, BOOL *_Nonnull stop) {
//        if ([object isKindOfClass:[PHAsset class]]) {
//            [assets addObject:object];
//            // 배열등 원하는 형태로 저장
//        }
//    }];

    PHImageManager *imageManager = [PHImageManager new];
    [imageManager requestImageForAsset:fetchResult.firstObject targetSize:CGSizeMake(55.0f, 55.0f) contentMode:PHImageContentModeDefault
                               options:NULL resultHandler:^(UIImage *result, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *newImage = result;
            newImage = [result imageByPreparingThumbnailOfSize:CGSizeMake(self->photoBtn.frame.size.width, self->photoBtn.frame.size.height)];
            [self->photoBtn setImage:newImage forState:UIControlStateNormal];
        });
    }];
}

- (PHFetchResult *)requestPHFetchResult {
    PHFetchResult<PHAssetCollection *> *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                                             options:NULL];
    PHAssetCollection *cameraRollCollection = [cameraRoll firstObject];
    
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.fetchLimit = 1;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:false];
    [fetchOptions setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:cameraRollCollection options:fetchOptions];
    
    //    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    //    fetchOptions.fetchLimit = 1;
        
        // 정렬
    //    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    //    fetchOptions.sortDescriptors = [ NSArray arrayWithObject:sort ];
        // 특정 조건
    //    requestOptions.predicate = [NSPredicate predicateWithFormat:@“creationDate > %@ AND creationDate < %@“, startDate, endDate];
    //    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    
    return fetchResult;
}

- (void)checkPhotoPermission {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                self->checkResult = AVCamSetupResultSuccess;
                
                [self requestPhoto];
                [self configureSession];
                
                break;
            }
            case PHAuthorizationStatusNotDetermined: {
                self->checkResult = AVCamSetupResultCameraNotAuthorized;
                break;
            }
            case PHAuthorizationStatusRestricted: {
                self->checkResult = AVCamSetupResultSuccess;
                break;
            }
            case PHAuthorizationStatusDenied: {
                self->checkResult = AVCamSetupResultCameraNotAuthorized;
                break;
            }
            case PHAuthorizationStatusLimited: {
                self->checkResult = AVCamSetupResultSuccess;
                break;
            }
        }
    }];
}

- (BOOL)configureSession {
    if (checkResult != AVCamSetupResultSuccess) {
        NSLog(@"B Camera: AVCamSetupResultCameraNotAuthorized");
        
        return false;
    }
    
    NSError *error = nil;
    
    AVCaptureDevice *currentDevice = [self selectVideoDevice];
    
//    [self.captureSession beginConfiguration];
    
    if (!_isRotate) {
        videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:currentDevice error:&error];
        NSLog(@"B Camera: Device Position - %ld", (long)videoDeviceInput.device.position);
        
        if (!videoDeviceInput) {
            NSLog(@"B Camera: Could not create video device input - %@", error);
            
            //        self.checkResult = AVCamSetupResultSessionConfigurationFailed;
            return false;
        } else {
            if ([captureSession canAddInput:videoDeviceInput]) {
                [captureSession addInput:videoDeviceInput];
            } else {
                NSLog(@"B Camera: The device does not support the camera - %@", error);
                
                return false;
            }
        }
        
        // Add photo output.
        photoOutput = [AVCapturePhotoOutput new];
        if ([captureSession canAddOutput:photoOutput]) {
            [captureSession addOutput:photoOutput];
            
            self.photoQualityPrioritizationMode = AVCapturePhotoQualityPrioritizationBalanced;
            self.inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
        } else {
            NSLog(@"B Camera: The terminal cannot save the video - %@", error);
            
            return false;
        }
        
//        [self.captureSession commitConfiguration];
        
        [self captureSessionStartRunning];
        
        return true;
    } else if (_isRotate) {
        NSLog(@"B Camera: captureSessionPreset - %@", captureSession.sessionPreset);
        
        // Make a video data input
        AVCaptureInput *currentCameraInput = [captureSession.inputs objectAtIndex:0];
        AVCaptureOutput *currentCameraOutput = [captureSession.outputs objectAtIndex:0];
        [captureSession removeInput:currentCameraInput];
        [captureSession removeOutput:currentCameraOutput];
            
        videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:currentDevice error:&error];
        NSLog(@"B Cameera: Device Position - %ld", (long)videoDeviceInput.device.position);
                  
        if (!videoDeviceInput) {
            NSLog(@"B Camera: Could not create video device input - %@", error);
                
            //        self.checkResult = AVCamSetupResultSessionConfigurationFailed;
            return false;
        } else {
            if ([captureSession canAddInput:videoDeviceInput]) {
                [captureSession addInput:videoDeviceInput];
            } else {
                NSLog(@"B Camera: The device does not support the camera - %@", error);
                
                return false;
            }
        }
        
        // Add photo output.
        photoOutput = [AVCapturePhotoOutput new];
        if ([captureSession canAddOutput:photoOutput]) {
            [captureSession addOutput:photoOutput];
            
            self.photoQualityPrioritizationMode = AVCapturePhotoQualityPrioritizationBalanced;
            self.inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionary];
        } else {
            NSLog(@"B Camera: The terminal cannot save the video - %@", error);
            
            return false;
        }
        
        //    // Make a video data output
        //    videoDataOuput = [AVCaptureVideoDataOutput new];
        //
        //
        //    // We want YUV, both CoreGraphics and OpenGL work well with 'YUV'
        //    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        //                                                                  forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        //    [videoDataOuput setVideoSettings:rgbOutputSettings];
        //    [videoDataOuput setAlwaysDiscardsLateVideoFrames:YES];
        //
        //
        //    if ([captureSession canAddOutput:videoDataOuput]) {
        //        [captureSession addOutput:videoDataOuput];
        //    } else
        //        NSLog(@"%@", error);
        //
        //    [[videoDataOuput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
        
//        [self.captureSession commitConfiguration];
        
        [self captureSessionStartRunning];
        
        self->_isRotate = false;
        
        return true;
    }
    
    checkResult = AVCamSetupResultSessionConfigurationFailed;
    return false;
}

- (void)setupVideoDeviceTypes {
    if (@available(iOS 15.4, *)) {
        deviceTypes = [NSArray arrayWithObjects:AVCaptureDeviceTypeBuiltInMicrophone, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTripleCamera,
                       AVCaptureDeviceTypeBuiltInDualWideCamera, AVCaptureDeviceTypeBuiltInUltraWideCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera,
                       AVCaptureDeviceTypeBuiltInTrueDepthCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, AVCaptureDeviceTypeBuiltInLiDARDepthCamera, nil];
    } else {
        // Fallback on earlier versions
        
        deviceTypes = [NSArray arrayWithObjects:AVCaptureDeviceTypeBuiltInMicrophone, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTripleCamera,
                       AVCaptureDeviceTypeBuiltInDualWideCamera, AVCaptureDeviceTypeBuiltInUltraWideCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera,
                       AVCaptureDeviceTypeBuiltInTrueDepthCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, nil];
    }
}

- (AVCaptureDevice *)selectVideoDevice {
//        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//        dispatch_async(globalQueue, ^{
//            [self->captureSession startRunning];
//        });
    
    /*
     We do not create an AVCaptureMovieFileOutput when setting up the session because
     Live Photo is not supported when AVCaptureMovieFileOutput is added to the session.
    */
    

//    Select a video device
    if (!_isRotate) {
        [self setupVideoDeviceTypes];
        [self selectSessionPreset];
        
        // Choose the back dual camera if available, otherwise default to a wide angle camera.
        videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        
        for(AVCaptureDevice *camera in videoDeviceDiscoverySession.devices) {
            if ([camera position] == AVCaptureDevicePositionBack) { // is back camera
                activeDevice0 = camera;
                
                break;
            }
        }
        NSLog(@"B Camera: DeviceType - %@", activeDevice0.deviceType);
        
        return activeDevice0;
    } else if (_isRotate) {
        // Choose the back dual camera if available, otherwise default to a wide angle camera.
        if (AVCaptureDevicePositionBack == videoDeviceInput.device.position) {
            videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
            
            for(AVCaptureDevice *camera in videoDeviceDiscoverySession.devices) {
                if ([camera position] == AVCaptureDevicePositionFront) { // is front camera
                    activeDevice1 = camera;
                    
                    break;
                }
            }
            NSLog(@"B Camera: DeviceType -  %@", activeDevice1.deviceType);
            
            activeDevice0 = NULL;
            
            return activeDevice1;
        } else if (AVCaptureDevicePositionFront == videoDeviceInput.device.position) {            
            videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
            
            for(AVCaptureDevice *camera in videoDeviceDiscoverySession.devices) {
                if ([camera position] == AVCaptureDevicePositionBack) { // is back camera
                    activeDevice1 = camera;
                    
                    break;
                }
            }
            NSLog(@"B Camera: DeviceType - : %@", activeDevice0.deviceType);
            
            activeDevice0 = NULL;
            
            return activeDevice1;
        }
    }
    
    return NULL;
}

- (void)selectSessionPreset {
    if ([captureSession canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        [captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
        
//        A preset suitable for capturing high-resolution photo quality output.
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetiFrame1280x720]) {
        [captureSession setSessionPreset:AVCaptureSessionPresetiFrame1280x720];
        
//        A preset suitable for capturing 1280 x 720 quality iFrame H.264 video at about 40 Mbits/sec with AAC audio.
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetiFrame960x540]) {
        [captureSession setSessionPreset:AVCaptureSessionPresetiFrame960x540];
        
//        A preset suitable for capturing 960 x 540 quality iFrame H.264 video at about 30 Mbits/sec with AAC audio.
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset3840x2160];
    
//        A preset suitable for capturing 2160p-quality (3840 x 2160 pixels) video output.
    NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
    
    imageFrameWidth = 3840;
    imageFrameHeight = 2160;
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
        
//        A preset suitable for capturing 1080p-quality (1920 x 1080 pixels) video output.
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
        
        imageFrameWidth = 1920;
        imageFrameHeight = 1080;
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
        
//        A preset sitable for capturing 720p quality (1280 x 720 pixel) video output.
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
        
        imageFrameWidth = 1280;
        imageFrameHeight = 720;
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
        
//        A preset suitable for capturing VGA quality (640 x 480 pixel) video output.
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
        
        imageFrameWidth = 640;
        imageFrameHeight = 480;
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset352x288];
        
//        A preset suitable for capturing CIF quality (352 x 288 pixel) video output.
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
        
        imageFrameHeight = 352;
        imageFrameWidth = 288;
    } else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetInputPriority]) {
        [captureSession setSessionPreset:AVCaptureSessionPresetInputPriority];
        
        NSLog(@"B Camera - captureSessionPreset: %@", captureSession.sessionPreset);
    } else {
        NSLog(@"B Camera - failed selectSessionPreset");
    }
}

- (void)captureSessionStartRunning {
//    dispatch_async(self->sessionQueue, ^{
        switch (self->checkResult) {
            case AVCamSetupResultSuccess: {
                dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^{
                    // Only setup observers and start the session running if setup succeeded.
                    //                [self addObservers];
                    [self->captureSession startRunning];
                });
                NSLog(@"B Camera: startRunning");
                
                self->sessionRunning = self->captureSession.isRunning;
                break;
            }
            case AVCamSetupResultCameraNotAuthorized: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button") style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"Alert button to open Settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [alertController addAction:settingsAction];
                    
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString(@"Unable to capture media", @"Alert message when something goes wrong during capture session configuration");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Alert OK button") style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    
                    [self presentViewController:alertController animated:YES completion:nil];
                });
                break;
            }
        }
//    });
}

- (void)addVideoPreviewLayer {
    previewLayer.session = captureSession;
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    //    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    //    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [previewLayer setVideoGravity:AVLayerVideoGravityResize];
    [previewLayer setFrame:CGRectMake(0.0f, 0.0f, cameraView.layer.frame.size.width, cameraView.layer.frame.size.height)];
    [cameraView.layer addSublayer:previewLayer];
    
    // Apply animation effect to the camera's preview layer
    CATransition *applicationLoadViewIn = [CATransition animation];
    [applicationLoadViewIn setDuration:0.6f];
    [applicationLoadViewIn setType:kCATransitionReveal];
    [applicationLoadViewIn setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [previewLayer addAnimation:applicationLoadViewIn forKey:kCATransitionReveal];
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    //        self.spinner.color = [UIColor yellowColor];
    //        [self.cameraView addSubview:self.spinner];
    //    });
}

- (BOOL)savaPhoto {
    /*
     Retrieve the video preview layer's video orientation on the main queue before
     entering the session queue. We do this to ensure UI elements are accessed on
     the main thread and session configuration is done on the session queue.
    */
//    AVCaptureVideoOrientation videoPreviewLayerVideoOrientation = self.previewLayer.connection.videoOrientation;

    dispatch_async(self.sessionQueue, ^{
        // Update the photo output's connection to match the video orientation of the video preview layer.
        AVCaptureConnection *photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
        photoOutputConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
        AVCapturePhotoSettings *photoSettings;
        // Capture HEIF photos when supported, with the flash set to enable auto- and high-resolution photos.
        if ([self.photoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
            photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{ AVVideoCodecKey : AVVideoCodecTypeHEVC }];
        } else {
            photoSettings = [AVCapturePhotoSettings photoSettings];
        }
        
        if (self.videoDeviceInput.device.isFlashAvailable) {
            photoSettings.flashMode = AVCaptureFlashModeAuto;
        }
        photoSettings.highResolutionPhotoEnabled = false;
       
        if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0) {
            photoSettings.previewPhotoFormat = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
        }
        
        if (self.livePhotoMode == AVCamLivePhotoModeOn && self->photoOutput.livePhotoCaptureSupported) { // Live Photo capture is not supported in movie mode.
            NSString *livePhotoMovieFileName = [NSUUID UUID].UUIDString;
            
            // 2023. 02. 12 수정
//            NSString *livePhotoMovieFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[livePhotoMovieFileName stringByAppendingPathExtension:@"mov"]];
//            photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoMovieFilePath];
            photoSettings.livePhotoMovieFileURL = nil;
        }
        
        photoSettings.depthDataDeliveryEnabled = (self.depthDataDeliveryMode == AVCamDepthDataDeliveryModeOn && self.photoOutput.isDepthDataDeliveryEnabled);
        
        photoSettings.portraitEffectsMatteDeliveryEnabled = (self.portraitEffectsMatteDeliveryMode == AVCamPortraitEffectsMatteDeliveryModeOn && self.photoOutput.isPortraitEffectsMatteDeliveryEnabled);
        
        if (photoSettings.depthDataDeliveryEnabled && self.photoOutput.availableSemanticSegmentationMatteTypes.count > 0) {
            photoSettings.enabledSemanticSegmentationMatteTypes = self.selectedSemanticSegmentationMatteTypes;
        }
        
        photoSettings.photoQualityPrioritization = self.photoQualityPrioritizationMode;
        
        // Use a separate object for the photo capture delegate to isolate each capture life cycle.
        AVCamPhotoCaptureDelegate *photoCaptureDelegate = [[AVCamPhotoCaptureDelegate alloc] initWithRequestedPhotoSettings:photoSettings willCapturePhotoAnimation:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.previewLayer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewLayer.opacity = 1.0;
                }];
            });
        } livePhotoCaptureHandler:^(BOOL capturing) {
            /*
             Because Live Photo captures can overlap, we need to keep track of the
             number of in progress Live Photo captures to ensure that the
             Live Photo label stays visible during these captures.
            */
            dispatch_async(self.sessionQueue, ^{
                if (capturing) {
                    self.inProgressLivePhotoCapturesCount++;
                } else {
                    self.inProgressLivePhotoCapturesCount--;
                }
                
//                NSInteger inProgressLivePhotoCapturesCount = self.inProgressLivePhotoCapturesCount;
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (inProgressLivePhotoCapturesCount > 0) {
//                        self.capturingLivePhotoLabel.hidden = NO;
//                    } else if (inProgressLivePhotoCapturesCount == 0) {
//                        self.capturingLivePhotoLabel.hidden = YES;
//                    } else {
//                        NSLog(@"Error: In progress Live Photo capture count is less than 0.");
//                    }
//                });
            });
        } completionHandler:^(AVCamPhotoCaptureDelegate *photoCaptureDelegate) {
            // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
            dispatch_async(self.sessionQueue, ^{
                self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = nil;
            });
            
            [self requestPhoto];
        } photoProcessingHandler:^(BOOL animate) {
            // Animates a spinner while photo is processing
            dispatch_async(dispatch_get_main_queue(), ^{
                if (animate) {
                    self.spinner.hidesWhenStopped = YES;
                    self.spinner.center = CGPointMake(self.cameraView.frame.size.width / 2.0, self.cameraView.frame.size.height / 2.0);
                    [self.spinner startAnimating];
                } else {
                    [self.spinner stopAnimating];
                }
            });
        }];
        
        // Specify the location the photo was taken
        photoCaptureDelegate.location = self.locationManager.location;
        
        /*
         The Photo Output keeps a weak reference to the photo capture delegate so
         we store it in an array to maintain a strong reference to this object
         until the capture is completed.
        */
        self.inProgressPhotoCaptureDelegates[@(photoCaptureDelegate.requestedPhotoSettings.uniqueID)] = photoCaptureDelegate;
        
        [self.photoOutput capturePhotoWithSettings:photoSettings delegate:photoCaptureDelegate];
    });
    
    return true;
}

- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return destImage;
}


#pragma mark - IBAction methods

- (IBAction)photoBtn:(UIButton *)sender {
    //    GalleryViewController *galleryVC = [GalleryViewController new];
    //
    //    [self.navigationController pushViewController:galleryVC animated:YES];
    
    UIImagePickerController *pickerLibrary = [UIImagePickerController new];
    pickerLibrary.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [pickerLibrary setAllowsEditing:YES];
    pickerLibrary.delegate = self;
    
    [self presentViewController:pickerLibrary animated:YES completion:nil];
}

- (IBAction)capturePhotoBtn:(UIButton *)sender {
    [self savaPhoto];
}

- (IBAction)cameraRotateBtn:(UIButton *)sender {
    _isRotate = true;
    
    [self configureSession];
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    UIImage *newImage = [image imageByPreparingThumbnailOfSize:CGSizeMake(photoBtn.frame.size.width, photoBtn.frame.size.height)];
    [photoBtn setImage:newImage forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

//error
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
//    NSString *ediaType = [info objectForKey:UIImagePickerControllerMediaType];
//
//    UIImage *newImage = info[UIImagePickerControllerOriginalImage];
//    [photoBtn setImage:newImage forState:UIControlStateNormal];
//
//    [self dismissViewControllerAnimated:YES completion:nil];
//}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
