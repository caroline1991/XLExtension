//
//  NSObject+XLModel.m
//  XLNetWorkLibrary
//
//  Created by xl10014 on 2017/3/2.
//  Copyright © 2017年 xl10014. All rights reserved.
//

#import "NSObject+XLModel.h"
#import "XLClassInfoMeta.h"
#import <objc/message.h>

#define force_inline __inline__ __attribute__((always_inline))

typedef struct {
    void *modelMeta;
    void *model;
    void *dictionary;
} ModelSetContext;

static force_inline NSNumber *CPNSNumberCreateFromID(__unsafe_unretained id value) {
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{@"TRUE" :   @(YES),
                @"True" :   @(YES),
                @"true" :   @(YES),
                @"FALSE" :  @(NO),
                @"False" :  @(NO),
                @"false" :  @(NO),
                @"YES" :    @(YES),
                @"Yes" :    @(YES),
                @"yes" :    @(YES),
                @"NO" :     @(NO),
                @"No" :     @(NO),
                @"no" :     @(NO),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
    });
    
    if (!value || value == (id)kCFNull) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num) {
            if (num == (id)kCFNull) return nil;
            return num;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        } else {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            return @(atoll(cstring));
        }
    }
    return nil;
}


static force_inline void ModelSetNumberToProperty(__unsafe_unretained id model,
                                                  __unsafe_unretained NSNumber *num,
                                                  __unsafe_unretained XLModelPropertyMeta *meta) {
    switch (meta->_type & XLEncodingTypeMask) {
        case XLEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)model, meta->_setter, num.boolValue);
        } break;
        case XLEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id)model, meta->_setter, (int8_t)num.charValue);
        } break;
        case XLEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint8_t)num.unsignedCharValue);
        } break;
        case XLEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id)model, meta->_setter, (int16_t)num.shortValue);
        } break;
        case XLEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint16_t)num.unsignedShortValue);
        } break;
        case XLEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id)model, meta->_setter, (int32_t)num.intValue);
        }
        case XLEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint32_t)num.unsignedIntValue);
        } break;
        case XLEncodingTypeInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.longLongValue);
            }
        } break;
        case XLEncodingTypeUInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.unsignedLongLongValue);
            }
        } break;
        case XLEncodingTypeFloat: {
            float f = num.floatValue;
            if (isnan(f) || isinf(f)) f = 0;
            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)model, meta->_setter, f);
        } break;
        case XLEncodingTypeDouble: {
            double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)model, meta->_setter, d);
        } break;
        case XLEncodingTypeLongDouble: {
            long double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id)model, meta->_setter, (long double)d);
        }
        default: break;
    }
}


static void ModelSetValueForProperty(__unsafe_unretained id model, __unsafe_unretained id value, __unsafe_unretained XLModelPropertyMeta *meta) {
    if (meta->_isCNumber) {
        NSNumber *num = CPNSNumberCreateFromID(value);
        ModelSetNumberToProperty(model, num, meta);
        if (num) [num class];
    } else if (meta->_nsType) {
        if (value == (id)kCFNull) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)nil);
        } else {
            switch (meta->_nsType) {
                case XLEncodingTypeNSString:
                case XLEncodingTypeNSMutableString: {
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_nsType == XLEncodingTypeNSString) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSString *)value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                       meta->_setter,
                                                                       (meta->_nsType == XLEncodingTypeNSString) ?
                                                                       ((NSNumber *)value).stringValue :
                                                                       ((NSNumber *)value).stringValue.mutableCopy);
                    } else if ([value isKindOfClass:[NSData class]]) {
                        NSMutableString *string = [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, string);
                    } else if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                       meta->_setter,
                                                                       (meta->_nsType == XLEncodingTypeNSString) ?
                                                                       ((NSURL *)value).absoluteString :
                                                                       ((NSURL *)value).absoluteString.mutableCopy);
                    } else if ([value isKindOfClass:[NSAttributedString class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                       meta->_setter,
                                                                       (meta->_nsType == XLEncodingTypeNSString) ?
                                                                       ((NSAttributedString *)value).string :
                                                                       ((NSAttributedString *)value).string.mutableCopy);
                    }
                } break;
                case XLEncodingTypeNSNumber:{
                    if ([value isKindOfClass:[NSNumber class]]) {
                        if (meta->_nsType == XLEncodingTypeNSNumber) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,meta->_setter,value);
                        }
                    }
                } break;
                case XLEncodingTypeNSArray:
                case XLEncodingTypeNSMutableArray: {
                    if ([value isKindOfClass:[NSArray class]]) {
                        if (meta->_nsType == XLEncodingTypeNSArray) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                           meta->_setter,
                                                                           ((NSArray *)value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSSet class]]) {
                        if (meta->_nsType == XLEncodingTypeNSArray) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSSet *)value).allObjects);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                           meta->_setter,
                                                                           ((NSSet *)value).allObjects.mutableCopy);
                        }
                    }
                } break;
                case XLEncodingTypeNSDictionary:
                case XLEncodingTypeNSMutableDictionary:
                {
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        if (meta->_nsType == XLEncodingTypeNSDictionary) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                           meta->_setter,
                                                                           ((NSDictionary *)value).mutableCopy);
                        }
                    }
                } break;
                    
                default: break;
            }
        }
    }
}

static void ModelSetWithDictionaryFunction(const void *key, const void *value, void *context) {
    ModelSetContext *ctx = context;
    __unsafe_unretained XLModelMeta *modelMeta = (__bridge XLModelMeta *)(ctx->modelMeta);
    __unsafe_unretained XLModelPropertyMeta *propertyMeta = [modelMeta->_mapper objectForKey:(__bridge id)(key)];
    __unsafe_unretained id model = (__bridge id)(ctx->model);
    if (propertyMeta->_setter) {
        ModelSetValueForProperty(model, (__bridge __unsafe_unretained id)value, propertyMeta);
    }
}

@implementation NSObject (XLModel)

+ (instancetype)modelWithJSON:(id)json
{
    NSDictionary * dict = [self dictionaryWithJSON:json];
    if (!dict || dict == (id)kCFNull) {
        return nil;
    }
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    Class cls = [self class];
    NSObject * clsObject = [[cls alloc] init];
    if ([clsObject modelSetWithDictionary:dict]) {
        return clsObject;
    }
    return nil;
}

+ (NSDictionary *)dictionaryWithJSON:(id)json
{
    if (!json || json == (id)kCFNull) {
        return nil;
    }
    
    NSDictionary * dict = nil;
    NSData * data = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dict = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        data = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        data = json;
    }
    if (data) {
        dict = [NSJSONSerialization JSONObjectWithData:data
                                               options:NSJSONReadingMutableLeaves
                                                 error:nil];
        if (![dict isKindOfClass:[NSDictionary class]]) {
            dict = nil;
        }
    }
    return dict;
}

- (BOOL)modelSetWithDictionary:(NSDictionary *)dict
{
    if (!dict || dict == (id)kCFNull) {
        return NO;
    }
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    XLModelMeta * meta = [XLModelMeta metaWithClass:object_getClass(self)];
    if (meta->_keyMappedCount == 0) {
        return NO;
    }
    
    ModelSetContext context = {0};
    context.modelMeta = (__bridge void *)(meta);
    context.model = (__bridge void *)(self);
    context.dictionary = (__bridge void *)(dict);
    if (meta->_keyMappedCount >= dict.count) {
        CFDictionaryApplyFunction((CFDictionaryRef)dict, ModelSetWithDictionaryFunction, &context);
    }
    return YES;
}

@end
