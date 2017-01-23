//
//  MAGMAGSTOMPClient.m
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import "MAGSTOMPClient.h"

#import <SocketRocket/SRWebSocket.h>
#import "MAGStompConstants.h"
#import "MAGSTOMPSubscription.h"
#import "MAGSTOMPMessage.h"

@interface MAGSTOMPClient()

@property (nonatomic, retain) SRWebSocket *socket;
@property (nonatomic, copy) NSString *host;
@property (nonatomic) NSUInteger port;
@property (nonatomic) NSString *clientHeartBeat;
@property (nonatomic, weak) NSTimer *pinger;
@property (nonatomic, weak) NSTimer *ponger;

@property (nonatomic, retain) NSMutableDictionary *subscriptions;
@property (nonatomic, strong) NSMutableDictionary *connectHeaders;

- (void) sendFrameWithCommand:(NSString *)command
                      headers:(NSDictionary *)headers
                         body:(NSString *)body;

@end



@implementation MAGSTOMPClient

@synthesize socket, host, port;
@synthesize receiptHandler, errorHandler;
@synthesize subscriptions;
@synthesize connectHeaders;
@synthesize pinger, ponger;

int idGenerator;
CFAbsoluteTime serverActivity;

#pragma mark -
#pragma mark Public API

- (id)initWithHost:(NSString *)aHost {
    if(self = [super init]) {
        self.socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:aHost]];
        self.socket.delegate = self;
        
        
        self.host = aHost;
        idGenerator = 0;
        self.connected = NO;
        self.subscriptions = [[NSMutableDictionary alloc] init];
        self.clientHeartBeat = @"10000,10000";
    }
    return self;
}

- (void)connectWithCompletionHandler:(MAGSTOMPFrameHandler)completionHandler {
    [self connectWithHeaders:nil completionHandler:completionHandler];
}

- (void)connectWithLogin:(NSString *)login
                passcode:(NSString *)passcode
       completionHandler:(MAGSTOMPFrameHandler)completionHandler {
    [self connectWithHeaders:@{kHeaderLogin: login, kHeaderPasscode: passcode}
           completionHandler:completionHandler];
}

- (void)connectWithAuthorizationToken:(NSString *)token
                    completionHandler:(MAGSTOMPFrameHandler)completionHandler {
    [self connectWithHeaders:@{kHeaderAuthorization: token }
           completionHandler:completionHandler];
}

- (void)connectWithHeaders:(NSDictionary *)headers
         completionHandler:(MAGSTOMPFrameHandler)completionHandler {
    
    self.didConnectBySTOMP = completionHandler;
    // build connection headers
    if (headers != nil) {
        self.connectHeaders = [[NSMutableDictionary alloc] initWithDictionary:headers];
    }
    else {
        self.connectHeaders = [[NSMutableDictionary alloc] init];
    }
    
    [self.socket open];
}

- (void)sendTo:(NSString *)destination
          body:(NSString *)body {
    [self sendTo:destination
         headers:nil
            body:body];
}

- (void)sendTo:(NSString *)destination
       headers:(NSDictionary *)headers
          body:(NSString *)body {
    NSMutableDictionary *msgHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
    msgHeaders[kHeaderDestination] = destination;
    if (body) {
        NSUInteger length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        msgHeaders[kHeaderContentLength] = [NSNumber numberWithLong:length];
    }
    [self sendFrameWithCommand:kCommandSend
                       headers:msgHeaders
                          body:body];
}

- (MAGSTOMPSubscription *)subscribeTo:(NSString *)destination
                    messageHandler:(MAGSTOMPMessageHandler)handler {
    return [self subscribeTo:destination
                     headers:nil
              messageHandler:handler];
}

- (MAGSTOMPSubscription *)subscribeTo:(NSString *)destination
                           headers:(NSDictionary *)headers
                    messageHandler:(MAGSTOMPMessageHandler)handler {
    NSMutableDictionary *subHeaders = [[NSMutableDictionary alloc] initWithDictionary:headers];
    subHeaders[kHeaderDestination] = destination;
    NSString *identifier = subHeaders[kHeaderID];
    if (!identifier) {
        identifier = [NSString stringWithFormat:@"sub-%d", idGenerator++];
        subHeaders[kHeaderID] = identifier;
    }
    self.subscriptions[identifier] = handler;
    [self sendFrameWithCommand:kCommandSubscribe
                       headers:subHeaders
                          body:nil];
    return [[MAGSTOMPSubscription alloc] initWithClient:self identifier:identifier];
}

- (MAGSTOMPTransaction *)begin {
    NSString *identifier = [NSString stringWithFormat:@"tx-%d", idGenerator++];
    return [self begin:identifier];
}

- (MAGSTOMPTransaction *)begin:(NSString *)identifier {
    [self sendFrameWithCommand:kCommandBegin
                       headers:@{kHeaderTransaction: identifier}
                          body:nil];
    return [[MAGSTOMPTransaction alloc] initWithClient:self identifier:identifier];
}

- (void)disconnect {
    [self disconnect: nil];
}

- (void)disconnect:(void (^)(NSError *error))completionHandler {
    [self sendFrameWithCommand:kCommandDisconnect
                       headers:nil
                          body:nil];
    [self.subscriptions removeAllObjects];
    [self.pinger invalidate];
    [self.ponger invalidate];
    [self.socket close];
}


#pragma mark -
#pragma mark Private Methods

- (void)sendFrameWithCommand:(NSString *)command
                     headers:(NSDictionary *)headers
                        body:(NSString *)body {
    if (self.socket.readyState != SR_OPEN) {
        return;
    }
    MAGSTOMPFrame *frame = [[MAGSTOMPFrame alloc] initWithCommand:command headers:headers body:body];
    LogDebug(@">>> %@", frame);
    [self.socket send:[frame toString]];
}

- (void)sendPing {
    
    if (self.socket.readyState != SR_OPEN) {
        return;
    }
    
    [self.socket sendPing:[NSData dataWithBytes:kLineFeed length:1]];
    LogDebug(@">>> PING");
}

- (void)checkPong:(NSTimer *)timer  {
    NSDictionary *dict = timer.userInfo;
    NSInteger ttl = [dict[@"ttl"] intValue];
    
    CFAbsoluteTime delta = CFAbsoluteTimeGetCurrent() - serverActivity;
    if (delta > (ttl * 2)) {
        LogDebug(@"did not receive server activity for the last %f seconds", delta);
        [self disconnect:errorHandler];
    }
}

- (void)setupHeartBeatWithClient:(NSString *)clientValues
                          server:(NSString *)serverValues {
    NSInteger cx, cy, sx, sy;
    
    NSScanner *scanner = [NSScanner scannerWithString:clientValues];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@", "];
    [scanner scanInteger:&cx];
    [scanner scanInteger:&cy];
    
    scanner = [NSScanner scannerWithString:serverValues];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@", "];
    [scanner scanInteger:&sx];
    [scanner scanInteger:&sy];
    
    NSInteger pingTTL = ceil(MAX(cx, sy) / 1000);
    NSInteger pongTTL = ceil(MAX(sx, cy) / 1000);
    
    LogDebug(@"send heart-beat every %ld seconds", (long)pingTTL);
    LogDebug(@"expect to receive heart-beats every %ld seconds", (long)pongTTL);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (pingTTL > 0) {
            self.pinger = [NSTimer scheduledTimerWithTimeInterval: pingTTL
                                                           target: self
                                                         selector: @selector(sendPing)
                                                         userInfo: nil
                                                          repeats: YES];
        }
        if (pongTTL > 0) {
            self.ponger = [NSTimer scheduledTimerWithTimeInterval: pongTTL
                                                           target: self
                                                         selector: @selector(checkPong:)
                                                         userInfo: @{@"ttl": [NSNumber numberWithInteger:pongTTL]}
                                                          repeats: YES];
        }
    });
    
}

- (void)receivedFrame:(MAGSTOMPFrame *)frame {
    // CONNECTED
    if([kCommandConnected isEqual:frame.command]) {
        self.connected = YES;
        [self setupHeartBeatWithClient:self.clientHeartBeat server:frame.headers[kHeaderHeartBeat]];
        if (self.didConnectBySTOMP) {
            self.didConnectBySTOMP(frame);
        }
        // MESSAGE
    } else if([kCommandMessage isEqual:frame.command]) {
        MAGSTOMPMessageHandler handler = self.subscriptions[frame.headers[kHeaderSubscription]];
        if (handler) {
            MAGSTOMPMessage *message = [MAGSTOMPMessage MAGSTOMPMessageFromFrame:frame
                                                                 client:self];
            handler(message);
        } else {
            //TODO default handler
        }
        // RECEIPT
    } else if([kCommandReceipt isEqual:frame.command]) {
        if (self.receiptHandler) {
            self.receiptHandler(frame);
        }
        // ERROR
    } else if([kCommandError isEqual:frame.command]) {
        NSError *error = [[NSError alloc] initWithDomain:@"StompKit" code:1 userInfo:@{@"frame": frame}];
        // ERROR coming after the CONNECT frame
        if (!self.connected && self.didConnectBySTOMP) {
#warning didConnectBySTOMP error handling
            self.didConnectBySTOMP(frame);
        } else if (self.errorHandler) {
            self.errorHandler(error);
        } else {
            LogDebug(@"Unhandled ERROR frame: %@", frame);
        }
    } else {
        NSError *error = [[NSError alloc] initWithDomain:@"StompKit"
                                                    code:2
                                                userInfo:@{@"message": [NSString stringWithFormat:@"Unknown frame %@", frame.command],
                                                           @"frame": frame}];
        if (self.errorHandler) {
            self.errorHandler(error);
        }
    }
}

+ (NSString *)stringFromData:(NSData*)data {
    return [[NSString alloc] initWithData:[data copy] encoding:NSUTF8StringEncoding];
    
}

#pragma mark - SRWebSocket Delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    LogDebug(@"=== WEB SOCKET DID OPEN ===");
    
    if (self.webSocketDidOpen) {
        self.webSocketDidOpen();
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.connectHeaders[kHeaderAcceptVersion] = kVersion1_2;
        //        if (!connectHeaders[kHeaderHost]) {
        //            connectHeaders[kHeaderHost] = host;
        //        }
        if (!connectHeaders[kHeaderHeartBeat]) {
            connectHeaders[kHeaderHeartBeat] = self.clientHeartBeat;
        } else {
            self.clientHeartBeat = connectHeaders[kHeaderHeartBeat];
        }
        
        [self sendFrameWithCommand:kCommandConnect
                           headers:connectHeaders
                              body: nil];
    });
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    LogDebug(@"=== WEB SOCKET DID CLOSE WITH CODE: %ld REASON: < %@ > ===", (long)code, reason);
    self.connected = NO;
    
    if (self.webSocketDidCloseWithCodeAndReason) {
        self.webSocketDidCloseWithCodeAndReason(code, reason);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    LogDebug(@"=== WEB SOCKET DID FAIL WITH ERROR: < %@ > ===", error);
    
    if (self.didFailWithError) {
        self.didFailWithError(error);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    if ([message isEqualToString:kLineFeed]) {
        LogDebug(@"<<< PONG");
        serverActivity = CFAbsoluteTimeGetCurrent();
        [self sendPing];
    } else {
        LogDebug(@"=== WEB SOCKET DID RECEIVE MESSAGE: < %@ > ===", message);
        MAGSTOMPFrame *frame = [MAGSTOMPFrame MAGSTOMPFrameFromDataString:message];
        [self receivedFrame:frame];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    LogDebug(@"<<< PONG");
    serverActivity = CFAbsoluteTimeGetCurrent();
}

@end
