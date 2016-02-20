//
//  CCNetworkProtocol.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#ifndef CCNetworkProtocol_h
#define CCNetworkProtocol_h

/*  Logging  */
#define LOG_LEVEL 3   /* 1-error 2-warning 3-info */
#define INFO_LOG      if(LOG_LEVEL < 3) ; else NSLog
#define WARNING_LOG   if(LOG_LEVEL < 2) ; else NSLog
#define ERROR_LOG     if(LOG_LEVEL < 1) ; else NSLog


/*  General  */
#define kCCNetworkProtocolVersion @"1.0.0"
#define kUseBonjour NO
#define kEnableAudio YES

// A block can never be more than MTU Size. We can assume MTU is ~1500.
// We'll leave 100 bytes for headers.
// On all networks tested 8192 bytes works fine but papers recommend smaller sizes
//8192
// 1420
#define CCNetworkUDPDataSize        8192

//Number of bytes used by tags and options
#define CCNetworkTagSize            4 //Bytes

#define CCNetworkServerPort         57901

/*  Discovery  */
#define CCNetworkPing               (uint32_t)10011
#define CCNetworkPingResponse       (uint32_t)10012
#define CCNetworkConnect            (uint32_t)10111
#define CCBonjourServerAddress      (uint32_t)10101

/*  Information  */
#define CCNetworkGetAvaliableGames  (uint32_t)5001
#define CCNetworkGetSubGames        (uint32_t)5002

/*  Stream Start */
#define CCNetworkOpenStream         (uint32_t)2010
#define CCNetworkReopenStream       (uint32_t)2011
#define CCNetworkStreamOpenSuccess  (uint32_t)2012
#define CCNetworkStreamOpenFailure  (uint32_t)2013
#define CCNetworkStreamReceivePort  (uint32_t)2020
#define CCNetworkCloseStream        (uint32_t)2021

// Stream Options
#define CCNetworkStreamUseTCP       (uint32_t)1 << 0 //Place holder

/*  In Stream  */
#define CCNetworkVideoData          (uint32_t)1008
#define CCNetworkAudioData          (uint32_t)1009
#define CCNetworkStreamKeepAlive    (uint32_t)1010

/*  Blocks  */
#define CCNetworkStreamBeginBlock   (uint32_t)1011
#define CCNetworkStreamBlockNumber  (uint32_t)1112
#define CCNetworkStreamAcknowledge  (uint32_t)1113
#define CCNetworkStreamAcknowledged (uint32_t)1114

/*  Controls  */
#define CCNetworkButtonState        (uint32_t)3030

#define CCNetworkDirectionalState   (uint32_t)3031

/*  Application States  */
#define CCStateHome                 (uint32_t)4001
#define CCStateInStream             (uint32_t)4002

/*  Enumerations  */

#endif /* NetworkProtocol_h */

