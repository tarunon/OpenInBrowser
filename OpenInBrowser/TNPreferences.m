//
//  TNDefaultsWrapper.m
//  Libing
//
//  Created by tarunon on 2014/06/28.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import <objc/runtime.h>
#import "TNPreferences.h"

@implementation NSString (defaultsWrapper)

- (NSString *)firstLetterUppercaseString_TNDefaultsWrapper
{
    return [[self substringToIndex:1].uppercaseString stringByAppendingString:[self substringFromIndex:1]];
}

- (NSString *)firstLetterLowercaseString_TNDefaultsWrapper
{
    return [[self substringToIndex:1].lowercaseString stringByAppendingString:[self substringFromIndex:1]];
}

@end

@interface TNPreferences()

@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic) NSUbiquitousKeyValueStore *store;
@property (nonatomic) NSDictionary *propertiesDictionary;

@end

@implementation TNPreferences

static NSString *const defaultsWrapperPrefix = @"TNPreferences";

- (NSString *)keyForSelector:(SEL)aSelector
{
    NSString *selName = NSStringFromSelector(aSelector);
    NSString *propertyName = [selName hasSuffix:@":"] ? propertyNameFromSetter(aSelector) : selName;
    NSString *key = _propertiesDictionary[propertyName];
    return key ? key : [defaultsWrapperPrefix stringByAppendingString:propertyName.capitalizedString];
}

static NSString *propertyNameFromSetter(SEL aSelector)
{
    NSString *selName = NSStringFromSelector(aSelector);
    return [[selName substringWithRange:NSMakeRange(3, selName.length - 4)] firstLetterLowercaseString_TNDefaultsWrapper];
}

static SEL setterForString(NSString *propertyName)
{
    return NSSelectorFromString([NSString stringWithFormat:@"set%@:", [propertyName firstLetterUppercaseString_TNDefaultsWrapper]]);
}

static id getDefaultsObject(TNPreferences *_self, SEL aSelector)
{
    if (_self.defaults) {
        return [_self.defaults objectForKey:[_self keyForSelector:aSelector]];
    } else {
        return [_self.store objectForKey:[_self keyForSelector:aSelector]];
    }
}

static void setDefaultsObject(TNPreferences *_self, SEL aSelector, id value)
{
    if (_self.defaults) {
        [_self.defaults setObject:value forKey:[_self keyForSelector:aSelector]];
    } else {
        [_self.store setObject:value forKey:[_self keyForSelector:aSelector]];
    }
}

static BOOL getDefaultsBoolean(TNPreferences *_self, SEL aSelector)
{
    if (_self.defaults) {
        return [_self.defaults boolForKey:[_self keyForSelector:aSelector]];
    } else {
        return [_self.store boolForKey:[_self keyForSelector:aSelector]];
    }
}

static void setDefaultsBoolean(TNPreferences *_self, SEL aSelector, BOOL value)
{
    if (_self.defaults) {
        [_self.defaults setBool:value forKey:[_self keyForSelector:aSelector]];
    } else {
        [_self.store setBool:value forKey:[_self keyForSelector:aSelector]];
    }
}

static NSInteger getDefaultsInteger(TNPreferences *_self, SEL aSelector)
{
    if (_self.defaults) {
        return [_self.defaults integerForKey:[_self keyForSelector:aSelector]];
    } else {
        return [_self.store longLongForKey:[_self keyForSelector:aSelector]];
    }
}

static void setDefaultsInteger(TNPreferences *_self, SEL aSelector, NSInteger value)
{
    if (_self.defaults) {
        [_self.defaults setInteger:value forKey:[_self keyForSelector:aSelector]];
    } else {
        [_self.store setLongLong:value forKey:[_self keyForSelector:aSelector]];
    }
}

static double getDefaultsDouble(TNPreferences *_self, SEL aSelector)
{
    if (_self.defaults) {
        return [_self.defaults doubleForKey:[_self keyForSelector:aSelector]];
    } else {
        return [_self.store doubleForKey:[_self keyForSelector:aSelector]];
    }
}

static void setDefaultsDouble(TNPreferences *_self, SEL aSelector, double value)
{
    if (_self.defaults) {
        [_self.defaults setDouble:value forKey:[_self keyForSelector:aSelector]];
    } else {
        [_self.store setDouble:value forKey:[_self keyForSelector:aSelector]];
    }
}

+ (instancetype)sharedPreferences
{
    static TNPreferences *_sharedWrapper;
    @synchronized (self) {
        if (!_sharedWrapper) {
            _sharedWrapper = [[self alloc] init];
        }
    }
    return _sharedWrapper;
}

+ (void)initialize
{
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    for (unsigned int idx = 0; idx < count; idx++) {
        objc_property_t property = properties[idx];
        NSString *propertyName = @(property_getName(property));
        if ([propertyName isEqualToString:NSStringFromSelector(@selector(defaults))] || [propertyName isEqualToString:NSStringFromSelector(@selector(store))] || [propertyName isEqualToString:NSStringFromSelector(@selector(propertiesDictionary))]) {
            continue;
        }
        const char *type = [self instanceMethodSignatureForSelector:NSSelectorFromString(propertyName)].methodReturnType;
        IMP getIMP, setIMP;
        if (!strcmp(type, @encode(BOOL))) {
            getIMP = (IMP)getDefaultsBoolean;
            setIMP = (IMP)setDefaultsBoolean;
        } else if (!strcmp(type, @encode(NSInteger))) {
            getIMP = (IMP)getDefaultsInteger;
            setIMP = (IMP)setDefaultsInteger;
        } else if (!strcmp(type, @encode(CGFloat))) {
            getIMP = (IMP)getDefaultsDouble;
            setIMP = (IMP)setDefaultsDouble;
        } else {
            getIMP = (IMP)getDefaultsObject;
            setIMP = (IMP)setDefaultsObject;
        }
        SEL getSEL = NSSelectorFromString(propertyName);
        SEL setSEL = setterForString(propertyName);
        class_replaceMethod(self, setSEL, setIMP, method_getTypeEncoding(class_getClassMethod(self, setSEL)));
        class_replaceMethod(self, getSEL, getIMP, method_getTypeEncoding(class_getClassMethod(self, getSEL)));
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        _defaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)setUserDefaults:(NSUserDefaults *)defaults
{
    _defaults = defaults;
    _store = nil;
}

- (void)setUbiquityStore:(NSUbiquitousKeyValueStore *)store
{
    _store = store;
    _defaults = nil;
}

- (void)setPropertiesDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *properties = dictionary.mutableCopy;
    [properties addEntriesFromDictionary:_propertiesDictionary];
    _propertiesDictionary = properties.copy;
}

- (void)addConverterToObj:(id(^)(id fromDefaults))d2o toDefaults:(id(^)(id fromObj))o2d withPropertyName:(NSString *)propertyName
{
    IMP getIMP = imp_implementationWithBlock(^id (TNPreferences *_self){
        return d2o(getDefaultsObject(_self, NSSelectorFromString(propertyName)));
    });
    IMP setIMP = imp_implementationWithBlock(^(TNPreferences *_self, id value){
        setDefaultsObject(_self, setterForString(propertyName), o2d(value));
    });
    SEL getSEL = NSSelectorFromString(propertyName);
    SEL setSEL = setterForString(propertyName);
    class_replaceMethod(self.class, getSEL, getIMP, method_getTypeEncoding(class_getInstanceMethod(self.class, getSEL)));
    class_replaceMethod(self.class, setSEL, setIMP, method_getTypeEncoding(class_getInstanceMethod(self.class, setSEL)));
}

- (void)synchronize
{
    [_defaults synchronize];
    [_store synchronize];
}

@end
