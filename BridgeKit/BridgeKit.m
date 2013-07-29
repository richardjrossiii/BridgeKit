#import "BridgeKit.h"
#import "BridgeKit.js"

@interface BridgeKit()<UIWebViewDelegate> {
    // A mapping of string -> mutable array of callbacks
    NSMutableDictionary    *_callbacks;
    NSMutableDictionary    *_nativeCallbacks;
    
    UIWebView              *_webView;
    id<BridgeKitDelegate>   _delegate;
    
    NSString               *_urlScheme;
}

@end

@implementation BridgeKit

-(id) initWithWebView:(UIWebView *) webView delegate:(id<BridgeKitDelegate>) delegate {
    if (self = [super init]) {
        _callbacks = [NSMutableDictionary dictionary];
        _nativeCallbacks = [NSMutableDictionary dictionary];
        
        _webView = webView;
        _delegate = delegate;
        
        _urlScheme = @"bk";
        
        _webView.delegate = self;
    }
    
    return self;
}

+(BridgeKit *) bridgeKitWithWebView:(UIWebView *)webView delegate:(id<BridgeKitDelegate>)delegate {
    return [[self alloc] initWithWebView:webView delegate:delegate];
}

#pragma mark - Event Registering

// These methods are invoked dynamically through our JavaScript engine.
-(void) registerEvent:(NSString *) event callback:(BridgeKitCallback *) callback {    
    if ([_delegate respondsToSelector:@selector(bridgeKit:shouldRegisterCallback:forEvent:)]) {
        if (![_delegate bridgeKit:self shouldRegisterCallback:callback forEvent:event]) {
            return;
        }
    }
    
    if ([_delegate respondsToSelector:@selector(bridgeKit:willRegisterCallback:forEvent:)])
        [_delegate bridgeKit:self willRegisterCallback:callback forEvent:event];
    
    // now, actually register the event
    if (_callbacks[event] == nil)
        _callbacks[event] = [NSMutableArray array];
    
    [_callbacks[event] addObject:callback];
    
    // Notify our delegate that something changed
    if ([_delegate respondsToSelector:@selector(bridgeKit:didRegisterCallback:forEvent:)])
        [_delegate bridgeKit:self didRegisterCallback:callback forEvent:event];
}

-(void) registerNativeEvent:(NSString *) event callback:(BridgeKitCallback *) callback {
    if ([_delegate respondsToSelector:@selector(bridgeKit:shouldRegisterNativeCallback:forEvent:)]) {
        if ([_delegate bridgeKit:self shouldRegisterNativeCallback:callback forEvent:event]) {
            return;
        }
    }
    
    if ([_delegate respondsToSelector:@selector(bridgeKit:willRegisterNativeCallback:forEvent:)])
        [_delegate bridgeKit:self willRegisterNativeCallback:callback forEvent:event];
    
    if (_nativeCallbacks[event] == nil) {
        _nativeCallbacks[event] = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(__bridgeKit_nativeCallbackHandler:) name:event object:nil];
    }
    
    [_nativeCallbacks[event] addObject:callback];
    
    if ([_delegate respondsToSelector:@selector(bridgeKit:didRegisterNativeCallback:forEvent:)])
        [_delegate bridgeKit:self didRegisterNativeCallback:callback forEvent:event];
}

#pragma mark - Event Sending

-(void) sendEvent:(NSString *)eventName {
    [self sendEvent:eventName withArgumentsArray:nil];
}

-(void) sendEvent:(NSString *)eventName withArguments:(id)args, ... {
    va_list list;
    va_start(list, args);
    
    id obj = args;
    NSMutableArray *arguments = [NSMutableArray array];
    
    while (obj) {
        [arguments addObject:obj];
        obj = va_arg(list, id);
    }
    
    va_end(list);
    
    [self sendEvent:eventName withArgumentsArray:arguments];
}

-(void) sendEvent:(NSString *)eventName withArgumentsArray:(NSArray *)arguments {
    for (BridgeKitCallback *callback in _callbacks[eventName]) {
        [callback invokeWithArgumentsArray:arguments];
    }
}

#pragma mark - Request Handling 

-(void) handleBridgeKitRequest:(BridgeKitRequest *) request {
    // create an invocation from the request
    NSInvocation *invocation = [request possibleInvocationWithTarget:self];
    [invocation invoke];
    
    if (invocation == nil) {
        if ([_delegate respondsToSelector:@selector(bridgeKit:couldNotHandleRequest:reason:)])
        {
            [_delegate bridgeKit:self
           couldNotHandleRequest:request
                          reason:[NSError errorWithDomain:@"BridgeKitErrorDomain"
                                                     code:0
                                                 userInfo:@{
                                    NSLocalizedDescriptionKey: @"Request send did not match any internal invocation."
                                  }]];
        }
    }
}

-(void) request:(NSString *) requestName parameters:(NSArray *) params callback:(BridgeKitCallback *) callback {
    // Nothing to do if we don't have a delegate
    if (_delegate == nil)
        return;
    
    BridgeKitDelegateRequest *delegateRequest = [BridgeKitDelegateRequest delegateRequestWithName:requestName arguments:params callback:callback];
    
    BOOL transient = NO;
    NSInvocation *invocation = [delegateRequest possibleInvocationWithTarget:_delegate hasTransientCallback:&transient];
    
    SEL targetCMD = NULL;
    [invocation getArgument:&targetCMD atIndex:1];
    
    if ([_delegate respondsToSelector:targetCMD]) {
        [invocation invokeWithTarget:_delegate];
    } else if ([_delegate respondsToSelector:@selector(bridgeKit:forwardRequestInvocation:)]) {
        [_delegate bridgeKit:self forwardRequestInvocation:invocation];
    }
    
    if (!transient) {
        // get the return type and pass it back to JS
        id returnValue = nil;
        [invocation getReturnValue:&returnValue];
        
        [callback invokeWithArguments:returnValue, nil];
    }
}

#pragma mark - UIWebViewDelegate

-(BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    // this is important that we only capture the correct urls here!
    if (navigationType == UIWebViewNavigationTypeOther && [request.URL.scheme isEqualToString:_urlScheme]) {
        [self handleBridgeKitRequest:[BridgeKitRequest requestWithURL:request.URL inContext:self]];
        
        return NO;
    }
    
    if ([_delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
        return [_delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    
    return YES;
}

-(void) webViewDidStartLoad:(UIWebView *)webView {
    [webView stringByEvaluatingJavaScriptFromString:__BridgeKit_JS_String];
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"BridgeKit.setUrlScheme(\"%@\");", _urlScheme]];
    
    if ([_delegate respondsToSelector:@selector(webViewDidStartLoad:)])
        [_delegate webViewDidStartLoad:webView];
}

#pragma mark - NSNotificationCenter Handling

-(void) __bridgeKit_nativeCallbackHandler:(NSNotification *) notification {
    for (BridgeKitCallback *callback in _nativeCallbacks[notification.name]) {
        [callback invokeWithArguments:notification.userInfo, nil];
    }
}

#pragma mark - URL scheme handling

-(void) setURLScheme:(NSString *)newScheme {
    _urlScheme = newScheme;
    [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"BridgeKit.setUrlScheme(\"%@\");", _urlScheme]];
}

@end
