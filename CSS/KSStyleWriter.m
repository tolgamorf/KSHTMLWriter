//
//  KSStyleWriter.m
//  Sandvox
//
//  Created by Mike Abdullah on 17/06/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KSStyleWriter.h"

@implementation KSStyleWriter

- (void)writeProperty:(NSString *)property value:(NSString *)value;
{
    [self writeString:property];
    [self writeString:@": "];
    [self writeString:value];
    [self writeString:@"; "];
}

- (BOOL)writeBackgroundWithImageURL:(NSURL *)image color:(NSColor *)color repeat:(BOOL)repeat;
{
    NSString *colorName = [[self class] hexadecimalRepresentationOfColor:color];
    if (!colorName) return NO;
    
    NSString *value = [NSString stringWithFormat:@"%@ url(%@)", colorName, [image absoluteString]];
    if (!repeat)
    {
        value = [value stringByAppendingString:@" no-repeat"];
    }
    
    [self writeProperty:@"background" value:value];
    return YES;
}

- (BOOL)writeBackgroundWithGradient:(NSGradient *)gradient repeat:(BOOL)repeat;
{
    NSColor *endColor;
    [gradient getColor:&endColor location:NULL atIndex:([gradient numberOfColorStops] - 1)];
    NSString *endColorName = [[self class] hexadecimalRepresentationOfColor:endColor];
    if (!endColorName) return NO;
    
    NSString *gradientDesc = [[self class] linearGradientWithGradient:gradient];
    if (!gradientDesc) return NO;
    
    NSString *value = [NSString stringWithFormat:@"%@ %@", endColorName, gradientDesc];
    if (!repeat)
    {
        value = [value stringByAppendingString:@" no-repeat"];
    }
    
    [self writeProperty:@"background" value:value];
    return YES;
}

- (BOOL)writeProperty:(NSString *)property color:(NSColor *)color;
{
    NSString *hex = [[self class] hexadecimalRepresentationOfColor:color];
    if (!hex) return NO;
    
    [self writeProperty:property value:hex];
    return YES;
}

+ (NSString *)hexadecimalRepresentationOfColor:(NSColor *)color;
{
    // Can't handle non-RGB colors
    if ([[color colorSpace] colorSpaceModel] != NSRGBColorSpaceModel)
    {
        color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        if (!color) return nil;
    }
    
    
    // Grab the components to generate hex
	CGFloat red,green,blue,alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int r = 0.5 + red	* 255.0;
    int g = 0.5 + green	* 255.0;
    int b = 0.5 + blue	* 255.0;
    
    // Can generate shorter string for simple colors
    // TODO: The old code returned standard names like "blue" when appropriate. Worth bothering with?
    NSString *result;
    if ( (r/16 == r%16) && (g/16 == g%16) && (b/16 == b%16) )
    {
        result = [NSString stringWithFormat:@"#%X%X%X",r/16,g/16,b/16];
    }
    else
    {
        result = [NSString stringWithFormat:@"#%02X%02X%02X",r,g,b];
    }
    
	return result;
}

- (BOOL)writeProperty:(NSString *)property gradient:(NSGradient *)gradient;
{
    NSString *value = [[self class] linearGradientWithGradient:gradient];
    if (!value) return NO;
    
    [self writeProperty:property value:value];
    return YES;
}

+ (NSString *)linearGradientWithGradient:(NSGradient *)gradient;
{
    NSColor *color1;
    [gradient getColor:&color1 location:NULL atIndex:0];
    NSString *colorName1 = [self hexadecimalRepresentationOfColor:color1];
    if (!colorName1) return nil;
    
    NSColor *color2;
    [gradient getColor:&color2 location:NULL atIndex:1];
    NSString *colorName2 = [self hexadecimalRepresentationOfColor:color2];
    if (!colorName2) return nil;
    
    // TODO: Account for more than 2 colors
    
    NSString *result = [NSString stringWithFormat:
                        @"-webkit-linear-gradient(%@, %@)", colorName1, colorName2];
    
    return result;
}

@end
