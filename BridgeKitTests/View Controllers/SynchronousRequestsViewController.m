//
//  SynchronousRequestsViewController.m
//  BridgeKit
//
//  Created by Angry Beast on 7/28/13.
//  Copyright (c) 2013 richardjrossiii. All rights reserved.
//

#import "SynchronousRequestsViewController.h"
#import "BridgeKit.h"

@interface SynchronousRequestsViewController ()<UIWebViewDelegate, BridgeKitDelegate, UITextFieldDelegate>

@property IBOutlet UIWebView *webView;
@property BridgeKit *bridgeKit;

@end

@implementation SynchronousRequestsViewController

- (void)viewDidLoad
{
    self.bridgeKit = [BridgeKit bridgeKitWithWebView:self.webView delegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"SynchronousRequests" withExtension:@"html"]]];
}

-(NSString *) getNewText {
    return @"I am the synchronously loaded new text!";
}

@end