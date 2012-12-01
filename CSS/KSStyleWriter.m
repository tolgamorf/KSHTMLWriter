//
//  KSStyleWriter.m
//  Sandvox
//
//  Created by Mike Abdullah on 17/06/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//
/*
 
 
 For writing style declarations within a block.  To write out an entire declaration, use KSStyleSheetWriter.
 
 
 Dan's note: I'm not sure how much I want to put into this class.  Yes, convenience methods
 for emitting and formatting CSS.  Perhaps complex stuff like the gradient generation (which needs
 some complex formatting, plus output of special variants for decent browser compatibility).
 
 But when it comes to things like background images, where there is a lot of complexity in
 how it's built up, it might be better to leave the logic on the Sandvox side of the fence.
 
 We'll see. 
 
 
 Possible improvement:  Automatically intercept calls for certain properties, and either
 output the property, with different prefixes, multiple times (e.g. filters), or re-output
 the property with a prefixed value, like gradients.
 
 */

#import "KSStyleWriter.h"

#import "KSBackgroundProperties.h"


@implementation KSStyleWriter


#pragma mark General

- (void)writeProperty:(NSString *)property value:(NSString *)value;     // Convenience, no comment
{
    [self writeProperty:property value:value comment:nil];
}

- (void)writeProperty:(NSString *)property asPercent:(float)floatValue comment:(NSString *)comment;
{
    [self writeProperty:property value:[NSString stringWithFormat:@"%.6g%%", 100.0f * floatValue] comment:comment];
}

// Higher level convenience function; it builds up the correct string.
- (void)writeProperty:(NSString *)property float:(float)floatValue units:(NSString *)units comment:(NSString *)comment;
{
    NSString *value = (0.0 == floatValue) ? @"0" : [NSString stringWithFormat:@"%.6g%@", floatValue, units];
    [self writeProperty:property value:value comment:comment];
}

- (void)writeProperty:(NSString *)property int:(int)intValue units:(NSString *)units comment:(NSString *)comment;
{
    NSString *value = (0 == intValue) ? @"0" : [NSString stringWithFormat:@"%d%@", (int)intValue, units];
    [self writeProperty:property value:value comment:comment];
}

// Primitive method to write out property without checking for special prefixes to also write.
- (void)_writeProperty:(NSString *)property value:(NSString *)value comment:(NSString *)comment;
{
    [self writeString:property];
    [self writeString:@":"];
    if (self.outputFormat & kStyleSpaceAfterColon) [self writeString:@" "];
    [self writeString:value];
    [self writeString:@";"];
#if CSS_COMMENTS
    if (comment && ![comment isEqualToString:@""])
    {
        if (self.outputFormat & kStyleSpacesBetween || self.outputFormat & kStyleLinesBetween) [self writeString:@" "];
        [self writeString:@"/* "];
        [self writeString:comment];
        [self writeString:@" */"];
    }
#endif
    if (self.outputFormat & kStyleSpacesBetween) [self writeString:@" "];
    if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n"];
}


// Main version of writeProperty that allows a comment -- IGNORED if we aren't generating comments
// This is the "bottleneck" method that all convenience methods call.
// It knows which properties need to have browser prefix versions written as well.
//
//  (Should it force them to be single-line?)
//


/*
 
https://developer.mozilla.org/en-US/docs/CSS/CSS_Reference/Mozilla_Extensions?redirectlocale=en-US&redirectslug=CSS_Reference%2FMozilla_Extensions
 
 
 
 */

- (void)writeProperty:(NSString *)property value:(NSString *)value comment:(NSString *)comment;
{
    static NSMutableDictionary *sSpecialProperties = nil;
    static NSDictionary *sSpecialPropertyPrefixes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSSet *sO = [NSSet setWithArray:@[@"o"]];
        NSSet *sWebkit = [NSSet setWithArray:@[@"webkit"]];
        NSSet *sMozWebkit = [NSSet setWithArray:@[@"moz", @"webkit"]];
        NSSet *sMozWebkitO = [NSSet setWithArray:@[@"moz", @"webkit", @"o"]];
        NSSet *sMozWebkitOMs = [NSSet setWithArray:@[@"moz", @"webkit", @"o", @"ms"]];
        NSSet *sMozWebkitMs = [NSSet setWithArray:@[@"moz", @"webkit", @"ms"]];
        
                                    
        
        sSpecialProperties = [[NSMutableDictionary alloc] initWithDictionary:@{     // Mutable so it can be added for caching
                              @"transform" : sMozWebkitOMs,
                              @"gradient" : sMozWebkitO,
                              @"hyphens" : sMozWebkitMs,
                              @"transform-style" : sMozWebkit,   // ??? o, ??? ms
                              @"border-image" : sMozWebkitO,
                              @"box-shadow" : sWebkit,
                              @"box-sizing" : sMozWebkit,
                              @"text-overflow" : sO,
							  @"border-width": [NSSet set],		// prevent border-width from matching wildcard below
                              
                              @"transition" : sMozWebkitO,
                              @"filter" : sWebkit,
                              @"box-reflect" : sWebkit,
                              @"text-fill-color" : sWebkit }];
        
        // Slower check by prefix.  If a match is found, it's added to sSpecialProperties, at runtime, for faster matching next time.
        sSpecialPropertyPrefixes = [[NSDictionary alloc] initWithDictionary:@{
                                    @"animation-" : sMozWebkitO,      // Really would like an NSSet prefix here!
                                    @"border-" : sMozWebkit,       // For border-*-radius. Moz: ff 3.6 and back, so maybe we could exclude, though csslint wants it.
                                    @"column-" : sMozWebkit,
                                    @"mask-" : sWebkit,
                                    @"text-stroke" : sWebkit }];
    });
    
    __block NSSet *prefixesToUse = [sSpecialProperties valueForKey:property];     // Special property in our quick lookup?
    if (!prefixesToUse)
    {
        [sSpecialPropertyPrefixes enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent
                                                 usingBlock:^(id propertyPrefixKey, id browserPrefixSet, BOOL *stop) {
                                                     if ([property hasPrefix:propertyPrefixKey])
                                                     {
                                                         prefixesToUse = browserPrefixSet;
                                                         *stop = YES;
                                                     }
                                                 }];
        if (prefixesToUse)
        {
            // If it found a match, cache this result in sSpecialProperties so that next time, in this run, the property will be found quickly.
            sSpecialProperties[property] = prefixesToUse;
        }
    }
    if (prefixesToUse)      // So, did we find any prefixes? If so, write them out (along with the regular one)
    {
        KSStyleSheetOutputFormat savedFormat = self.outputFormat;
        self.outputFormat = (savedFormat | kStyleSpacesBetween) & (~kStyleLinesBetween);
        
        for (NSString *prefix in [[prefixesToUse allObjects] sortedArrayUsingSelector:@selector(compare:)])
        {
            [self _writeProperty:[NSString stringWithFormat:@"-%@-%@", prefix, property] value:value comment:nil];
        }
        self.outputFormat = savedFormat;
        [self _writeProperty:property value:value comment:comment]; // Only do comment last.
    
    }
    else        // No prefixes, just write the usual property.
    {
        [self _writeProperty:property value:value comment:comment];
    }
    
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
        sPrefixes = @[@"-moz-", @"-webkit-", @"-o-", @""];
        [sPrefixes retain];
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
            sDirectionKeywords = @[@"top", @"left top", @"right", @"right top", @"left", @"bottom", @"left bottom", @"right bottom", @"right"];
            [sDirectionKeywords retain];
        });
        toString = [NSString stringWithFormat:@"to %@", sDirectionKeywords[toEdge]];
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
            if (self.outputFormat & kStyleSpacesBetween) [buf appendString:@" "];
        }
        else
        {
            [buf appendFormat:@"%@ %d%%,",
             [self.class CSSRepresentationOfColor:color],
             (int) roundf(location * 100.0)];
            if (self.outputFormat & kStyleSpacesBetween) [self writeString:@" "];
       }
    }
    NSUInteger toDelete = (self.outputFormat & kStyleSpacesBetween) ? 2 : 1;
    [buf deleteCharactersInRange:NSMakeRange([buf length]-toDelete, toDelete)];    // space or comma-space
    [buf appendString:@")"];
    return buf;
}

@end
