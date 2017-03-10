//
//  XLMeta.m
//  XLNetWorkLibrary
//
//  Created by xl10014 on 2017/3/2.
//  Copyright © 2017年 xl10014. All rights reserved.
//

#import "XLClassInfoMeta.h"


#define force_inline __inline__ __attribute__((always_inline ))

static force_inline XLEncodingNSType XLClassGetNSType(Class cls) {
    if (!cls) {
        return XLEncodingTypeNSUnknown;
    }
    if ([cls isSubclassOfClass:[NSMutableString class]]) {
        return XLEncodingTypeNSMutableString;
    } else if ([cls isSubclassOfClass:[NSString class]]) {
        return XLEncodingTypeNSString;
    } else if ([cls isSubclassOfClass:[NSDecimalNumber class]]) {
        return XLEncodingTypeNSDecimalNumber;
    } else if ([cls isSubclassOfClass:[NSNumber class]]) {
        return XLEncodingTypeNSNumber;
    } else if ([cls isSubclassOfClass:[NSValue class]]) {
        return XLEncodingTypeNSValue;
    } else if ([cls isSubclassOfClass:[NSMutableData class]]) {
        return XLEncodingTypeNSMutableData;
    } else if ([cls isSubclassOfClass:[NSData class]]) {
        return XLEncodingTypeNSData;
    } else if ([cls isSubclassOfClass:[NSDate class]]) {
        return XLEncodingTypeNSDate;
    } else if ([cls isSubclassOfClass:[NSURL class]]) {
        return XLEncodingTypeNSURL;
    } else if ([cls isSubclassOfClass:[NSMutableArray class]]) {
        return XLEncodingTypeNSMutableArray;
    } else if ([cls isSubclassOfClass:[NSArray class]]) {
        return XLEncodingTypeNSArray;
    } else if ([cls isSubclassOfClass:[NSMutableDictionary class]]) {
        return XLEncodingTypeNSMutableDictionary;
    } else if ([cls isSubclassOfClass:[NSDictionary class]]) {
        return XLEncodingTypeNSDictionary;
    } else if ([cls isSubclassOfClass:[NSMutableSet class]]) {
        return XLEncodingTypeNSMutableSet;
    } else if ([cls isSubclassOfClass:[NSSet class]]) {
        return XLEncodingTypeNSSet;
    }
    return XLEncodingTypeNSUnknown;
}

static force_inline BOOL XLEncodingTypeIsCNumber(XLEncodingType type) {
    switch (type & XLEncodingTypeMask) {
        case XLEncodingTypeBool:
        case XLEncodingTypeInt8:
        case XLEncodingTypeUInt8:
        case XLEncodingTypeInt16:
        case XLEncodingTypeUInt16:
        case XLEncodingTypeInt32:
        case XLEncodingTypeUInt32:
        case XLEncodingTypeInt64:
        case XLEncodingTypeUInt64:
        case XLEncodingTypeFloat:
        case XLEncodingTypeDouble:
        case XLEncodingTypeLongDouble:
            return YES;
        default:
            return NO;
    }
}


@implementation XLModelMeta

- (instancetype)initWithClass:(Class)cls
{
    if (!cls) {
        return nil;
    }
    
    if (self = [super init]) {
        XLClassInfo * clsInfo = [XLClassInfo classInfoWithClass:cls];
        NSMutableDictionary * allPropertyMetas = [[NSMutableDictionary alloc] init];
        XLClassInfo * curClsInfo = clsInfo;
        while (curClsInfo && curClsInfo.superClass != nil) {
            for (XLClasssPropertyInfo * propertyInfo in curClsInfo.propertyInfos.allValues) {
                if (!propertyInfo.name.length) {
                    continue;
                }
                XLModelPropertyMeta * meta = [XLModelPropertyMeta modelWithClassInfo:curClsInfo
                                                                        propertyInfo:propertyInfo
                                                                             generic:nil];
                if (!meta || !meta->_name.length) {
                    continue;
                }
                if (!meta->_setter || !meta->_getter) {
                    continue;
                }
                if (allPropertyMetas[meta->_name]) {
                    continue;
                }
                allPropertyMetas[meta->_name] = meta;
            }
            curClsInfo = clsInfo.superClassInfo;
        }
        
        if (allPropertyMetas.count) {
            _allPropertyMetas = allPropertyMetas.allValues.copy;
        }
        NSMutableDictionary * mapper = [[NSMutableDictionary alloc] init];
        [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull name, XLModelPropertyMeta * _Nonnull meta, BOOL * _Nonnull stop) {
            meta->_mappedToKey = name;
            mapper[name] = meta;
        }];
        
        if (mapper.count) {
            _mapper = mapper;
        }
        _clsInfo = clsInfo;
        _keyMappedCount = allPropertyMetas.count;
        _nsType = XLClassGetNSType(cls);
    }
    return self;
}

+ (instancetype)metaWithClass:(Class)cls
{
    if (!cls) {
        return nil;
    }
    
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    XLModelMeta * meta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    
    if (!meta || meta->_clsInfo.bIsNeedUpdate) {
        meta = [[XLModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache,  (__bridge const void *)(cls), (__bridge const void *)(meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}

@end

@implementation XLModelPropertyMeta
+ (instancetype)modelWithClassInfo:(XLClassInfo *)clsInfo propertyInfo:(XLClasssPropertyInfo *)propertyInfo generic:(Class)generic
{
    XLModelPropertyMeta * meta = [[self alloc] init];
    meta->_name = propertyInfo.name;
    meta->_type = propertyInfo.type;
    meta->_info = propertyInfo;
    meta->_genericCls = generic;
    
    if ((meta->_type & XLEncodingTypeMask) == XLEncodingTypeObject) {
        meta->_nsType = XLClassGetNSType(propertyInfo.cls);
    } else {
        meta->_isCNumber = XLEncodingTypeIsCNumber(meta->_type);
    }
    meta->_cls = propertyInfo.cls;
    if (propertyInfo.getter) {
        if ([clsInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
            meta->_getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([clsInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
            meta->_setter = propertyInfo.setter;
        }
    }
    
    if (meta->_setter && meta->_getter) {
        switch (meta->_type & XLEncodingTypeMask) {
            case XLEncodingTypeBool:
            case XLEncodingTypeInt8:
            case XLEncodingTypeUInt8:
            case XLEncodingTypeInt16:
            case XLEncodingTypeUInt16:
            case XLEncodingTypeInt32:
            case XLEncodingTypeUInt32:
            case XLEncodingTypeInt64:
            case XLEncodingTypeUInt64:
            case XLEncodingTypeFloat:
            case XLEncodingTypeDouble:
            case XLEncodingTypeObject:
            case XLEncodingTypeClass:
            case XLEncodingTypeBlock:
            case XLEncodingTypeStruct:
            case XLEncodingTypeUnion:
            {
                meta->_isKVCCompatible = YES;
            }
                break;
            default:
                break;
        }
    }
    return meta;
}

@end
