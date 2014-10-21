//
//  TNDefaultsWrapper.h
//  Libing
//
//  Created by tarunon on 2014/06/28.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TNPreferences : NSObject

+ (instancetype)sharedPreferences;

/**
 *  Use standard NSUserDefaults or set key value store.
 */
- (void)setUserDefaults:(NSUserDefaults *)defaults;
- (void)setUbiquityStore:(NSUbiquitousKeyValueStore *)store;

/**
 *  You set any key in NSUserDefaults for the property.
 *  @param dictionary e.g. @{@"propertyName": @"UserDefaultsKey"}
 */
- (void)setPropertiesDictionary:(NSDictionary *)dictionary;

/**
 *  Create a converter Object and Defaults in any property
 *
 *  @param d2o from Defaults to Object converter
 *  @param o2d from Object to Defaults converter
 *  @param propertyName property name that convert
 */
- (void)addConverterToObj:(id(^)(id fromDefaults))d2o toDefaults:(id(^)(id fromObj))o2d withPropertyName:(NSString *)propertyName;

- (void)synchronize;

@end
