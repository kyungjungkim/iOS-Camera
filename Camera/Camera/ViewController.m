//
//  ViewController.m
//  Camera
//
//  Created by Kyungjung Kim on 2022/11/12.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize captureSessionManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupCaptureSessionManager];
}


#pragma mark - Instance Methods

- (void)setupCaptureSessionManager {
    // remove existing input
    AVCaptureInput *currentCameraInput = [captureSessionManager.captureSession.inputs objectAtIndex:0];
    [captureSessionManager.captureSession removeInput:currentCameraInput];
    currentCameraInput = NULL;
    
    
    // Create and configure 'CaptureSessionManager' object
    captureSessionManager = [CaptureSessionManager new];
    
    // Indicate that some changes will be made to the session
    [captureSessionManager.captureSession beginConfiguration];
    
    if (captureSessionManager) {
        // Configure
        if (![captureSessionManager initiateCaptureSessionForCamera])
            [self.navigationController popViewControllerAnimated:YES];
        
        
        [captureSessionManager addVideoPreviewLayer];
        
        [captureSessionManager.captureSession commitConfiguration];
        
        // Add to self.view's layer
        // [self.view.layer addSublayer:[captureSessionManager.rootView layer]];
        [captureSessionManager.previewLayer setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view.layer addSublayer:captureSessionManager.previewLayer];
        
        dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(globalQueue, ^{
            [self->captureSessionManager.captureSession startRunning];
        });
    }
}

@end
