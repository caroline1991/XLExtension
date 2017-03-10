//
//  XLClassInfo.h
//  XLNetWorkLibrary
//
//  Created by xl10014 on 2017/3/2.
//  Copyright © 2017年 xl10014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Type encoding's type.
 */
typedef NS_OPTIONS(NSUInteger, XLEncodingType) {
    XLEncodingTypeMask       = 0xFF, ///< mask of type value
    XLEncodingTypeUnknown    = 0, ///< unknown
    XLEncodingTypeVoid       = 1, ///< void
    XLEncodingTypeBool       = 2, ///< bool
    XLEncodingTypeInt8       = 3, ///< char / BOOL
    XLEncodingTypeUInt8      = 4, ///< unsigned char
    XLEncodingTypeInt16      = 5, ///< short
    XLEncodingTypeUInt16     = 6, ///< unsigned short
    XLEncodingTypeInt32      = 7, ///< int
    XLEncodingTypeUInt32     = 8, ///< unsigned int
    XLEncodingTypeInt64      = 9, ///< long long
    XLEncodingTypeUInt64     = 10, ///< unsigned long long
    XLEncodingTypeFloat      = 11, ///< float
    XLEncodingTypeDouble     = 12, ///< double
    XLEncodingTypeLongDouble = 13, ///< long double
    XLEncodingTypeObject     = 14, ///< id
    XLEncodingTypeClass      = 15, ///< Class
    XLEncodingTypeSEL        = 16, ///< SEL
    XLEncodingTypeBlock      = 17, ///< block
    XLEncodingTypePointer    = 18, ///< void*
    XLEncodingTypeStruct     = 19, ///< struct
    XLEncodingTypeUnion      = 20, ///< union
    XLEncodingTypeCString    = 21, ///< char*
    XLEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    XLEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    XLEncodingTypeQualifierConst  = 1 << 8,  ///< const
    XLEncodingTypeQualifierIn     = 1 << 9,  ///< in
    XLEncodingTypeQualifierInout  = 1 << 10, ///< inout
    XLEncodingTypeQualifierOut    = 1 << 11, ///< out
    XLEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    XLEncodingTypeQualifierByref  = 1 << 13, ///< byref
    XLEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    XLEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    XLEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    XLEncodingTypePropertyCopy         = 1 << 17, ///< copy
    XLEncodingTypePropertyRetain       = 1 << 18, ///< retain
    XLEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    XLEncodingTypePropertyWeak         = 1 << 20, ///< weak
    XLEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    XLEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    XLEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};

XLEncodingType encodingGetType(const char *typeEncoding);


@interface XLClasssPropertyInfo : NSObject

@property (nonatomic, assign, readonly) objc_property_t property;
@property (nonatomic, strong, readonly) NSString * name;
@property (nonatomic, assign, readonly) XLEncodingType type;
@property (nonatomic, strong, readonly) NSString * typeEncoding;
@property (nonatomic, strong, readonly) NSString * ivarName;
@property (nullable, nonatomic, assign, readonly) Class cls;
@property (nonatomic, assign, readonly) SEL getter;
@property (nonatomic, assign, readonly) SEL setter;

- (instancetype)initWithProperty:(objc_property_t)property;

@end

@interface XLClassMethodInfo : NSObject

@property (nonatomic, assign, readonly) Method method;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, assign, readonly) SEL sel;
@property (nonatomic, assign, readonly) IMP imp;
@property (nonatomic, strong, readonly) NSString *typeEncoding;
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;
@property (nullable,nonatomic, strong, readonly) NSArray <NSString *> *argumentTypeEncodings; //all arguments type encoding

- (instancetype)initWithMethod:(Method)method;

@end

@interface XLClassIvarInfo : NSObject

@property (nonatomic, assign, readonly) Ivar ivar;
@property (nonatomic, strong, readonly) NSString * name;
@property (nonatomic, strong, readonly) NSString * typeEncoding;
@property (nonatomic, assign, readonly) XLEncodingType type;


-(instancetype)initWithIvar:(Ivar)ivar;

@end

@interface XLClassInfo : NSObject

@property (nonatomic, assign, readonly) Class cls;
@property (nonatomic, assign, readonly) Class superClass;
@property (nonatomic, assign, readonly) Class metaClass;
@property (nonatomic, readonly) BOOL isMeta;
@property (nonatomic, strong, readonly) NSString * name;
@property (nullable, nonatomic, strong, readonly) XLClassInfo * superClassInfo;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *,XLClassIvarInfo *>*ivarInfos;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *,XLClassMethodInfo *>*methodInfos;
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *,XLClasssPropertyInfo *>*propertyInfos;

- (void)setNeedUpdate;
- (BOOL)bIsNeedUpdate;
+ (nullable instancetype)classInfoWithClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
