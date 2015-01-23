/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import <Foundation/Foundation.h>

typedef enum {
    TGUserSexUnknown = 0,
    TGUserSexMale = 1,
    TGUserSexFemale = 2
} TGUserSex;

typedef enum {
    TGUserPresenceValueLately = -2,
    TGUserPresenceValueWithinAWeek = -3,
    TGUserPresenceValueWithinAMonth = -4,
    TGUserPresenceValueALongTimeAgo = -5
} TGUserPresenceValue;

typedef struct {
    bool online;
    int lastSeen;
    int temporaryLastSeen;
} TGUserPresence;

typedef enum {
    TGUserLinkKnown = 1,
    TGUserLinkForeignRequested = 2,
    TGUserLinkForeignMutual = 4,
    TGUserLinkMyRequested = 8,
    TGUserLinkMyContact = 16,
    TGUserLinkForeignHasPhone = 32
} TGUserLink;

typedef enum {
    TGUserFieldUid = 1,
    TGUserFieldPhoneNumber = 2,
    TGUserFieldPhoneNumberHash = 4,
    TGUserFieldFirstName = 8,
    TGUserFieldLastName = 16,
    TGUserFieldPhonebookFirstName = 32,
    TGUserFieldPhonebookLastName = 64,
    TGUserFieldSex = 128,
    TGUserFieldPhotoUrlSmall = 256,
    TGUserFieldPhotoUrlMedium = 512,
    TGUserFieldPhotoUrlBig = 1024,
    TGUserFieldPresenceLastSeen = 2048,
    TGUserFieldPresenceOnline = 4096,
    TGUserFieldUsername = 8192
} TGUserFields;

@class TGNotificationPrivacyAccountSetting;

#define TGUserFieldsAllButPresenceMask (TGUserFieldUid | TGUserFieldPhoneNumber | TGUserFieldPhoneNumberHash | TGUserFieldFirstName| TGUserFieldLastName | TGUserFieldPhonebookFirstName | TGUserFieldPhonebookLastName | TGUserFieldSex | TGUserFieldPhotoUrlSmall | TGUserFieldPhotoUrlMedium | TGUserFieldPhotoUrlBig)

@interface TGUser : NSObject

@property (nonatomic) int uid;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic) int64_t phoneNumberHash;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *phonebookFirstName;
@property (nonatomic, strong) NSString *phonebookLastName;
@property (nonatomic) TGUserSex sex;
@property (nonatomic) NSString *photoUrlSmall;
@property (nonatomic) NSString *photoUrlMedium;
@property (nonatomic) NSString *photoUrlBig;

@property (nonatomic) TGUserPresence presence;

@property (nonatomic) int contactId;

@property (nonatomic, strong) NSDictionary *customProperties;

- (id)copyWithZone:(NSZone *)zone;

- (bool)hasAnyName;

- (NSString *)realFirstName;
- (NSString *)realLastName;

- (NSString *)displayName;
- (NSString *)displayRealName;
- (NSString *)displayFirstName;
- (NSString *)compactName;

- (NSString *)formattedPhoneNumber;

- (bool)isEqualToUser:(TGUser *)anotherUser;
- (int)differenceFromUser:(TGUser *)anotherUser;

+ (TGUserPresence)approximatePresenceFromPresence:(TGUserPresence)presence currentTime:(NSTimeInterval)currentTime;
- (TGUser *)applyPrivacyRules:(TGNotificationPrivacyAccountSetting *)privacyRules currentTime:(NSTimeInterval)currentTime;

@end
