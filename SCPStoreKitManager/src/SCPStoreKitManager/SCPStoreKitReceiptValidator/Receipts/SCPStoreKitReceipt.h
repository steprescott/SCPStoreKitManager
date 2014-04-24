//
//  SCPStoreKitReceipt.h
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 12/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SCPStoreKitIAPReceipt.h"

@interface SCPStoreKitReceipt : NSObject

@property (nonatomic, strong, readonly) NSString *bundleIdentifier;
@property (nonatomic, strong, readonly) NSData *bundleIdentifierData;
@property (nonatomic, strong, readonly) NSData *hash;
@property (nonatomic, strong, readonly) NSData *opaqueValue;
@property (nonatomic, strong, readonly) NSString *originalVersion;
@property (nonatomic, strong, readonly) NSString *version;

@property (nonatomic, strong, readonly) NSMutableArray *inAppPurchases;

- (SCPStoreKitReceipt *)initFromAppStoreReceiptPath:(NSString *)receiptPath;

- (NSDictionary *)fullDescription;

@end
