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

@end
