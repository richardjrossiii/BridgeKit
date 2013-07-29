#import <Foundation/Foundation.h>

@class BridgeKit;
@class BridgeKitCallback;
@class BridgeKitRequest;

@protocol BridgeKitDelegate <NSObject, UIWebViewDelegate>
@optional

// These methods allow you to know and to verify that it is your code on the JS side that is attaching to events.
// You may wish to deny callback adding if the page being loaded is yours.
-(BOOL) bridgeKit:(BridgeKit *) bridgeKit shouldRegisterCallback:(BridgeKitCallback *) callback forEvent:(NSString *) eventName;
-(void) bridgeKit:(BridgeKit *) bridgeKit   willRegisterCallback:(BridgeKitCallback *) callback forEvent:(NSString *) eventName;
-(void) bridgeKit:(BridgeKit *) bridgeKit    didRegisterCallback:(BridgeKitCallback *) callback forEvent:(NSString *) eventName;

// It is VERY important that you do NOT allow unknown code to add a native callback.
// This is mostly done by checking the URL of the webview currently being loaded.
// Native callbacks are hooks into NSNotificationCenter, which then let you talk with
// Native events. Powerful, but dangerous
-(BOOL) bridgeKit:(BridgeKit *) bridgeKit shouldRegisterNativeCallback:(BridgeKitCallback *) callback forEvent:(NSString *) eventName;
-(void) bridgeKit:(BridgeKit *) bridgeKit   willRegisterNativeCallback:(BridgeKitCallback *) callback forEvent:(NSString *) eventName;
-(void) bridgeKit:(BridgeKit *) bridgeKit    didRegisterNativeCallback:(BridgeKitCallback *) callback forEvent:(NSString *) eventName;

// It is not as important to handle this group of methods.
// It's only useful for dynamic invocation purposes, which we already do, if possible.
-(BOOL) bridgeKit:(BridgeKit *) bridgeKit shouldHandleRequest:(BridgeKitRequest *) request;
-(void) bridgeKit:(BridgeKit *) bridgeKit   willHandleRequest:(BridgeKitRequest *) request;
-(void) bridgeKit:(BridgeKit *) bridgeKit    didHandleRequest:(BridgeKitRequest *) request;

// These are used for error handling, and for dynamically handling requests.
-(void) bridgeKit:(BridgeKit *) bridgeKit couldNotHandleRequest:(BridgeKitRequest *) request reason:(NSError *) error;
-(void) bridgeKit:(BridgeKit *) bridgeKit forwardRequestInvocation:(NSInvocation *) invocation;

@end
