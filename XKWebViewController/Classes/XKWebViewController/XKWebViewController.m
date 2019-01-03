//
//  XKWebViewController.m
//  kun
//
//  Created by Nicholas on 16/7/19.
//  Copyright © 2016年 Nicholas. All rights reserved.
//

#import "XKWebViewController.h"
#import <WebKit/WebKit.h>
#import "Masonry.h"

#define XK_RATIO (XK_SCREEN_WIDTH/375.0)
#define XK_SCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define XK_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define XK_STATUS_BAR_AND_NAVIGATION_BAR_HEIGHT (XK_IS_IHPONEX ? 88.f : 64.f)
#define XK_IS_IHPONEX (XK_SCREEN_WIDTH == 375.f && XK_SCREEN_HEIGHT == 812.f ? YES : NO)

@interface XKWebViewController () <WKNavigationDelegate>

@property (strong, nonatomic) WKWebView *webView;

@property (strong, nonatomic) UIProgressView *progressView;

@end

@implementation XKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    [self.view addSubview:self.progressView];
    
    if (self.autoSetTitle == NO) {
        UILabel *titleLabel  = [UILabel new];
        titleLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
        titleLabel.font      = [UIFont systemFontOfSize:16*XK_RATIO];
        titleLabel.text      = self.title;
        [titleLabel sizeToFit];
        self.navigationItem.titleView = titleLabel;
        self.titleLabel = titleLabel;
    }
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    
    if (self.progressColor) {
        self.progressView.progressTintColor = self.progressColor;
    }
    
    //添加观察者
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    if (self.autoSetTitle) [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.top.mas_equalTo(XK_STATUS_BAR_AND_NAVIGATION_BAR_HEIGHT);
    }];
    
    self.containScrollView = YES;
}
#pragma mark - view will appear

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:self.hideNavigationBar animated:YES];
    
    if (self.hideNavigationBar) {
        
        self.progressView.frame = CGRectMake(0, 0, self.progressView.frame.size.width, self.progressView.frame.size.height);
    }
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect frame            = self.progressView.frame;
    frame.size.width        = CGRectGetWidth(self.view.bounds);;
    self.progressView.frame = frame;
    if (self.containScrollView) {
        [self.webView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.view).with.mas_offset(64.0);
        }];
    }
}

#pragma mark - 加载网页
#pragma mark 通过方法

- (void)loadURL:(NSString *)urlString {
    
    if (urlString && urlString.length > 0) {
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        
        [self.webView loadRequest:request];
        
    }
}

#pragma mark 通过属性

- (void)setUrlString:(NSString *)urlString {
    
    _urlString = urlString;
    
    if ([_urlString isKindOfClass:[NSNull class]] == NO && _urlString && _urlString.length > 0) {
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_urlString]];
        
        [self.webView loadRequest:request];
        
    }
    
}

- (void)setTextHtmlString:(NSString *)textHtmlString {
    
    _textHtmlString = textHtmlString;
    
    if ([_textHtmlString isKindOfClass:[NSNull class]] == NO && _textHtmlString && _textHtmlString.length > 0) {
        
        NSString *headerString = @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>";
        NSString *str = [NSString stringWithFormat:@"<head><style>img{max-width:%fpx;height:auto !important;}</style></head>",XK_SCREEN_WIDTH-20];
        str = [headerString stringByAppendingString:str];
        NSString *htmlString = [str stringByAppendingString:_textHtmlString];
        [self.webView loadHTMLString:htmlString baseURL:nil];
        
    }
}

#pragma mark - 观察者 观察加载进度与标题

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if (object == self.webView) {
        
        if ([keyPath isEqualToString:@"estimatedProgress"]) {
            
            CGFloat progress = [[change valueForKey:@"new"] floatValue];
            
            [self.progressView setProgress:progress animated:YES];
            
            if (progress == 1.000000) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    self.progressView.hidden = YES;
                });
                
            }
            
        }
        if ([keyPath isEqualToString:@"title"]) {
            
            NSString *urlTitle = [change valueForKey:@"new"];
            
            self.title = urlTitle;
            
//            self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:17],NSForegroundColorAttributeName:[UIColor blackColor]};
        }
    }
    
}

#pragma mark -- web view delegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    if (([navigationAction.request.URL.scheme isEqualToString:@"http"] || [navigationAction.request.URL.scheme isEqualToString:@"https"]) && navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    //判断是否跳转一个新页面
    else if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    else decisionHandler(WKNavigationActionPolicyAllow);
    
}

- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    
    self.progressView.progressTintColor = progressColor;
}

#pragma mark - 懒加载
#pragma mark web view

- (WKWebView *)webView {
    
    if (!_webView) {
        
        WKWebViewConfiguration *config = [WKWebViewConfiguration new];
        //偏好设置
        config.preferences = [WKPreferences new];
        //最小字体
        config.preferences.minimumFontSize = 14;
        config.preferences.javaScriptEnabled = YES;
        //不通过交互是否可以打开窗口
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        
        //自适应js代码
        NSString *js = @"var count = document.images.length;for (var i = 0; i < count; i++) {var image = document.images[i];image.style.width=320;};";
        //根据JS字符串初始化WKUserScript对象
        WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        [config.userContentController addUserScript:script];
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.navigationDelegate = self;
        
    }
    return _webView;
}

#pragma mark progress view

- (UIProgressView *)progressView {
    
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, 0, 1)];
        
        _progressView.progressTintColor = [UIColor colorWithRed:83/255.0 green:202/255.0 blue:195/255.0 alpha:1.0];
    }
    return _progressView;
}

#pragma mark - 释放

- (void)dealloc {
    
    [_webView removeObserver:self forKeyPath:@"estimatedProgress"];
    if (_autoSetTitle) [_webView removeObserver:self forKeyPath:@"title"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
