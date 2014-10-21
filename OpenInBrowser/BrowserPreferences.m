//
//  BrowserPreferences.m
//  OpenInBrowser
//
//  Created by tarunon on 2014/09/15.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import "BrowserPreferences.h"

@implementation BrowserPreferences

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setUserDefaults:[[NSUserDefaults alloc] initWithSuiteName:@"group.com.tarunon.openin"]];
    }
    return self;
}

@end
