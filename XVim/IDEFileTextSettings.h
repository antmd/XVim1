//
//  IDEFileTextSettings.h
//  XVim
//
//  Created by Nader Akoury on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class IDEFileReference;
@class DVTStackBacktrace;

@interface IDEFileTextSettings : NSObject
{
    BOOL _isInvalidated;
    DVTStackBacktrace *_invalidationBacktrace;
    IDEFileReference *_fileReference;
    unsigned long long _textEncoding;
    long long _tabWidth;
    long long _indentWidth;
    unsigned long long _lineEndings;
    BOOL _usesTabs;
    BOOL _wrapsLines;
}

@property(readonly) DVTStackBacktrace *invalidationBacktrace; // @synthesize invalidationBacktrace=_invalidationBacktrace;
@property BOOL wrapsLines; // @synthesize wrapsLines=_wrapsLines;
@property long long indentWidth; // @synthesize indentWidth=_indentWidth;
@property long long tabWidth; // @synthesize tabWidth=_tabWidth;
@property BOOL usesTabs; // @synthesize usesTabs=_usesTabs;
@property unsigned long long textEncoding; // @synthesize textEncoding=_textEncoding;
@property unsigned long long lineEndings; // @synthesize lineEndings=_lineEndings;
@property(assign) IDEFileReference *fileReference; // @synthesize fileReference=_fileReference;
- (id)description;
- (void)updateWrapLines;
- (void)updateIndentWidth;
- (void)updateTabWidth;
- (void)updateUsesTabs;
- (void)updateTextEncoding;
- (void)updateLineEndings;
- (id)_textPreferences;
@property(readonly, getter=isValid) BOOL valid;
- (void)invalidate;
- (void)_clearFileReferenceObservations;
- (id)init;

@end