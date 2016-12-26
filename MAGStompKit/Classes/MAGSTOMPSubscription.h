//
//  MAGSTOMPSubscription.h
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import <Foundation/Foundation.h>

@class MAGSTOMPClient;

@interface MAGSTOMPSubscription : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;

- (id)initWithClient:(MAGSTOMPClient *)theClient
          identifier:(NSString *)theIdentifier;
- (void)unsubscribe;

@end
