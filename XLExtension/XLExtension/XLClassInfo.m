//
//  XLClassInfo.m
//  XLNetWorkLibrary
//
//  Created by xl10014 on 2017/3/2.
//  Copyright © 2017年 xl10014. All rights reserved.
//

#import "XLClassInfo.h"

XLEncodingType encodingGetType(const char *typeEncoding)
{
    char *type = (char *)typeEncoding;
    if (!type) {
        return XLEncodingTypeUnknown;
    }
    size_t length = strlen(type);
    if (length== 0) {
        return XLEncodingTypeUnknown;
    }
    
    XLEncodingType qualifier = 0;
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r':
                qualifier |= XLEncodingTypeQualifierConst;
                break;
            case 'n':
                qualifier |= XLEncodingTypeQualifierIn;
                type++;
                break;
            case 'N': {
                qualifier |= XLEncodingTypeQualifierInout;
                type++;
            } break;
            case 'o': {
                qualifier |= XLEncodingTypeQualifierOut;
                type++;
            } break;
            case 'O': {
                qualifier |= XLEncodingTypeQualifierBycopy;
                type++;
            } break;
            case 'R': {
                qualifier |= XLEncodingTypeQualifierByref;
                type++;
            } break;
            case 'V': {
                qualifier |= XLEncodingTypeQualifierOneway;
                type++;
            } break;
            default: {
                prefix = false;
            }
                break;
        }
    }
    
    length = strlen(type);
    if (length == 0) {
        return XLEncodingTypeUnknown | qualifier;
    }
    
    switch (*type) {
        case 'v': return XLEncodingTypeVoid | qualifier;
        case 'B': return XLEncodingTypeBool | qualifier;
        case 'c': return XLEncodingTypeInt8 | qualifier;
        case 'C': return XLEncodingTypeUInt8 | qualifier;
        case 's': return XLEncodingTypeInt16 | qualifier;
        case 'S': return XLEncodingTypeUInt16 | qualifier;
        case 'i': return XLEncodingTypeInt32 | qualifier;
        case 'I': return XLEncodingTypeUInt32 | qualifier;
        case 'l': return XLEncodingTypeInt32 | qualifier;
        case 'L': return XLEncodingTypeUInt32 | qualifier;
        case 'q': return XLEncodingTypeInt64 | qualifier;
        case 'Q': return XLEncodingTypeUInt64 | qualifier;
        case 'f': return XLEncodingTypeFloat | qualifier;
        case 'd': return XLEncodingTypeDouble | qualifier;
        case 'D': return XLEncodingTypeLongDouble | qualifier;
        case '#': return XLEncodingTypeClass | qualifier;
        case ':': return XLEncodingTypeSEL | qualifier;
        case '*': return XLEncodingTypeCString | qualifier;
        case '^': return XLEncodingTypePointer | qualifier;
        case '[': return XLEncodingTypeCArray | qualifier;
        case '(': return XLEncodingTypeUnion | qualifier;
        case '{': return XLEncodingTypeStruct | qualifier;
        case '@': {
            if (length == 2 && *(type + 1) == '?')
                return XLEncodingTypeBlock | qualifier;
            else
                return XLEncodingTypeObject | qualifier;
        }
        default: return XLEncodingTypeUnknown | qualifier;
    }
}

@implementation XLClasssPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property
{
    if (self = [super init]) {
        _property = property;
        const char * name = property_getName(property);
        if (name) {
            _name = [NSString stringWithUTF8String:name];
        }
        
        XLEncodingType type = 0;
        unsigned int outCount;
        objc_property_attribute_t * attrs = property_copyAttributeList(property, &outCount);
        //拿到属性括号内部的所有声明类型 例如:nonatomic, assign,weak等等
        for (unsigned int i = 0; i < outCount; i++) {
            switch (attrs[i].name[0]) {
                case 'T':
                {
                    if (attrs[i].value) {
                        _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                        type = encodingGetType(attrs[i].value);
                        //如果该类型是一个对象 例如@"NSArray",截取中间的NSArray,这样就可以得到这个类的class
                        if ((type & XLEncodingTypeMask) == XLEncodingTypeObject){
                            size_t length = strlen(attrs[i].value);
                            if (length > 3) {
                                char name[length - 2];
                                name[length - 3] = '\0';
                                memcpy(name, attrs[i].value + 2 ,length - 3);
                                _cls = objc_getClass(name);
                            }
                        }
                    }
                }
                    break;
                case 'V':
                {
                    if (attrs[i].value) {
                        _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                    }
                }
                    break;
                case 'R':
                {
                    type |= XLEncodingTypePropertyReadonly;
                }
                    break;
                case 'C':
                {
                    type |= XLEncodingTypePropertyCopy;
                }
                    break;
                case '&':
                {
                    type |= XLEncodingTypePropertyRetain;
                }
                    break;
                case  'N':
                {
                    type |= XLEncodingTypePropertyNonatomic;
                }
                    break;
                case 'D':
                {
                    type |= XLEncodingTypePropertyDynamic;
                }
                    break;
                case 'W':
                {
                    type |= XLEncodingTypePropertyWeak;
                }
                    break;
                case  'G':
                {
                    type |= XLEncodingTypePropertyCustomGetter;
                    if (attrs[i].value) {
                        _getter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                    }
                }
                    break;
                case 'S':
                {
                    type |= XLEncodingTypePropertyCustomSetter;
                    if (attrs[i].value) {
                        _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                    }
                }
                    break;
                default:
                    break;
            }
        }
        if (attrs) {
            free(attrs);
            attrs = NULL;
        }
        
        _type = type;
        if (_name.length) {
            if (!_getter) {
                _getter = NSSelectorFromString(_name);
            }
            if (!_setter) {
                _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",[_name substringToIndex:1].uppercaseString,[_name substringFromIndex:1]]);
            }
        }
    }
    return self;
}

@end

@implementation XLClassMethodInfo

-(instancetype)initWithMethod:(Method)method
{
    if (self = [super init]) {
        _method = method;
        _sel = method_getName(method);
        _imp = method_getImplementation(method);
        const char * name = sel_getName(_sel);
        if (name) {
            _name = [NSString stringWithUTF8String:name];
        }
        const char * typeEncoding = method_getTypeEncoding(method);
        if (typeEncoding) {
            _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
        }
        char * returnTypeEncoding = method_copyReturnType(method);
        if (returnTypeEncoding) {
            _returnTypeEncoding = [NSString stringWithUTF8String:returnTypeEncoding];
            free(returnTypeEncoding);
        }
        
        unsigned int paramsCount = method_getNumberOfArguments(method);
        NSMutableArray * paramsArray = [[NSMutableArray alloc] init];
        for (unsigned int i = 0 ; i < paramsCount; i++) {
            char * argumentsType = method_copyArgumentType(method, i);
            NSString * type = argumentsType ? [NSString stringWithUTF8String:argumentsType] : nil;
            [paramsArray addObject:type ? type : @""];
            if (argumentsType) {
                free(argumentsType);
            }
        }
        _argumentTypeEncodings = paramsArray;
    }
    return self;
}

@end

@implementation XLClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar
{
    if (self = [super init]) {
        _ivar = ivar;
        if (ivar_getName(ivar)) {
            _name = [NSString stringWithUTF8String:ivar_getName(ivar)];
        }
        const char  * typeEncoding = ivar_getTypeEncoding(ivar);
        if (typeEncoding) {
            _typeEncoding = [NSString stringWithUTF8String:typeEncoding];
            _type = encodingGetType(typeEncoding);
        }
    }
    return self;
}

@end


@implementation XLClassInfo
{
    BOOL _needUpdate;
}

- (instancetype)initWithClass:(Class)cls
{
    if (self = [super init]) {
        _cls = cls;
        _superClass = class_getSuperclass(cls);
        _isMeta = class_isMetaClass(cls);
        if (_isMeta) {
            _metaClass = objc_getMetaClass(class_getName(cls));
        }
        _name = NSStringFromClass(cls);
        [self update];
        _superClassInfo = [self.class classInfoWithClass:_superClass];
    }

    return self;
}

- (void)update
{
    _ivarInfos = nil;
    _propertyInfos = nil;
    _methodInfos = nil;
    unsigned int ivarCount = 0;
    Ivar * ivars = class_copyIvarList(self.cls, &ivarCount);
    if (ivars) {
        _ivarInfos = [[NSMutableDictionary alloc] init];
        for (unsigned int i = 0; i < ivarCount; i++) {
            XLClassIvarInfo * ivar = [[XLClassIvarInfo alloc] initWithIvar:ivars[i]];
            if (ivar.name.length) {
                [_ivarInfos setValue:ivar forKey:ivar.name];
            }
        }
        free(ivars);
    }

    unsigned int propertyCount = 0;
    objc_property_t * properties = class_copyPropertyList(self.cls, &propertyCount);
    if (properties) {
        _propertyInfos = [[NSMutableDictionary alloc] init];
        for (unsigned int i = 0; i < propertyCount; i++) {
            XLClasssPropertyInfo * property = [[XLClasssPropertyInfo alloc] initWithProperty:properties[i]];
            if (property.name.length) {
                [_propertyInfos setValue:property forKey:property.name];
            }
        }
        free(properties);
    }
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(self.cls, &methodCount);
    if (methods) {
        _methodInfos = [[NSMutableDictionary alloc] init];
        for (unsigned int i = 0; i < methodCount; i++) {
            XLClassMethodInfo * method = [[XLClassMethodInfo alloc] initWithMethod:methods[i]];
            if (method.name.length) {
                [_methodInfos setValue:method forKey:method.name];
            }
        }
        free(methods);
    }
    
    if (!_ivarInfos) {
        _ivarInfos = @{};
    }
    if (!_methodInfos) {
        _methodInfos = @{};
    }
    if (!_propertyInfos) {
        _propertyInfos = @{};
    }
    _needUpdate = NO;
}

- (BOOL)bIsNeedUpdate
{
    return _needUpdate;
}

- (void)setNeedUpdate
{
    _needUpdate = YES;
}

+ (instancetype)classInfoWithClass:(Class)cls
{
    if (!cls) {
        return nil;
    }
    
    static NSMutableDictionary * metaCache = nil;
    static NSMutableDictionary * classCache = nil;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        metaCache = [[NSMutableDictionary alloc] init];
        classCache = [[NSMutableDictionary alloc] init];
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    XLClassInfo *info = nil;
    if (class_isMetaClass(cls)) {
        info = [metaCache valueForKey:NSStringFromClass(cls)];
    } else {
        info = [classCache valueForKey:NSStringFromClass(cls)];
    }
    if (info && info->_needUpdate) {
        [info update];
    }
    dispatch_semaphore_signal(lock);
    if (!info) {
        info = [[XLClassInfo alloc] initWithClass:cls];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            if (info.isMeta) {
                [metaCache setValue:info forKey:NSStringFromClass(cls)];
            } else {
                [classCache setValue:info forKey:NSStringFromClass(cls)];
            }
            dispatch_semaphore_signal(lock);
        }
    }
    return info;
}
@end
