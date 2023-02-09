//
//  PhotoViewController.m
//  B Camera
//
//  Created by Kyungjung Kim on 2022/12/10.
//

#import "PhotoViewController.h"

extern int selectedIndex;
extern UIImage *personalImage;
extern PHFetchResult<PHAsset *> *fetchPhotos;

@interface PhotoViewController ()

@end

@implementation PhotoViewController

@synthesize photoImageView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    photoImageView.image = personalImage;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)backBtn:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
