//
//  XVimWindowManager.h
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XVimWindow;
@class IDESourceCodeEditor;

@interface XVimWindowManager : NSObject
@property(assign) IDESourceCodeEditor *currentEditor;

+ (void)createWithEditor:(IDESourceCodeEditor*)editor;
+ (XVimWindowManager*)instance;

// These DO use the assisstant editor
- (void)addEditorWindow;
- (void)addEditorWindowVertical;
- (void)addEditorWindowHorizontal;
- (void)removeEditorWindow;
- (void)closeAllButActive;

// These DO NOT use the assisstant editor
- (void)addNewEditorWindow;
- (void)closeAllButCurrentWindow;
- (void)removeCurrentEditorWindow;
- (void)splitEditorWindow:(XVimWindow*)window;
- (void)defaultLayoutAllWindows;
- (void)moveFocusToNextEditor;
- (void)moveFocusToPreviousEditor;
@end