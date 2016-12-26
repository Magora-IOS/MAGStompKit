//
//  MAGSTOMPMessage.m
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import "MAGSTOMPMessage.h"
#import "MAGStompConstants.h"
#import "MAGSTOMPClient.h"

@interface MAGSTOMPMessage()

@property (nonatomic, retain) MAGSTOMPClient *client;

+ (MAGSTOMPMessage *)MAGSTOMPMessageFromFrame:(MAGSTOMPFrame *)frame
                                 client:(MAGSTOMPClient *)client;

@end



@implementation MAGSTOMPMessage

@synthesize client;

- (id)initWithClient:(MAGSTOMPClient *)theClient
             headers:(NSDictionary *)theHeaders
                body:(NSString *)theBody {
    if (self = [super initWithCommand:kCommandMessage
                              headers:theHeaders
                                 body:theBody]) {
        self.client = theClient;
    }
    return self;
}

- (void)ack {
    [self ackWithCommand:kCommandAck headers:nil];
}

- (void)ack: (NSDictionary *)theHeaders {
    [self ackWithCommand:kCommandAck headers:theHeaders];
}

- (void)nack {
    [self ackWithCommand:kCommandNack headers:nil];
}

- (void)nack: (NSDictionary *)theHeaders {
    [self ackWithCommand:kCommandNack headers:theHeaders];
}

- (void)ackWithCommand: (NSString *)command
               headers: (NSDictionary *)theHeaders {
    NSMutableDictionary *ackHeaders = [[NSMutableDictionary alloc] initWithDictionary:theHeaders];
    ackHeaders[kHeaderID] = self.headers[kHeaderAck];
    [self.client sendFrameWithCommand:command
                              headers:ackHeaders
                                 body:nil];
}

+ (MAGSTOMPMessage *)MAGSTOMPMessageFromFrame:(MAGSTOMPFrame *)frame
                                 client:(MAGSTOMPClient *)client {
    return [[MAGSTOMPMessage alloc] initWithClient:client headers:frame.headers body:frame.body];
}

@end
