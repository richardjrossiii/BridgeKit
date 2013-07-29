#import "EventHandlingViewController.h"
#import "BridgeKit.h"

@interface EventHandlingViewController ()<UIWebViewDelegate, BridgeKitDelegate, UITextFieldDelegate>

@property IBOutlet UIWebView *webView;
@property BridgeKit *bridgeKit;

@end

@implementation EventHandlingViewController

- (void)viewDidLoad
{
    self.bridgeKit = [BridgeKit bridgeKitWithWebView:self.webView delegate:self];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"EventHandling" withExtension:@"html"]]];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    [self.bridgeKit sendEvent:@"textFieldUpdated" withArguments:textField.text, nil];
    [textField resignFirstResponder];
    
    return NO;
}

@end