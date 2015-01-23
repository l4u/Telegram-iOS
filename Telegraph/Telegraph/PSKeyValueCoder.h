#import <Foundation/Foundation.h>

#import "PSCoding.h"

typedef enum {
    PSKeyValueCoderFieldTypeString = 1,
    PSKeyValueCoderFieldTypeInt32 = 2,
    PSKeyValueCoderFieldTypeInt64 = 3,
    PSKeyValueCoderFieldTypeCustomClass = 4,
    PSKeyValueCoderFieldTypeArray = 5,
    PSKeyValueCoderFieldTypeData = 6
} PSKeyValueCoderFieldType;

@interface PSKeyValueCoder : NSObject

- (void)encodeString:(NSString *)string forKey:(NSString *)key;
- (void)encodeString:(NSString *)string forCKey:(const char *)key;
- (void)encodeInt32:(int32_t)number forKey:(NSString *)key;
- (void)encodeInt32:(int32_t)number forCKey:(const char *)key;
- (void)encodeInt64:(int64_t)number forKey:(NSString *)key;
- (void)encodeInt64:(int64_t)number forCKey:(const char *)key;
- (void)encodeObject:(id<PSCoding>)object forKey:(NSString *)key;
- (void)encodeObject:(id<PSCoding>)object forCKey:(const char *)key;
- (void)encodeArray:(NSArray *)array forKey:(NSString *)key;
- (void)encodeArray:(NSArray *)array forCKey:(const char *)key;
- (void)encodeData:(NSData *)data forCKey:(const char *)key;

- (NSString *)decodeStringForKey:(NSString *)key;
- (NSString *)decodeStringForCKey:(const char *)key;
- (int32_t)decodeInt32ForKey:(NSString *)key;
- (int32_t)decodeInt32ForCKey:(const char *)key;
- (int64_t)decodeInt64ForKey:(NSString *)key;
- (int64_t)decodeInt64ForCKey:(const char *)key;
- (id<PSCoding>)decodeObjectForKey:(NSString *)key;
- (id<PSCoding>)decodeObjectForCKey:(const char *)key;
- (NSArray *)decodeArrayForKey:(NSString *)key;
- (NSArray *)decodeArrayForCKey:(const char *)key;
- (NSData *)decodeDataCorCKey:(const char *)key;
- (NSDictionary *)decodeObjectsByKeys;

+ (Class<PSCoding>)classForName:(NSString *)name;

@end
