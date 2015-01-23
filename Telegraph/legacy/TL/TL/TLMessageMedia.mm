#import "TLMessageMedia.h"

#import "../NSInputStream+TL.h"
#import "../NSOutputStream+TL.h"

#import "TLPhoto.h"
#import "TLVideo.h"
#import "TLGeoPoint.h"
#import "TLDocument.h"
#import "TLAudio.h"

@implementation TLMessageMedia


- (int32_t)TLconstructorSignature
{
    TGLog(@"constructorSignature is not implemented for base type");
    return 0;
}

- (int32_t)TLconstructorName
{
    TGLog(@"constructorName is not implemented for base type");
    return 0;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)__unused metaObject
{
    TGLog(@"TLbuildFromMetaObject is not implemented for base type");
    return nil;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
    TGLog(@"TLfillFieldsWithValues is not implemented for base type");
}


@end

@implementation TLMessageMedia$messageMediaEmpty : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x3ded6320;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xfb752ca9;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)__unused metaObject
{
    TLMessageMedia$messageMediaEmpty *object = [[TLMessageMedia$messageMediaEmpty alloc] init];
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)__unused values
{
}


@end

@implementation TLMessageMedia$messageMediaPhoto : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0xc8c45a2a;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x77fb40e5;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)metaObject
{
    TLMessageMedia$messageMediaPhoto *object = [[TLMessageMedia$messageMediaPhoto alloc] init];
    object.photo = metaObject->getObject((int32_t)0xe6c52372);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.photo;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xe6c52372, value));
    }
}


@end

@implementation TLMessageMedia$messageMediaVideo : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0xa2d24290;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x508c8007;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)metaObject
{
    TLMessageMedia$messageMediaVideo *object = [[TLMessageMedia$messageMediaVideo alloc] init];
    object.video = metaObject->getObject((int32_t)0x2182fe3c);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.video;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x2182fe3c, value));
    }
}


@end

@implementation TLMessageMedia$messageMediaGeo : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x56e0d474;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x7f81253;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)metaObject
{
    TLMessageMedia$messageMediaGeo *object = [[TLMessageMedia$messageMediaGeo alloc] init];
    object.geo = metaObject->getObject((int32_t)0x3c803e05);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.geo;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x3c803e05, value));
    }
}


@end

@implementation TLMessageMedia$messageMediaContact : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x5e7d2f39;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xbe4c9bee;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)metaObject
{
    TLMessageMedia$messageMediaContact *object = [[TLMessageMedia$messageMediaContact alloc] init];
    object.phone_number = metaObject->getString((int32_t)0xaecb6c79);
    object.first_name = metaObject->getString((int32_t)0xa604f05d);
    object.last_name = metaObject->getString((int32_t)0x10662e0e);
    object.user_id = metaObject->getInt32((int32_t)0xafdf4073);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeString;
        value.nativeObject = self.phone_number;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xaecb6c79, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeString;
        value.nativeObject = self.first_name;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xa604f05d, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeString;
        value.nativeObject = self.last_name;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x10662e0e, value));
    }
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypePrimitiveInt32;
        value.primitive.int32Value = self.user_id;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xafdf4073, value));
    }
}


@end

@implementation TLMessageMedia$messageMediaUnsupported : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x29632a36;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x8bdaec28;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)metaObject
{
    TLMessageMedia$messageMediaUnsupported *object = [[TLMessageMedia$messageMediaUnsupported alloc] init];
    object.bytes = metaObject->getBytes((int32_t)0xec5ef20a);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeBytes;
        value.nativeObject = self.bytes;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xec5ef20a, value));
    }
}


@end

@implementation TLMessageMedia$messageMediaDocument : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0x2fda2204;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0x224d0678;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)metaObject
{
    TLMessageMedia$messageMediaDocument *object = [[TLMessageMedia$messageMediaDocument alloc] init];
    object.document = metaObject->getObject((int32_t)0xf1465b5f);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.document;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0xf1465b5f, value));
    }
}


@end

@implementation TLMessageMedia$messageMediaAudio : TLMessageMedia


- (int32_t)TLconstructorSignature
{
    return (int32_t)0xc6b68300;
}

- (int32_t)TLconstructorName
{
    return (int32_t)0xd601e60a;
}

- (id<TLObject>)TLbuildFromMetaObject:(std::tr1::shared_ptr<TLMetaObject>)metaObject
{
    TLMessageMedia$messageMediaAudio *object = [[TLMessageMedia$messageMediaAudio alloc] init];
    object.audio = metaObject->getObject((int32_t)0x88cc1b1);
    return object;
}

- (void)TLfillFieldsWithValues:(std::map<int32_t, TLConstructedValue> *)values
{
    {
        TLConstructedValue value;
        value.type = TLConstructedValueTypeObject;
        value.nativeObject = self.audio;
        values->insert(std::pair<int32_t, TLConstructedValue>((int32_t)0x88cc1b1, value));
    }
}


@end

