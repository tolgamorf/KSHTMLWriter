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

@implementation NSMutableString (KSStyleSheetWriter)

- (void) ks_indentLines;
{
    if ([self hasSuffix:@"\n"]) { [self deleteCharactersInRange:NSMakeRange(self.length-1, 1)]; }
    // Indent with tabs
    [self replaceOccurrencesOfString:@"\n"
                            withString:@"\n\t"
                               options:NSLiteralSearch
                                 range:NSMakeRange(0,[self length])];
    [self insertString:@"\t" atIndex:0];
}
@end


@implementation KSStyleSheetWriter

+ (NSString *)stringWithOutputFormat:(KSStyleSheetOutputFormat)format declarations:(void(^)(KSStyleWriter *))declarations;
{
    NSMutableString *buffer = [NSMutableString string];
    KSStyleWriter *writer = [[[KSStyleWriter alloc] initWithOutputWriter:buffer] autorelease];
    writer.outputFormat = format;
    declarations(writer);
    [writer close];
    return [NSString stringWithString:buffer];
}
- (void)writeSelector:(NSString *)selector declarations:(void (^)(KSStyleWriter *))declarations;
{
    [self writeString:selector];
    if ([selector length] > 50 && (self.outputFormat & kStyleLongSelectorForceBreak) && 0 == (self.outputFormat & kStyleNewlineBeforeBrace))
    {
        [self writeString:@"\n\t"];
    }
    else    // normal case
    {
        if (self.outputFormat & kStyleSpacesBetween
            || (self.outputFormat & kStyleLinesBetween && 0 == (self.outputFormat & kStyleNewlineBeforeBrace)) ) [self writeString:@" "];      // #foo {
        if (self.outputFormat & kStyleNewlineBeforeBrace) [self writeString:@"\n"];
    }
    [self writeString:@"{"];
    if (self.outputFormat & kStyleSpacesBetween) [self writeString:@" "];
    if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n"];
    
    NSMutableString *buffer = [NSMutableString string];
    KSStyleWriter *styleWriter = [[[KSStyleWriter alloc] initWithOutputWriter:buffer] autorelease];
    styleWriter.outputFormat = self.outputFormat;
    declarations(styleWriter);
    if (self.outputFormat & kStyleIndent)
    {
        [buffer ks_indentLines];
    }
    if (0 == (self.outputFormat & kStyleEndingSemicolon) && [buffer hasSuffix:@";"]) // remove trailing ; which isn't needed, in super-compact mode.
    {
        [buffer deleteCharactersInRange:NSMakeRange([buffer length]-1,1)];
    }
    [self writeString:buffer];
    if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n"];
    [self writeString:@"}"];
    
    if (self.outputFormat & kStyleSpacesBetween || self.outputFormat & kStyleLinesBetween) [self writeString:@"\n"];				// Sorry, but a declaration block ends in a newline even if you want spaces between.
    // An extra newline if we are in multi-line mode, to separate blocks visually.
    if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n"];
}

- (void)writeSelector:(NSString *)selector declarationString:(NSString *)declarations;       // pre-built string; assume whitespace is as what we want here, but not indented
{
    [self writeSelector:selector declarations:^(KSStyleWriter *styleWriter){
        [styleWriter writeString:declarations];
    }];
}

- (void) writeLine:(NSString *)line;      // \n afterward if appropriate.  For @import directives and misc.
{
    [self writeString:line];
    // An extra newline if we are in multi-line mode, to separate blocks visually.
    if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n\n"];
}

#pragma mark Comments

- (void) writeCommentLine:(NSString *)comment;      // \n afterward if appropriate. Assumes it's starting on a line.
{
#if CSS_COMMENTS
    [self writeString:@"/* "];
    [self writeString:comment];
    [self writeString:@" */"];
    // An extra newline if we are in multi-line mode, to separate blocks visually.
    if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n\n"];
#endif
}

- (void) writeCommentSection:(NSString *)comment;      // \n afterward if appropriate. Assumes it's starting on a line.
{
#if CSS_COMMENTS
    [self writeString:@"/* "];
    if (self.outputFormat & kStyleHighlightSections) [self writeString:@"=========================================================================="];
    [self writeString:@"\n   "];
    [self writeString:comment];
    [self writeString:@"\n   "];
    if (self.outputFormat & kStyleHighlightSections) [self writeString:@"=========================================================================="];
    [self writeString:@" */"];
    // An extra newline if we are in multi-line mode, to separate blocks visually.
    if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n\n"];
#endif
}

#pragma mark Media Queries

- (void)writeMediaQuery:(NSString *)predicate declarations:(void (^)(KSStyleSheetWriter *styleWriter))declarations;
{
    // Collect the declarations before writing anything, in case it's empty.
    
    NSMutableString *buffer = [NSMutableString string];
    KSStyleSheetWriter *writer = [[[[self class] alloc] initWithOutputWriter:buffer] autorelease];
    writer.outputFormat = self.outputFormat;        // use same format as parent, though declarations block can certainly adjust to be more compact.
    declarations(writer);
    [writer close];
        
    if ([buffer length])
    {
        if (self.outputFormat & kStyleIndent)
        {
            [buffer ks_indentLines];
        }

        [self writeString:@"@media "];
        [self writeString:predicate];
        if (self.outputFormat & kStyleSpacesBetween
            || (self.outputFormat & kStyleLinesBetween && 0 == (self.outputFormat & kStyleNewlineBeforeBrace)) ) [self writeString:@" "];      // @media foo {
        if (self.outputFormat & kStyleNewlineBeforeBrace) [self writeString:@"\n"];
        [self writeString:@"{"];
        if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n"];
        if (self.outputFormat & kStyleSpacesBetween) [self writeString:@" "];
        [self writeString:buffer];
        if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n"];
        [self writeString:@"}"];
        // An extra newline if we are in multi-line mode, to separate blocks visually.
        if (self.outputFormat & kStyleLinesBetween) [self writeString:@"\n\n"];
    }
}


@end
