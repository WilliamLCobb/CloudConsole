//
//  CCNetworkProtocol.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#ifndef CCNetworkProtocol_h
#define CCNetworkProtocol_h

/*  General  */

#define kUseBonjour YES

// A block can never be more than MTU Size with we can assume is greater than 1024
#define CCNetworkUDPDataSize        8192

//Number of bytes used by tags and options
#define CCNetworkTagSize            4 //Bytes

#define CCNetworkServerPort         57901

/* Bonjour  */
#define CCBonjourServerAddress      (uint32_t)0101

/*  Information  */
#define CCNetworkGetAvaliableGames  (uint32_t)5001
#define CCNetworkGetSubGames        (uint32_t)5002

/*  Stream Start */
#define CCNetworkOpenStream         (uint32_t)2010
#define CCNetworkStreamOpenSuccess  (uint32_t)2011
#define CCNetworkStreamOpenFailure  (uint32_t)2012
#define CCNetworkStreamReceivePort  (uint32_t)2020
#define CCNetworkCloseStream        (uint32_t)2021

// Stream Options
#define CCNetworkStreamUseTCP       (uint32_t)1 << 0

/*  In Stream  */
#define CCNetworkVideoData          (uint32_t)1008
#define CCNetworkAudioData          (uint32_t)1009
#define CCNetworkStreamKeepAlive    (uint32_t)1010
#define CCNetworkStreamBeginBlock   (uint32_t)1011
#define CCNetworkStreamBlockNumber  (uint32_t)1112

/*  Controls  */
#define CCNetworkButtonState        (uint32_t) 3030
#define CCNetworkNoButtons          (uint16_t) 0
#define CCNetworkXButton            (uint16_t) 1 << 0
#define CCNetworkBButton            (uint16_t) 1 << 1
#define CCNetworkYButton            (uint16_t) 1 << 2
#define CCNetworkAButton            (uint16_t) 1 << 3
#define CCNetworkLButton            (uint16_t) 1 << 4
#define CCNetworkRButton            (uint16_t) 1 << 5
#define CCNetworkStartButton        (uint16_t) 1 << 6
#define CCNetworkSelectButton       (uint16_t) 1 << 7

#define CCNetworkDirectionalState   (uint32_t) 3031
#define CCNetworkNoDirection        (uint8_t) 0
#define CCNetworkUp                 (uint8_t) 1 << 0
#define CCNetworkDown               (uint8_t) 1 << 1
#define CCNetworkLeft               (uint8_t) 1 << 2
#define CCNetworkRight              (uint8_t) 1 << 3

/*  Application States  */
#define CCStateHome                 (uint32_t)4001
#define CCStateInStream             (uint32_t)4002

#endif /* NetworkProtocol_h */

