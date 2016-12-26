//
//  MAGSTOMPFrame.m
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import "MAGSTOMPFrame.h"
#import "MAGStompConstants.h"



#pragma mark STOMP Frame

@interface MAGSTOMPFrame()

- (id)initWithCommand:(NSString *)theCommand
              headers:(NSDictionary *)theHeaders
                 body:(NSString *)theBody;

- (NSData *)toData;
- (NSString *)toString;

@end

@implementation MAGSTOMPFrame

@synthesize command, headers, body;

- (id)initWithCommand:(NSString *)theCommand
              headers:(NSDictionary *)theHeaders
                 body:(NSString *)theBody {
    if(self = [super init]) {
        command = theCommand;
        headers = theHeaders;
        body = theBody;
    }
    return self;
}

- (NSString *)toString {
    NSMutableString *frame = [NSMutableString stringWithString: [self.command stringByAppendingString:kLineFeed]];
    for (id key in self.headers) {
        [frame appendString:[NSString stringWithFormat:@"%@%@%@%@", key, kHeaderSeparator, self.headers[key], kLineFeed]];
    }
    [frame appendString:kLineFeed];
    if (self.body) {
        [frame appendString:self.body];
    }
    [frame appendString:kNullChar];
    return frame;
}

- (NSData *)toData {
    return [[self toString] dataUsingEncoding:NSUTF8StringEncoding];
}

+ (MAGSTOMPFrame *) MAGSTOMPFrameFromDataString:(NSString *)msg {
    LogDebug(@"<<< %@", msg);
    NSMutableArray *contents = (NSMutableArray *)[[msg componentsSeparatedByString:kLineFeed] mutableCopy];
    while ([contents count] > 0 && [contents[0] isEqual:@""]) {
        [contents removeObjectAtIndex:0];
    }
    
    NSString *command = [[contents objectAtIndex:0] copy];
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    NSMutableString *body = [[NSMutableString alloc] init];
    BOOL hasHeaders = NO;
    [contents removeObjectAtIndex:0];
    for(NSString *line in contents) {
        if(hasHeaders) {
            for (int i=0; i < [line length]; i++) {
                unichar c = [line characterAtIndex:i];
                if (c != '\x00') {
                    [body appendString:[NSString stringWithFormat:@"%c", c]];
                }
            }
        } else {
            if ([line isEqual:@""]) {
                hasHeaders = YES;
            } else {
                NSMutableArray *parts = [NSMutableArray arrayWithArray:[line componentsSeparatedByString:kHeaderSeparator]];
                // key ist the first part
                NSString *key = parts[0];
                [parts removeObjectAtIndex:0];
                headers[key] = [parts componentsJoinedByString:kHeaderSeparator];
            }
        }
    }
    
    
    return [[MAGSTOMPFrame alloc] initWithCommand:command headers:headers body:body];
}

- (NSString *)description {
    return [self toString];
}


@end
