//
//  GlobalMarksViewController.h
//  XVim
//
//  Created by Ant on 05/01/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "XVimGlobalMark.h"

@interface GlobalMarksViewController : NSViewController {
    NSArray* _globalMarks;
}

@property (retain,nonatomic) NSArray* globalMarks;
+(GlobalMarksViewController*)instance;
    
@end
