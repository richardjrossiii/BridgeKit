#import "BridgeKitRequest.h"
#import "BridgeKit.h"

#import <objc/runtime.h>

@interface BridgeKitRequest()

@property (readwrite, copy) NSString *name;
@property (readwrite, copy) NSArray *arguments;
@property (readwrite, strong) BridgeKitCallback *callback;

@end

@implementation BridgeKitRequest

+(id) requestWithName:(NSString *)name arguments:(NSArray *)arguments callback:(BridgeKitCallback *) callback {
    BridgeKitRequest *request = [BridgeKitRequest new];
    
    request.name = name;
    request.arguments = arguments;
    request.callback = callback;
    
    return request;
}

+(id) requestWithURL:(NSURL *)URL inContext:(BridgeKit *) context {
    // Here, we must parse this URL into a BridgeKit request.
    BridgeKitRequest *request = [BridgeKitRequest new];
    NSArray *hostComponents = [[URL host] pathComponents];
    
    if (hostComponents.count < 2)
        [NSException raise:NSInvalidArgumentException format:@"URL is not properly formed for a BridgeKit request!"];
    
    request.name = hostComponents[0];
        
    NSInteger callbackId = [hostComponents[1] integerValue];
    request.callback = [BridgeKitCallback __callbackWithIdentifier:callbackId inContext:context];
    
    NSMutableArray *arguments = [[URL pathComponents] mutableCopy];
    [arguments removeObjectAtIndex:0]; // this would be the leading '/'.
    
    for (int i = 0; i < arguments.count; i++) {
        NSData *data = [[arguments[i] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];

        // decode the JSON encoded arguments
        NSError *error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        
        if (result == nil) {
            NSLog(@"%@", error);
            continue;
        }
        
        arguments[i] = result;
    }
    
    request.arguments = [arguments copy];
    
    return request;
}

-(NSInvocation *) possibleInvocationWithTarget:(id)target {
    // The first step is to see if a method exists such that:
    //   - It has the same number of arguments that we do
    //   - Starts with the same name
    Method match = nil;
    Class class = [target class];
    
    // We must traverse superclasses, as class_copyMethodList doesn't include superclasses.
    while (class_getSuperclass(class) != nil) {
        unsigned methodCount;
        Method *methods = class_copyMethodList(class, &methodCount);
        
        for (int i = 0; i < methodCount; i++) {
            // Check the number of arguments. Subtract 2 for self and _cmd,
            // but add one to the arguments count for the extra 'callback' parameter
            if ((method_getNumberOfArguments(methods[i]) - 2) != (self.arguments.count + 1))
                continue;
            
            NSString *methodName = @(sel_getName(method_getName(methods[i])));
            if ([methodName hasPrefix:self.name]) {
                match = methods[i];
                break;
            }
        }
        
        free(methods);
        
        if (match)
            break;
        
        class = class_getSuperclass(class);
    }
    
    if (match == nil)
        return nil;
    
    // Once we have our match, construct an invocation that will seamlessly pass our arguments to the target.
    NSMethodSignature *methodSignature = [target methodSignatureForSelector:method_getName(match)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    [invocation setTarget:target];
    [invocation setSelector:method_getName(match)];
    
    unsigned argumentIndex = 2;
    for (__unsafe_unretained id argument in self.arguments) {
        [invocation setArgument:&argument atIndex:argumentIndex++];
    }
    
    [invocation setArgument:&_callback atIndex:argumentIndex];
    
    return invocation;
}

@end
