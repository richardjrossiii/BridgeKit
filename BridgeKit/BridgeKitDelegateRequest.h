//
//  BridgeKitDelegateRequest.h
//  BridgeKit
//
//  Created by Angry Beast on 7/28/13.
//  Copyright (c) 2013 richardjrossiii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BridgeKitRequest.h"

@interface BridgeKitDelegateRequest : NSObject 

+(instancetype) delegateRequestWithName:(NSString *)name arguments:(NSArray *)arguments callback:(BridgeKitCallback *)callback;
-(NSInvocation *) possibleInvocationWithTarget:(id)target hasTransientCallback:(BOOL *) transientCallback;

@end