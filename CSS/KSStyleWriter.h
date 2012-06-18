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

@end
