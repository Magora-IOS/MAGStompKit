//
//  MAGMAGSTOMPClient.h
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>
#import "MAGSTOMPFrame.h"
#import "MAGSTOMPSubscription.h"
#import "MAGSTOMPTransaction.h"


@class MAGSTOMPFrame;
@class MAGSTOMPMessage;

typedef void (^MAGSTOMPFrameHandler)(MAGSTOMPFrame *frame);
typedef void (^MAGSTOMPMessageHandler)(MAGSTOMPMessage *message);



typedef void (^VoidBlock)();
typedef void (^IntAndStringBlock)(NSInteger code, NSString *reason);
typedef void (^NSErrorBlock)(NSError *error);

@interface MAGSTOMPClient : NSObject < SRWebSocketDelegate >

@property (nonatomic, copy) VoidBlock webSocketDidOpen;
@property (nonatomic, copy) MAGSTOMPFrameHandler didConnectBySTOMP;
@property (nonatomic, copy) IntAndStringBlock webSocketDidCloseWithCodeAndReason;
@property (nonatomic, copy) NSErrorBlock didFailWithError;

@property (nonatomic, copy) MAGSTOMPFrameHandler receiptHandler;
@property (nonatomic, copy) void (^errorHandler)(NSError *error);

@property (nonatomic, assign) BOOL connected;


- (id)initWithHost:(NSString *)theHost;

- (void)connectWithCompletionHandler:(MAGSTOMPFrameHandler)completionHandler;

- (void)connectWithLogin:(NSString *)login
                passcode:(NSString *)passcode
       completionHandler:(MAGSTOMPFrameHandler)completionHandler;

- (void)connectWithAuthorizationToken:(NSString *)token
                    completionHandler:(MAGSTOMPFrameHandler)completionHandler;

- (void)connectWithHeaders:(NSDictionary *)headers
         completionHandler:(MAGSTOMPFrameHandler)completionHandler;

- (void)sendTo:(NSString *)destination
          body:(NSString *)body;

- (void)sendTo:(NSString *)destination
       headers:(NSDictionary *)headers
          body:(NSString *)body;

- (MAGSTOMPSubscription *)subscribeTo:(NSString *)destination
                    messageHandler:(MAGSTOMPMessageHandler)handler;

- (MAGSTOMPSubscription *)subscribeTo:(NSString *)destination
                           headers:(NSDictionary *)headers
                    messageHandler:(MAGSTOMPMessageHandler)handler;

- (MAGSTOMPTransaction *)begin;
- (MAGSTOMPTransaction *)begin:(NSString *)identifier;

- (void)sendFrameWithCommand:(NSString *)command headers:(NSDictionary *)headers body:(NSString *)body;

- (void)disconnect;
- (void)disconnect:(void (^)(NSError *error))completionHandler;

@end
