//
//  MAGSTOMPMessage.h
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import <Foundation/Foundation.h>

#import "MAGSTOMPFrame.h"

@class MAGSTOMPClient;

@interface MAGSTOMPMessage : MAGSTOMPFrame

- (void)ack;
- (void)ack:(NSDictionary *)theHeaders;
- (void)nack;
- (void)nack:(NSDictionary *)theHeaders;

+ (MAGSTOMPMessage *)MAGSTOMPMessageFromFrame:(MAGSTOMPFrame *)frame
                                 client:(MAGSTOMPClient *)client;

@end
