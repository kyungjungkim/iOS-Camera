//
//  ViewController.h
//  Camera
//
//  Created by Kyungjung Kim on 2022/01/31.
//

#import <UIKit/UIKit.h>

#import "CaptureSessionManager.h"


@interface ViewController : UIViewController

@property (strong, nonatomic) CaptureSessionManager *captureSessionManager;

- (void)setupCaptureSessionManager;

@end

