//
//  XVimGlobalMark.m
//  XVim
//
//  Created by Ant on 05/01/2013.
//
//

#import "XVimGlobalMark.h"


@implementation XVimGlobalMark
@synthesize location=_location;
@synthesize url=_url;
@synthesize mark=_mark;
@synthesize projectRelativeUrl=_projectRelativeUrl;


+(XVimGlobalMark*)globalMark:(NSString *)mark withURL:(NSURL *)url withLocation:(NSString *)location{
    XVimGlobalMark* gmark = [[ XVimGlobalMark alloc] init];
    gmark.mark = mark;
    gmark.url = url;
    gmark.location = location;
    return [gmark autorelease];
}


-(NSString*)file
{
    return [[self.url path]lastPathComponent];
}

-(void)setUrl:(NSURL *)url
{
    [_url release], _url=nil;
    _url = [url copy];
    
    [_projectRelativeUrl release], _projectRelativeUrl=nil;
    _projectRelativeUrl = [[ NSURL alloc] initWithString:self.file];
}


- (void)dealloc
{
    [_mark release];
    [_url release];
    [_location release];
    [_projectRelativeUrl release];
    [super dealloc];
}
@end

