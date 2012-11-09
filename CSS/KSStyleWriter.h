//
//  KSStyleWriter.h
//  Sandvox
//
//  Created by Mike Abdullah on 17/06/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KSForwardingWriter.h"
#import "KSStyleSheetWriter.h"

@class KSBackgroundProperties;


@interface KSStyleWriter : KSForwardingWriter


@property KSStyleSheetOutputFormat outputFormat;

- (void)writeProperty:(NSString *)property value:(NSString *)value;
- (void)writeProperty:(NSString *)property float:(float)floatValue units:(NSString *)units comment:(NSString *)comment;
- (void)writeProperty:(NSString *)property int:(int)intValue units:(NSString *)units comment:(NSString *)comment;
- (void)writeProperty:(NSString *)property value:(NSString *)value comment:(NSString *)comment;
- (void)writeProperty:(NSString *)property asPercent:(float)floatValue comment:(NSString *)comment;


#pragma mark Colors & Gradients

// These methods return nil or NO if a color cannot be expressed in RGB

- (BOOL)writeBackground:(KSBackgroundProperties *)background;

- (BOOL)writeBackgroundWithColor:(NSColor *)color
                           image:(NSString *)image
                          repeat:(NSString *)repeat     // repeat | repeat-x | repeat-y | no-repeat | inherit
                      attachment:(NSString *)attachment // scroll | fixed | inherit
                        position:(NSString *)position;

- (BOOL)writeProperty:(NSString *)property color:(NSColor *)color;
+ (NSString *)CSSRepresentationOfColor:(NSColor *)color;

- (BOOL)writeProperty:(NSString *)property gradient:(NSGradient *)gradient;

@end
