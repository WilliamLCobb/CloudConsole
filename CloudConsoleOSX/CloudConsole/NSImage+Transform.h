//
//   - (NSImage*)imageRotatedByDegrees:(CGFloat)degrees ;  - (NSImage*)darkenedImage ;  NSImage+Transform.h
//  CloudConsole
//
//  Created by Will Cobb on 2/13/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Transform)

- (NSImage*)imageRotatedByDegrees:(CGFloat)degrees;
- (NSImage*)darkenedImage;

@end
