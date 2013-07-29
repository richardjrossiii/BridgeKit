#import "BridgeKitCallback.h"
#import "BridgeKit.h"

@implementation BridgeKitCallback {
    BridgeKit *_context;
    NSInteger  _callbackId;
}

-(id) initWithIdentifier:(NSInteger) callbackId inContext:(BridgeKit *) context {
    if (self = [super init]) {
        _context = context;
        _callbackId = callbackId;
    }
    
    return self;
}

+(instancetype) __callbackWithIdentifier:(NSInteger) callbackId inContext:(BridgeKit *) context {
    return [[self alloc] initWithIdentifier:callbackId inContext:context];
}

-(void) invoke {
    [self invokeWithArgumentsArray:nil];
}

-(void) invokeWithArguments:(id)args, ... {
    va_list list;
    va_start(list, args);
    
    id obj = args;
    NSMutableArray *arguments = [NSMutableArray array];
    
    while (obj) {
        [arguments addObject:obj];
        obj = va_arg(list, id);
    }
    
    va_end(list);
    
    [self invokeWithArgumentsArray:arguments];
}

-(void) invokeWithArgumentsArray:(NSArray *) arguments {
    // convert the arguments to a JSON string
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arguments options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSString *javaScriptString = [NSString stringWithFormat:@"window.BridgeKit.callbacks[%i].apply(null, %@);", _callbackId, jsonString];
    [[_context webView] stringByEvaluatingJavaScriptFromString:javaScriptString];
}

@end
