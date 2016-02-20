//
//  CCISpotlight.h
//  Cloud Console
//
//  Created by Will Cobb on 2/16/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*  Spotlight Window */

@protocol CCISpotlightWindowDelegate <NSObject>

- (void)touchedScreen;

@end

@interface CCISpotlightWindow : UIWindow

@property (weak) id <CCISpotlightWindowDelegate> delegate;
@end

/*  Spotlight  */
@class CCISpotlight;
@protocol CCISpotlightDelegate <NSObject>

- (void)CCISpotlight:(CCISpotlight *)spotlight showFrame:(NSInteger)frameNumber;

@end

@interface CCISpotlight : NSObject <CCISpotlightWindowDelegate>

@property (weak) id <CCISpotlightDelegate> delegate;
@property (nonatomic) CFTimeInterval    automaticTransitionTime;

- (void)beginPresentation;
- (void)endPresentation;

- (void)hideSpotlight;

- (void)showCircleSpotlightAtPoint:(CGPoint)point radius:(CGFloat)radius;
- (void)moveCircleSpotlightToPoint:(CGPoint)point radius:(CGFloat)radius;

- (void)showSquareSpotlightAtPoint:(CGPoint)point size:(CGSize)size;
- (void)moveSquareSpotlightToPoint:(CGPoint)point size:(CGSize)size;
@end
