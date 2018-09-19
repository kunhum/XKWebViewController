//
//  XKWebViewController.h
//  kun
//
//  Created by Nicholas on 16/7/19.
//  Copyright © 2016年 Nicholas. All rights reserved.
//

#import <UIKit/UIKit.h>

#define XKWebViewControllerSBIdentifier @"xkwebviewcontroller"

@interface XKWebViewController : UIViewController

///网页
- (void)loadURL:(NSString *)urlString;
///网页
@property (strong, nonatomic) NSString *urlString;
///html
@property (strong, nonatomic) NSString *textHtmlString;

///进度条颜色
@property (nonatomic, strong) UIColor  *progressColor;

@property (nonatomic, assign) BOOL      hideNavigationBar;

@property (nonatomic, assign) BOOL      containScrollView;

///自动获取标题，默认NO
@property (nonatomic, assign) BOOL      autoSetTitle;
///标题label
@property (nonatomic, weak) UILabel    *titleLabel;

@end
