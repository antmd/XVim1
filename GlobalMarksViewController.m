//
//  GlobalMarksViewController.m
//  XVim
//
//  Created by Ant on 05/01/2013.
//
//

#import "GlobalMarksViewController.h"
#import "XVimWindowManager.h"

@interface GlobalMarksViewController ()

@end

@implementation GlobalMarksViewController
@synthesize globalMarks = _globalMarks;

+(GlobalMarksViewController*)instance {
    static GlobalMarksViewController* sInstance = nil;
    if (sInstance==nil)
    {
        sInstance = [[ GlobalMarksViewController alloc] init];
    }
    return sInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    
    return self;
}

-(NSString*)nibName
{
    return @"GlobalMarksViewController";
}

-(NSBundle*)nibBundle
{
    return [NSBundle bundleForClass:[self class]];
}


- (void)dealloc
{
    [ _globalMarks release ];
    [super dealloc];
}

@end
