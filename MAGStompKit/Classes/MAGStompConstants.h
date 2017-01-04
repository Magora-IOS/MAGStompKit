//
//  MAGStompConstants.h
//  Pods
//
//  Created by Zykov Mikhail on 26.12.16.
//
//

#import <Foundation/Foundation.h>


#define kDefaultTimeout 5
#define kVersion1_2 @"1.1"
#define kNoHeartBeat @"0,0"

#pragma mark Logging macros

#if 1 // set to 1 to enable logs

#define LogDebug(frmt, ...) NSLog(frmt, ##__VA_ARGS__);

#else

#define LogDebug(frmt, ...) {}

#endif

#pragma mark Frame commands

#define kCommandAbort       @"ABORT"
#define kCommandAck         @"ACK"
#define kCommandBegin       @"BEGIN"
#define kCommandCommit      @"COMMIT"
#define kCommandConnect     @"CONNECT"
#define kCommandConnected   @"CONNECTED"
#define kCommandDisconnect  @"DISCONNECT"
#define kCommandError       @"ERROR"
#define kCommandMessage     @"MESSAGE"
#define kCommandNack        @"NACK"
#define kCommandReceipt     @"RECEIPT"
#define kCommandSend        @"SEND"
#define kCommandSubscribe   @"SUBSCRIBE"
#define kCommandUnsubscribe @"UNSUBSCRIBE"

#pragma mark Control characters

#define	kLineFeed @"\x0A"
#define	kNullChar @"\x00"
#define kHeaderSeparator @":"

#pragma mark Frame headers

#define kHeaderAcceptVersion @"accept-version"
#define kHeaderAck           @"ack"
#define kHeaderContentLength @"content-length"
#define kHeaderDestination   @"destination"
#define kHeaderHeartBeat     @"heart-beat"
#define kHeaderHost          @"host"
#define kHeaderID            @"id"
#define kHeaderLogin         @"login"
#define kHeaderMessage       @"message"
#define kHeaderPasscode      @"passcode"
#define kHeaderReceipt       @"receipt"
#define kHeaderReceiptID     @"receipt-id"
#define kHeaderSession       @"session"
#define kHeaderSubscription  @"subscription"
#define kHeaderTransaction   @"transaction"
#define kHeaderAuthorization @"Authorization"

#pragma mark Ack Header Values

#define kAckAuto             @"auto"
#define kAckClient           @"client"
#define kAckClientIndividual @"client-individual"


