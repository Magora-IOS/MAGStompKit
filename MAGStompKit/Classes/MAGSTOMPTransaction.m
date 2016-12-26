//
//  MAGMAGSTOMPTransaction.m
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import "MAGSTOMPTransaction.h"
#import "MAGSTOMPClient.h"
#import "MAGStompConstants.h"

@interface MAGSTOMPTransaction()

@property (nonatomic, retain) MAGSTOMPClient *client;

- (id)initWithClient:(MAGSTOMPClient *)theClient
          identifier:(NSString *)theIdentifier;

@end



@implementation MAGSTOMPTransaction

@synthesize identifier;

- (id)initWithClient:(MAGSTOMPClient *)theClient
          identifier:(NSString *)theIdentifier {
    if(self = [super init]) {
        self.client = theClient;
        identifier = [theIdentifier copy];
    }
    return self;
}

- (void)commit {
    [self.client sendFrameWithCommand:kCommandCommit
                              headers:@{kHeaderTransaction: self.identifier}
                                 body:nil];
}

- (void)abort {
    [self.client sendFrameWithCommand:kCommandAbort
                              headers:@{kHeaderTransaction: self.identifier}
                                 body:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MAGSTOMPTransaction identifier:%@>", identifier];
}

@end
