//
//  QRCodeScanController.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/2/25.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "QRCodeScanController.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"
#import "ScanningResultController.h"

@interface QRCodeScanController ()
<AVCaptureMetadataOutputObjectsDelegate>

//二维码扫描矩形框
@property (strong, nonatomic) UIImageView *scanningCropView;

//加载框
@property (strong, nonatomic) UIView *loadingView;

@property (strong, nonatomic) AVCaptureDevice *device;

@property (strong, nonatomic) AVCaptureInput *input;

@property (strong, nonatomic) AVCaptureMetadataOutput *output;

@property (strong, nonatomic) AVCaptureSession *session;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;


@end

@implementation QRCodeScanController {
    UIView *_sweepView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    if (_session.isRunning) {
        [_session stopRunning];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAppBecomeAciveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAppDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"扫一扫";
    self.view.backgroundColor = [UIColor blackColor];
    [self setupUI];
    
    [self registerNotification];
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self setupCamera];
                    });
                } else {
                    [self showTipsAlert];
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self setupCamera];
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
        {
            [self showTipsAlert];
            break;
        }
            
        default:
            break;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self isCanAccessCamera] && ![self.session isRunning]) {
        [self.session startRunning];
    }
    [self startAnimationSweep];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopAnimationSweep];
}


- (void)startAnimationSweep {
    _sweepView.hidden = NO;
    _sweepView.frame = CGRectMake(0, 0, CGRectGetWidth(self.scanningCropView.frame), 2);
    [UIView animateWithDuration:2. delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationCurveLinear animations:^{
        _sweepView.frame = CGRectMake(0, CGRectGetHeight(self.scanningCropView.frame)- 2, CGRectGetWidth(self.scanningCropView.frame), 2);
    } completion:nil];
}

- (void)stopAnimationSweep {
    _sweepView.frame = CGRectMake(0, 0, CGRectGetWidth(self.scanningCropView.frame), 2);
    _sweepView.hidden = YES;
}
#pragma mark - Notification Handler
- (void)didReceiveAppBecomeAciveNotification:(NSNotification *)notification {
    [self startAnimationSweep];
}

- (void)didReceiveAppDidEnterBackgroundNotification:(NSNotification *)notification {
    [self stopAnimationSweep];
}

- (void)setupUI {
    [self.view addSubview:self.scanningCropView];
    [self.view addSubview:self.loadingView];
    [self.scanningCropView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.offset(0);
        make.left.offset(64);
        make.width.equalTo(self.scanningCropView.mas_height);
    }];
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    UIView *topPlaceView = [[UIView alloc] init];
    UIView *leftPlaceView = [[UIView alloc] init];
    UIView *rightPlaceView = [[UIView alloc] init];
    UIView *bottomPlaceView = [[UIView alloc] init];
    topPlaceView.backgroundColor =
    leftPlaceView.backgroundColor =
    rightPlaceView.backgroundColor =
    bottomPlaceView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [self.view addSubview:topPlaceView];
    [self.view addSubview:leftPlaceView];
    [self.view addSubview:rightPlaceView];
    [self.view addSubview:bottomPlaceView];
    [topPlaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.offset(0);
        make.bottom.equalTo(self.scanningCropView.mas_top);
    }];
    [leftPlaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.scanningCropView);
        make.left.offset(0);
        make.right.equalTo(self.scanningCropView.mas_left);
    }];
    [rightPlaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.scanningCropView);
        make.right.offset(0);
        make.left.equalTo(self.scanningCropView.mas_right);
    }];
    [bottomPlaceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.offset(0);
        make.top.equalTo(self.scanningCropView.mas_bottom);
    }];
    [self.view bringSubviewToFront:self.loadingView];
    
}

- (void)setupCamera {
    CGRect videoPreviewFrame = self.view.bounds;
    CGRect QRCodeScanningRect = self.scanningCropView.frame;
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
    //设置输出类型为二维码
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    [self.output setRectOfInterest:({
        CGRect portraitScanningRect = QRCodeScanningRect;
        CGSize landscapePreviewSize = CGSizeMake(CGRectGetHeight(videoPreviewFrame), CGRectGetWidth(videoPreviewFrame));
        CGRect landscapeScanningRect = ({
            CGRect rect;
            rect.origin = CGPointMake(portraitScanningRect.origin.y, landscapePreviewSize.height - CGRectGetMaxX(portraitScanningRect));
            rect.size = CGSizeMake(CGRectGetHeight(portraitScanningRect), CGRectGetWidth(portraitScanningRect));
            rect;
        });
        CGFloat p1 = 1080./1920.;
        CGFloat p2 = landscapePreviewSize.height / landscapePreviewSize.width;
        /**
          屏幕高宽比 和 视频预设不相符时，需要做适当修正
         */
        CGRect rectOfInterest = ({
            CGRect rect;
            if (p1 < p2) {//屏幕宽度小于预设宽度，需对x进行修正
                CGFloat fitWidth = landscapePreviewSize.height / p1;//(当前实际高度对应的预设宽度)
                CGFloat xOffset = (fitWidth - landscapePreviewSize.width) / 2;
                rect.origin.x = (landscapeScanningRect.origin.x + xOffset)/landscapePreviewSize.width;
                rect.origin.y = landscapeScanningRect.origin.y / landscapePreviewSize.height;
            } else {//屏幕高度小于预设高度，需对y进行修正
                CGFloat fitHeight = landscapePreviewSize.width * p1;//(当前实际宽度对应的预设高度)
                CGFloat yOffset = (fitHeight - landscapePreviewSize.height) / 2;
                rect.origin.x = landscapeScanningRect.origin.x / landscapePreviewSize.width;
                rect.origin.y = (landscapeScanningRect.origin.y + yOffset)/landscapePreviewSize.height;
            }
            rect.size.width = CGRectGetWidth(landscapeScanningRect) / landscapePreviewSize.width;
            rect.size.height = CGRectGetHeight(landscapeScanningRect) / landscapePreviewSize.height;
            rect;
        });
        rectOfInterest;
    })];
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = videoPreviewFrame;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    [self.session startRunning];
    _loadingView.hidden = YES;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        //数组中包含的都是AVMetadataMachineReadableCodeObject 类型的对象，该对象中包含解码后的数据
        AVMetadataMachineReadableCodeObject *qrObject = [metadataObjects lastObject];
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
        ScanningResultController *resultController = [[ScanningResultController alloc] init];
        resultController.result = qrObject.stringValue;
        [self.navigationController pushViewController:resultController animated:YES];
        NSLog(@"识别成功：%@",qrObject.stringValue);
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Helper

- (void)showTipsAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"未获得授权使用摄像头" message:@"请在iOS\"设置\"-\"隐私\"-\"相机\"中打开" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
    [alert show];
}

- (BOOL)isCanAccessCamera {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized;
}

#pragma mark - Accessors
- (UIView *)loadingView {
	if(_loadingView == nil) {
		_loadingView = [[UIView alloc] init];
        _loadingView.backgroundColor = [UIColor blackColor];
        UILabel *tipsLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.text = @"正在加载...";
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:14];
            tipsLabel = label;
            label;
        });
        UIActivityIndicatorView *indicator = ({
            UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] init];
            [view startAnimating];
            view.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
            indicator = view;
            view;
        });
        UIView *assistView = ({
            UIView *view = [[UIView alloc] init];
            view;
        });
        [_loadingView addSubview:tipsLabel];
        [_loadingView addSubview:indicator];
        [_loadingView addSubview:assistView];
        [indicator mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
        }];
        [tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
            make.top.equalTo(indicator.mas_bottom).offset(15);
        }];
        [assistView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.offset(0);
            make.top.equalTo(indicator);
            make.bottom.equalTo(tipsLabel);
        }];
	}
	return _loadingView;
}

- (UIImageView *)scanningCropView {
	if(_scanningCropView == nil) {
        _scanningCropView = [[UIImageView alloc] init];
        _scanningCropView.image = [UIImage imageNamed:@"scan_rect"];
        UIView *sweepView = [[UIView alloc] init];
        sweepView.layer.cornerRadius = 1;
        sweepView.backgroundColor = [UIColor colorWithRed:56/255.0 green:195/255.0 blue:236/255.0 alpha:1];
        _sweepView = sweepView;
        [_scanningCropView addSubview:sweepView];
	}
	return _scanningCropView;
}

@end
