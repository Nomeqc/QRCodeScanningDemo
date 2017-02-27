//
//  ViewController.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/2/25.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeScanController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"扫描二维码Demo";
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"扫一扫" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:20];
    [self.view addSubview:button];
    button.frame = ({
        CGRect frame = button.frame;
        frame.size = button.intrinsicContentSize;
        frame.origin.x = (CGRectGetWidth(self.view.frame) - frame.size.width) /2;
        frame.origin.y = (CGRectGetHeight(self.view.frame) - frame.size.height) /2;
        frame;
    });
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)buttonTapped:(UIButton *)button {
    QRCodeScanController *scanController = [[QRCodeScanController alloc] init];
    [self.navigationController pushViewController:scanController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
