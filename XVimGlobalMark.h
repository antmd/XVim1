//
//  XVimGlobalMark.h
//  XVim
//
//  Created by Ant on 05/01/2013.
//
//

#import <Foundation/Foundation.h>

@interface XVimGlobalMark : NSObject
{
    NSString* _location;
    NSURL* _url;
    NSURL* _projectRelativeUrl;
    NSString* _mark;
}
@property (copy) NSString* location;
@property (readonly) NSString* file;
@property (copy) NSString* mark;
@property (copy) NSURL* url;
@property (readonly) NSURL* projectRelativeUrl;
+(XVimGlobalMark*)globalMark:(NSString*)mark withURL:(NSURL*)url withLocation:(NSString*)location;
@end

