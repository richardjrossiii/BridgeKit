//
//  NativeEventHandlingViewController.m
//  BridgeKit
//
//  Created by Angry Beast on 7/28/13.
//  Copyright (c) 2013 richardjrossiii. All rights reserved.
//

#import "NativeEventHandlingViewController.h"
#import "BridgeKit.h"

@interface NativeEventHandlingViewController ()<UIWebViewDelegate, BridgeKitDelegate, UITextFieldDelegate>

@property IBOutlet UIWebView *webView;
@property BridgeKit *bridgeKit;

@end

@implementation NativeEventHandlingViewController

- (void)viewDidLoad
{
    self.bridgeKit = [BridgeKit bridgeKitWithWebView:self.webView delegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"NativeEventHandling" withExtension:@"html"]]];
}

@end