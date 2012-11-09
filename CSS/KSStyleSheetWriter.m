//
//  KSStyleSheetWriter.m
//
//  Copyright 2010-2012, Mike Abdullah and Karelia Software
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL MIKE ABDULLAH OR KARELIA SOFTWARE BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "KSStyleSheetWriter.h"

#import "KSStyleWriter.h"


@implementation KSStyleSheetWriter

+ (NSString *)stringWithDeclarationsBlock:(void(^)(KSStyleWriter *))declarations;
{
    NSMutableString *buffer = [NSMutableString string];
    KSStyleWriter *writer = [[[self alloc] initWithOutputWriter:buffer] autorelease];
    declarations(writer);
    [writer close];
    return [NSString stringWithString:buffer];
}

- (void)writeSelector:(NSString *)selector declarations:(NSString *)declarations;
{
    [self writeString:selector];
    [self writeString:@" { "];
    [self writeString:declarations];
    [self writeString:@"}\n"];
}

- (void)writeSelector:(NSString *)selector declarationsBlock:(void (^)(KSStyleWriter *))declarations;
{
    [self writeString:selector];
    [self writeString:@" { "];
    
    KSStyleWriter *styleWriter = [[KSStyleWriter alloc] initWithOutputWriter:self];
    declarations(styleWriter);
    [styleWriter release];
    
    [self writeString:@"}\n"];
}

- (void)writeCSSString:(NSString *)cssString;
{
    [self writeString:cssString];
    if (![cssString hasSuffix:@"\n"]) [self writeString:@"\n"];
    [self writeString:@"\n"];
}

- (void)writeIDSelector:(NSString *)ID;
{
    [self writeString:@"#"];
    [self writeString:ID];
}

- (void)writeDeclarationBlock:(NSString *)declarations;
{
    [self writeString:@" {"];
    [self writeString:declarations];
    [self writeString:@"}"];
    
    // Could be smarter and analyze declarations for newlines
}

- (void) writeLine:(NSString *)line;      // \n afterward if appropriate.
{
    [self writeString:line];
    if (self.newlines)
    {
        [self writeString:@"\n"];
    }
}

#pragma mark Comments

- (void) writeCommentLine:(NSString *)comment;      // \n afterward if appropriate.
{
#if CSS_COMMENTS
    
    [self writeString:@"/* "];
    [self writeString:comment];
    [self writeString:@" */"];
    if (self.newlines)
    {
        [self writeString:@"\n"];
    }
#endif
}

#pragma mark Media Queries

- (void)writeMediaQuery:(NSString *)predicate comment:(NSString *)comment declarationsBlock:(void (^)(KSStyleSheetWriter *styleWriter))declarations;
{
    // Collect the declarations before writing anything, in case it's empty.
    
    NSMutableString *buffer = [NSMutableString string];
    KSStyleSheetWriter *writer = [[[[self class] alloc] initWithOutputWriter:buffer] autorelease];
    declarations(writer);
    [writer close];
        
    if ([buffer length])
    {
        // Indent the declarations for going into the media query block
        if ([buffer hasSuffix:@"\n"]) { [buffer deleteCharactersInRange:NSMakeRange(buffer.length-1, 1)]; }
        // Indent with tabs
        [buffer replaceOccurrencesOfString:@"\n"
                                withString:@"\n\t"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0,[buffer length])];
        [buffer insertString:@"\t" atIndex:0];

        [self writeString:@"@media "];
        [self writeString:predicate];
        [self writeString:@" { "];
        [self writeString:buffer];
        [self writeString:@"}\n"];
    }
}


@end
