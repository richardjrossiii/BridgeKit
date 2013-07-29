#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "BridgeKitCallback.h"
#import "BridgeKitDelegate.h"
#import "BridgeKitRequest.h"
#import "BridgeKitDelegateRequest.h"

@interface BridgeKit : NSObject

@property UIWebView *webView;

+(BridgeKit *) bridgeKitWithWebView:(UIWebView *) webView delegate:(id<BridgeKitDelegate>) delegate;
-(void) setURLScheme:(NSString *) newScheme;

-(void) sendEvent:(NSString *) eventName;
-(void) sendEvent:(NSString *) eventName withArguments:(id) args, ... NS_REQUIRES_NIL_TERMINATION;
-(void) sendEvent:(NSString *) eventName withArgumentsArray:(NSArray *) arguments;

@end