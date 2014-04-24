//
//  SCPStoreKitReceiptValidator.h
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 10/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

@import Foundation;
@import StoreKit;

#import "SCPStoreKitReceipt.h"

typedef void(^Success)(SCPStoreKitReceipt *receipt);
typedef void(^Failure)(NSError *error);

@interface SCPStoreKitReceiptValidator : NSObject <SKProductsRequestDelegate, UIAlertViewDelegate>

+ (id)sharedInstance;

- (void)validateReceiptWithBundleIdentifier:(NSString *)bundleIdentifier bundleVersion:(NSString *)bundleVersion tryAgain:(BOOL)tryAgain showReceiptAlert:(BOOL)showReceiptAlert alertViewTitle:(NSString *)alertViewTitle alertViewMessage:(NSString *)alertViewMessage success:(Success)successBlock failure:(Failure)failureBlock;

@end
