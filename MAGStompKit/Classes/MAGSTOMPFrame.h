//
//  MAGSTOMPFrame.h
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import <Foundation/Foundation.h>


@interface MAGSTOMPFrame : NSObject

@property (nonatomic, copy, readonly) NSString *command;
@property (nonatomic, copy, readonly) NSDictionary *headers;
@property (nonatomic, copy, readonly) NSString *body;

- (id)initWithCommand:(NSString *)theCommand
              headers:(NSDictionary *)theHeaders
                 body:(NSString *)theBody;

- (NSString *)toString;
+ (MAGSTOMPFrame *)MAGSTOMPFrameFromDataString:(NSString *)msg;

@end
