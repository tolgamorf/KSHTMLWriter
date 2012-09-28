//
//  KSStyleWriter.m
//  Sandvox
//
//  Created by Mike Abdullah on 17/06/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//
/*
 
 Dan's note: I'm not sure how much I want to put into this class.  Yes, convenience methods
 for emitting and formatting CSS.  Perhaps complex stuff like the gradient generation (which needs
 some complex formatting, plus output of special variants for decent browser compatibility).
 
 But when it comes to things like background images, where there is a lot of complexity in
 how it's built up, it might be better to leave the logic on the Sandvox side of the fence.
 
 We'll see. 
 
 */

#import "KSStyleWriter.h"

#import "KSBackgroundProperties.h"


@implementation KSStyleWriter

#pragma mark General

- (void)writeProperty:(NSString *)property value:(NSString *)value;
{
    [self writeString:property];
    [self writeString:@":"];
    if (!self.compact) [self writeString:@" "];
    [self writeString:value];
    [self writeString:@";"];
    if (self.newlines)
    {
        [self writeString:@"\n"];
    }
    else if (!self.compact)
    {
        [self writeString:@" "];
    }
}

// Version of writeProperty that allows a comment -- IGNORED if we aren't generating comments
- (void)writeProperty:(NSString *)property value:(NSString *)value comment:(NSString *)comment;
{
    [self writeString:property];
    [self writeString:@":"];
    if (!self.compact) [self writeString:@" "];
    [self writeString:value];
    [self writeString:@";"];
#if CSS_COMMENTS
    if (comment && ![comment isEqualToString:@""])
    {
        if (!self.compact) [self writeString:@" "];
        [self writeString:@"/* "];
        [self writeString:comment];
        [self writeString:@" */"];
    }
#endif
    if (self.newlines)
    {
        [self writeString:@"\n"];
    }
    else if (!self.compact)
    {
        [self writeString:@" "];
    }
}

#pragma mark Comments

- (void) writeLineComment:(NSString *)comment;      // \n afterward if appropriate.
{
#if CSS_COMMENTS

    [self.writeString:@"/* "];
    [self.writeString:comment];
    [self.writeString:@" */"];
    if (self.newlines)
    {
        [self.writeString:@"\n"];
    }
#endif
}

#pragma mark Backgrounds

// Not general enough for multiple backgrounds. 

- (BOOL)writeBackground:(KSBackgroundProperties *)background;
{
    return [self writeBackgroundWithColor:[background color]
                                    image:[background imageString]
                                   repeat:[background repeat]
                               attachment:[background attachment]
                                 position:[background position]];
}

- (BOOL)writeBackgroundWithColor:(NSColor *)color
                           image:(NSString *)image
                          repeat:(NSString *)repeat
                      attachment:(NSString *)attachment
                        position:(NSString *)position;
{
    NSMutableArray *components = [[NSMutableArray alloc] init];
    
    if (color)
    {
        NSString *colorName = [[self class] CSSRepresentationOfColor:color];
        if (!colorName) return NO;
        [components addObject:colorName];
    }
    
    if (image) [components addObject:image];
    if (repeat) [components addObject:repeat];
    if (attachment) [components addObject:attachment];
    if (position) [components addObject:position];
    
    [self writeProperty:@"background" value:[components componentsJoinedByString:@" "]];
    [components release];
    
    return YES;
}

#pragma mark Color

- (BOOL)writeProperty:(NSString *)property color:(NSColor *)color;
{
    NSString *hex = [[self class] CSSRepresentationOfColor:color];
    if (!hex) return NO;
    
    [self writeProperty:property value:hex];
    return YES;
}

+ (NSString *)CSSRepresentationOfColor:(NSColor *)color;
{
    NSString *result;
    
    // Can't handle non-RGB colors
    if ([[color colorSpace] colorSpaceModel] != NSRGBColorSpaceModel)
    {
        color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        if (!color)
        {
            NSLog(@"Cannot convert color into RGB color space: %@", color); // unusual, so log it.
            return nil;
        }
    }
    
    // Note: In IE9 and up, we could use HSLa representation.  Might make the CSS more readable,
    // but otherwise won't really buy us much.
    // Alpha is only fully supported in IE9.  Oh well.
    CGFloat red,green,blue,alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    NSUInteger r = 0.5 + red	* 255.0;
    NSUInteger g = 0.5 + green	* 255.0;
    NSUInteger b = 0.5 + blue	* 255.0;

    if (alpha < 0.999)
    {
        // Alpha in the color, so use RGBa method.
        result = [NSString stringWithFormat:@"rgba(%d,%d,%d,%.3g)", (int)r,(int)g,(int)b,alpha];
    }
    else
    {
        // No alpha; use hex format since it's compact.        
        
        // Can generate shorter string for simple colors
        // TODO: The old code returned standard names like "blue" when appropriate. Worth bothering with?
        NSString *result;
        NSUInteger r16 = r/16;
        NSUInteger g16 = g/16;
        NSUInteger b16 = b/16;
        
        if ( (r16 == r%16) && (g16 == g%16) && (b16 == b%16) )
        {
            result = [NSString stringWithFormat:@"#%X%X%X",(int)r16,(int)g16,(int)b16];
        }
        else
        {
            result = [NSString stringWithFormat:@"#%02X%02X%02X",(int)r,(int)g,(int)b];
        }
    }
	return result;
}

#pragma mark Gradients

- (BOOL)writeProperty:(NSString *)property gradient:(NSGradient *)gradient;
{
    
    // FIXME: Pass in the degrees.
    
    NSString *value = [[self class] CSSRepresentationOfGradient:gradient toEdge:NSImageAlignTop orDegrees:0];
    if (!value) return NO;
    
    // TODO: Perhaps we want to support the old webkit syntax for Safari 5.1?  The old MS filter for IE 9?

    // Write out the property multiple times, once for each browser variant.
    static NSArray *sPrefixes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sPrefixes = [[NSArray alloc] initWithObjects:@"-moz-", @"-webkit-", @"-o-", @"", nil];
    });
    for (NSString *prefix in sPrefixes)
    {
        [self writeProperty:property value:[prefix stringByAppendingString:value]];
    }
    return YES;
}

// An instance method so it can know output options.

- (NSString *)CSSRepresentationOfGradient:(NSGradient *)gradient toEdge:(NSImageAlignment)toEdge orDegrees:(CGFloat )toDegrees    // pass in 0 edge and degrees if you want degrees.
{
    NSMutableString *buf = [NSMutableString string];
    
    NSString *toString = nil;
    if (toEdge > 0)
    {
        static NSArray *sDirectionKeywords = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sDirectionKeywords = [[NSArray alloc] initWithObjects:@"top", @"left top", @"right", @"right top", @"left", @"bottom", @"left bottom", @"right bottom", @"right",nil];
        });
        toString = [NSString stringWithFormat:@"to %@", [sDirectionKeywords objectAtIndex:toEdge]];
    }
    else
    {
        toString = [NSString stringWithFormat:@"%.fdeg", toDegrees];
    }
    
    [buf appendString:@"linear-gradient("];
    [buf appendString:toString];
    [buf appendString:@", "];
    
    
    NSInteger n = [gradient numberOfColorStops];
    for (NSInteger i = 0; i < n ; i++)
    {
        NSColor *color = nil;
        CGFloat location = 0.0;
        [gradient getColor:&color location:&location atIndex:i];
        
        if (    (i == 0 && location == 0.0)
            ||  (i == n-1 && location == 1.0) )
        {
            // We can just do the color
            [buf appendString:[self.class CSSRepresentationOfColor:color]];
            if (!self.compact) [buf appendString:@", "];
        }
        else
        {
            [buf appendFormat:@"%@ %d%%,",
             [self.class CSSRepresentationOfColor:color],
             (int) roundf(location * 100.0)];
            if (!self.compact) [buf appendString:@", "];
       }
    }
    NSUInteger toDelete = self.compact ? 1 : 2;
    [buf deleteCharactersInRange:NSMakeRange([buf length]-toDelete, toDelete)];    // space or comma-space
    [buf appendString:@")"];
    return buf;
}

@end
