#import <Foundation/Foundation.h>

@class BridgeKit;

@interface BridgeKitCallback : NSObject

+(instancetype) __callbackWithIdentifier:(NSInteger) callbackId inContext:(BridgeKit *) context;

-(void) invoke;
-(void) invokeWithArguments:(id) args, ... NS_REQUIRES_NIL_TERMINATION;
-(void) invokeWithArgumentsArray:(NSArray *) arguments;

@end
