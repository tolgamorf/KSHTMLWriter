//
//  KSBackgroundProperties.h
//  Template Ideas
//
//  Created by Mike on 15/08/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface KSBackgroundProperties : NSObject <NSCopying>

// Designated initializer
- (id)initWithColor:(NSColor *)color imageString:(NSString *)image repeat:(NSString *)repeat attachment:(NSString *)attachment position:(NSString *)position;

// Conveniences
- (id)initWithColor:(NSColor *)color imageURLString:(NSString *)imageURL;
- (id)initWithGradient:(NSGradient *)gradient;  // color is set to match end of gradient

// Properties
@property(readonly, copy, nonatomic) NSColor *color;
@property(readonly, copy, nonatomic) NSString *imageString;
@property(readonly, copy, nonatomic) NSString *repeat;
@property(readonly, copy, nonatomic) NSString *attachment;
@property(readonly, copy, nonatomic) NSString *position;

@end
