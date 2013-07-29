//
//  AsynchronousRequestsViewController.m
//  BridgeKit
//
//  Created by Angry Beast on 7/28/13.
//  Copyright (c) 2013 richardjrossiii. All rights reserved.
//

#import "AsynchronousRequestsViewController.h"
#import "BridgeKit.h"

@interface AsynchronousRequestsViewController ()<UIWebViewDelegate, BridgeKitDelegate, UITextFieldDelegate>

@property IBOutlet UIWebView *webView;
@property BridgeKit *bridgeKit;

@end

@implementation AsynchronousRequestsViewController

- (void)viewDidLoad
{
    self.bridgeKit = [BridgeKit bridgeKitWithWebView:self.webView delegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"AsynchronousRequests" withExtension:@"html"]]];
}

-(void) getNewText:(BridgeKitCallback *) callback {
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [callback invokeWithArguments:@"I am the new text!", nil];
    });
}


@end