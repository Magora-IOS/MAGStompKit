//
//  MAGSTOMPSubscription.m
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import "MAGSTOMPSubscription.h"

#import "MAGStompConstants.h"
#import "MAGSTOMPClient.h"


@interface MAGSTOMPSubscription()

@property (nonatomic, retain) MAGSTOMPClient *client;

- (id)initWithClient:(MAGSTOMPClient *)theClient
          identifier:(NSString *)theIdentifier;

@end



@implementation MAGSTOMPSubscription

@synthesize client;
@synthesize identifier;

- (id)initWithClient:(MAGSTOMPClient *)theClient
          identifier:(NSString *)theIdentifier {
    if(self = [super init]) {
        self.client = theClient;
        identifier = [theIdentifier copy];
    }
    return self;
}

- (void)unsubscribe {
    [self.client sendFrameWithCommand:kCommandUnsubscribe
                              headers:@{kHeaderID: self.identifier}
                                 body:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MAGSTOMPSubscription identifier:%@>", identifier];
}

@end

