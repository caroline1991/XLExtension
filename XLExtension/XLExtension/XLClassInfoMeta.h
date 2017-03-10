//
//  XLMeta.h
//  XLNetWorkLibrary
//
//  Created by xl10014 on 2017/3/2.
//  Copyright © 2017年 xl10014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLClassInfo.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, XLEncodingNSType) {
    XLEncodingTypeNSUnknown = 0,
    XLEncodingTypeNSString,
    XLEncodingTypeNSMutableString,
    XLEncodingTypeNSValue,
    XLEncodingTypeNSNumber,
    XLEncodingTypeNSDecimalNumber,
    XLEncodingTypeNSData,
    XLEncodingTypeNSMutableData,
    XLEncodingTypeNSDate,
    XLEncodingTypeNSURL,
    XLEncodingTypeNSArray,
    XLEncodingTypeNSMutableArray,
    XLEncodingTypeNSDictionary,
    XLEncodingTypeNSMutableDictionary,
    XLEncodingTypeNSSet,
    XLEncodingTypeNSMutableSet
};

@interface XLModelMeta : NSObject {
    @package
    XLClassInfo * _clsInfo;
    NSDictionary * _mapper;
    NSArray * _allPropertyMetas; //properties of storage class and parent class
    NSUInteger _keyMappedCount;
    XLEncodingNSType _nsType;
}

+ (instancetype)metaWithClass:(Class)cls;

@end


@interface XLModelPropertyMeta : NSObject {
    @package
    NSString * _name;
    XLEncodingType _type;
    XLEncodingNSType _nsType;
    BOOL _isCNumber;  //is the type of the C language
    Class _cls;
    Class _genericCls;
    SEL _getter;
    SEL _setter;
    BOOL _isKVCCompatible; //can not support KVC
    NSString * _mappedToKey;
    XLClasssPropertyInfo * _info;
}


+ (instancetype)modelWithClassInfo:(XLClassInfo *)clsInfo
                      propertyInfo:(XLClasssPropertyInfo *)propertyInfo
                           generic:(Class)generic;

@end

