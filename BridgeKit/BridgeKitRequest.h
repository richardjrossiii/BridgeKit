#import <Foundation/Foundation.h>

@class BridgeKit;
@class BridgeKitCallback;

@interface BridgeKitRequest : NSObject

+(instancetype) requestWithName:(NSString *) name arguments:(NSArray *) arguments callback:(BridgeKitCallback *) callback;
+(instancetype) requestWithURL:(NSURL *) URL inContext:(BridgeKit *) context;

@property (readonly, copy)                      NSString *name;
@property (readonly, copy)                      NSArray *arguments;
@property (readonly, strong)                    BridgeKitCallback *callback;

// Constructs an invocation (or returns null if one is not valid),
// Which satisfies the name and argument count passed to this request
-(NSInvocation *) possibleInvocationWithTarget:(id) target;

@end
