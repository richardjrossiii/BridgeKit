//
//  BridgeKitDelegateRequest.m
//  BridgeKit
//
//  Created by Angry Beast on 7/28/13.
//  Copyright (c) 2013 richardjrossiii. All rights reserved.
//

#import "BridgeKitDelegateRequest.h"
#import <objc/runtime.h>

@interface BridgeKitDelegateRequest()

@property (readwrite, copy) NSString *name;
@property (readwrite, getter = isSynchronous) BOOL synchronous;
@property (readwrite, copy) NSArray *arguments;
@property (readwrite, strong) BridgeKitCallback *callback;

@end

@implementation BridgeKitDelegateRequest

+(id) delegateRequestWithName:(NSString *)name arguments:(NSArray *)arguments callback:(BridgeKitCallback *)callback {
    BridgeKitDelegateRequest *delegateRequest = [self new];
    
    if ([name hasPrefix:@"synchronous/"]) {
        name = [name stringByReplacingOccurrencesOfString:@"synchronous/" withString:@""];
        delegateRequest.synchronous = YES;
    }
    
    delegateRequest.name = name;
    delegateRequest.arguments = arguments;
    delegateRequest.callback = callback;
    
    return delegateRequest;
}

-(NSInvocation *) possibleInvocationWithTarget:(id)target hasTransientCallback:(BOOL *) pTransientCallback {
    // now that we are delegating to a target, we have much more to consider than just
    // arg count and name. We're now considering the following:
    //  - argument counts
    //  - method names
    //  - return type
    //  - last argument being the 'callback' parameter, but only if the return type is 'void'    
    SEL match = NULL;
    Class class = [target class];
    BOOL transientCallback;
    
    // We must traverse superclasses, as class_copyMethodList doesn't include superclasses.
    while (class_getSuperclass(class) != nil) {
        unsigned methodCount;
        Method *methods = class_copyMethodList(class, &methodCount);
        
        for (int i = 0; i < methodCount; i++) {
            int argumentCount = method_getNumberOfArguments(methods[i]) - 2;
            transientCallback = argumentCount == (self.arguments.count + 1);
            
            NSString *methodName = @(sel_getName(method_getName(methods[i])));
            
            char returnType;
            char lastArgumentType;
            
            // get the return type to ensure we're getting an object
            method_getReturnType(methods[i], &returnType, 1);
            
            // add one to the argument count, as we already subtracted 2 for self and _cmd.
            method_getArgumentType(methods[i], argumentCount + 1, &lastArgumentType, 1);
            
            if (!(argumentCount == self.arguments.count ||
                  argumentCount == self.arguments.count + 1))
                continue;
            
            // if the method has a return type, and we're already passing
            // the callback transiently, this isn't a valid candidate.
            if (returnType == '@' && transientCallback) {
                continue;
            }
            
            // if we're passing the callback transiently, but the last argument isn't an
            // object, this method won't work.
            if (transientCallback && (lastArgumentType != '@'))
                continue;
            
            // finally, the ultimate test - does the name match?
            if ([methodName hasPrefix:self.name]) {
                match = method_getName(methods[i]);
                break;
            }
        }
        
        free(methods);
        
        if (match)
            break;
        
        class = class_getSuperclass(class);
    }
    
    if (match == nil) {
        // create a method
        match = sel_registerName([self.name UTF8String]);
        return nil;
    }
    
    // Once we have our match, construct an invocation that will seamlessly pass our arguments to the target.
    NSMethodSignature *methodSignature = [target methodSignatureForSelector:match];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    [invocation setTarget:target];
    [invocation setSelector:match];
    
    unsigned argumentIndex = 2;
    for (__unsafe_unretained id argument in self.arguments) {
        [invocation setArgument:&argument atIndex:argumentIndex++];
    }
    
    if (transientCallback)
        [invocation setArgument:&_callback atIndex:argumentIndex];
    
    if (pTransientCallback)
        *pTransientCallback = transientCallback;
    
    return invocation;
}


@end
