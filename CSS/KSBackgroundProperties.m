//
//  KSBackgroundProperties.m
//  Template Ideas
//
//  Created by Mike on 15/08/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KSBackgroundProperties.h"

#import "KSStyleWriter.h"


@implementation KSBackgroundProperties

- (id)initWithColor:(NSColor *)color imageString:(NSString *)image repeat:(NSString *)repeat attachment:(NSString *)attachment position:(NSString *)position;
{
    if (self = [self init])
    {
        _color = [color copy];
        _imageString = [image copy];
        _repeat = [repeat copy];
        _attachment = [attachment copy];
        _position = [position copy];
    }
    
    return self;
}

- (id)initWithColor:(NSColor *)color imageURLString:(NSString *)imageURL;
{
    NSString *image = (imageURL ? [NSString stringWithFormat:@"url(%@)", imageURL] : nil);
    return [self initWithColor:color imageString:image repeat:@"no-repeat" attachment:nil position:nil];
}

- (id)initWithGradient:(NSGradient *)gradient;
{
    NSColor *endColor;
    [gradient getColor:&endColor location:NULL atIndex:[gradient numberOfColorStops] - 1];
    
    return [self initWithColor:endColor imageString:[KSStyleWriter linearGradientWithGradient:gradient] repeat:@"no-repeat" attachment:nil position:nil];
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    return [self retain];
}

@end
