//
//  NSError+SCPStoreKitManager.h
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 10/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

@import Foundation;

static NSString *SCPStoreKitDomain = @"SCPStoreKitDomain";

typedef NS_ENUM(NSInteger, SCPErrorCode) {
	SCPErrorCodePaymentQueueCanNotMakePayments = 0,
	SCPErrorCodeVersionNumberInvalid,
	SCPErrorCodeBundleIdentifierInvalid,
	SCPErrorCodeCouldNotParseAppStoreReceipt,
	SCPErrorCodeCouldNotValidateReceipt,
	SCPErrorCodeCouldNotRefreshAppReceipt,
	SCPErrorCodeCouldNotLoadAppleRootCertificate,
	SCPErrorCodeInvalidApplicationReceiptSignature,
	SCPErrorCodeNoAppReceipt,
	SCPErrorCodeAppReceiptInvalid,
};

@interface NSError (Additions)

//Helper method to ease creation of an error by not having to remember the keys for the user info dictionary
+ (NSError *)errorWithDomain:(NSString *)domain code:(SCPErrorCode)code errorDescription:(NSString *)errorDescription errorFailureReason:(NSString *)errorFailureReason errorRecoverySuggestion:(NSString *)errorRecoverySuggestion;

//Helper method to return the full description of an NSError as one string
- (NSString *)fullDescription;

@end
