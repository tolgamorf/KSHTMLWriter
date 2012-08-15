//
//  KSStyleWriter.h
//  Sandvox
//
//  Created by Mike Abdullah on 17/06/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KSForwardingWriter.h"

@interface KSStyleWriter : KSForwardingWriter

- (void)writeProperty:(NSString *)property value:(NSString *)value;


#pragma mark Colors & Gradients
// These methods return nil or NO if a color cannot be expressed in RGB

- (BOOL)writeBackgroundWithColor:(NSColor *)color
                           image:(NSString *)image
                          repeat:(NSString *)repeat     // repeat | repeat-x | repeat-y | no-repeat | inherit
                      attachment:(NSString *)attachment // scroll | fixed | inherit
                        position:(NSString *)position;

- (BOOL)writeProperty:(NSString *)property color:(NSColor *)color;
+ (NSString *)hexadecimalRepresentationOfColor:(NSColor *)color;

- (BOOL)writeProperty:(NSString *)property gradient:(NSGradient *)gradient;
+ (NSString *)linearGradientWithGradient:(NSGradient *)gradient;


@end
