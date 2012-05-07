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
@property(readonly) IDESourceCodeEditor *baseEditor;
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
- (void)splitEditorWindow;
- (void)addNewEditorWindow;
- (void)closeAllButCurrentWindow;
- (void)removeCurrentEditorWindow;
- (void)defaultLayoutAllWindows;
- (void)saveCurrentWindow;
- (void)saveCurrentWindowTo:(NSString*)relativePath;

- (void)moveFocusToNextEditor;
- (void)moveFocusToPreviousEditor;
- (void)moveFocusToTopEditor;
- (void)moveFocusToBotomEditor;

- (void)moveCurrentWindowToTop;
- (void)moveCurrentWindowToBottom;
@end