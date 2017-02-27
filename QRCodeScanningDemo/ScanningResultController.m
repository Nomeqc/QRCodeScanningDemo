//
//  ScanningResultController.m
//  QRCodeScanningDemo
//
//  Created by iOSDeveloper003 on 17/2/27.
//  Copyright © 2017年 Liang. All rights reserved.
//

#import "ScanningResultController.h"
#import <WebKit/WebKit.h>

@interface ScanningResultController ()


@end

@implementation ScanningResultController {
    WKWebView *_webView;
    UIProgressView *_progressView;
}

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"扫描结果";
    [self setupUI];
    NSMutableArray *barButtonItems = [NSMutableArray new];
    [barButtonItems addObject:[[UIBarButtonItem alloc] initWithTitle:@"复制" style:UIBarButtonItemStylePlain target:self action:@selector(copyBarButtonTapped:)]];
    if ([self isUrlString:self.result]) {
        [barButtonItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshBarButtonTapped:)]];
    }
    self.navigationItem.rightBarButtonItems = barButtonItems;
}

- (void)copyBarButtonTapped:(UIBarButtonItem *)barButtonItem {
    [UIPasteboard generalPasteboard].string = self.result;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"扫描结果已复制到剪切板" message:@"" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
    [alert show];
}

- (void)refreshBarButtonTapped:(UIBarButtonItem *)barButtonItem {
    [_webView reload];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    if ([self isUrlString:self.result]) {
        WKWebView *webView = ({
            WKWebView *webView = [[WKWebView alloc] init];
            [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.result]]];
            webView.frame = self.view.bounds;
            _webView = webView;
            webView;
        });
        UIProgressView *progressView = ({
            UIProgressView *progressView = [[UIProgressView alloc] init];
            progressView.trackTintColor = [UIColor clearColor];
            progressView.frame = CGRectMake(0, 65, CGRectGetWidth(self.view.frame), 2);
            _progressView = progressView;
            progressView;
        });
        [self.view addSubview:webView];
        [self.view addSubview:progressView];
    } else {
        UILabel *label = ({
            UILabel *label = [[UILabel alloc] init];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = self.result;
            label.font = [UIFont systemFontOfSize:20];
            label.numberOfLines = 0;
            label.frame = CGRectMake(15, 84, CGRectGetWidth(self.view.frame) - 30, 250);
            label;
        });
        [self.view addSubview:label];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == _webView) {
        _progressView.alpha = 1.;
        [_progressView setProgress:_webView.estimatedProgress];
        if (_webView.estimatedProgress >= 1.0) {
            [UIView animateWithDuration:0.3 animations:^{
                [_progressView setAlpha:0.];
            } completion:nil];
        }
    }
}

- (BOOL)isUrlString:(NSString *)result {
    return  [result hasPrefix:@"http://"] || [result hasPrefix:@"https://"];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



@end
