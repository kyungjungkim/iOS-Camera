//
//  PhotoViewController.h
//  B Camera
//
//  Created by Kyungjung Kim on 2022/12/10.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoViewController : UIViewController


@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

- (IBAction)backBtn:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
