//
//  SCPStoreKitIAPReceipt.h
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 12/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCPStoreKitIAPReceipt : NSObject

@property (nonatomic, strong, readonly) NSString *productIdentifier;
@property (nonatomic, strong, readonly) NSNumber *quantity;
@property (nonatomic, strong, readonly) NSDate *cancellationDate;
@property (nonatomic, strong, readonly) NSDate *originalPurchaseDate;
@property (nonatomic, strong, readonly) NSDate *purchaseDate;
@property (nonatomic, strong, readonly) NSString *transactionIdentifier;
@property (nonatomic, strong, readonly) NSString *originalTransactionIdentifier;
@property (nonatomic, strong, readonly) NSDate *subscriptionExpiryDate;
@property (nonatomic, strong, readonly) NSNumber *webItemId;

- (SCPStoreKitIAPReceipt *)initWithData:(NSData *)inAppPurchasesData;

- (NSDictionary *)fullDescription;

@end
