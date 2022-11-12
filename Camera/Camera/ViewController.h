//
//  ViewController.h
//  Camera
//
//  Created by Kyungjung Kim on 2022/11/12.
//

#import <UIKit/UIKit.h>

#import "CaptureSessionManager.h"


NS_ASSUME_NONNULL_BEGIN

@interface ViewController : UIViewController

@property (strong, nonatomic) CaptureSessionManager *captureSessionManager;


- (void)setupCaptureSessionManager;

@end

NS_ASSUME_NONNULL_END
