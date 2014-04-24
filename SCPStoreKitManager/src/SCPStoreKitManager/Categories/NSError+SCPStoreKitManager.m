//
//  NSError+SCPStoreKitManager.m
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 10/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import "NSError+SCPStoreKitManager.h"

@implementation NSError (Additions)

+ (NSError *)errorWithDomain:(NSString *)domain code:(SCPErrorCode)code errorDescription:(NSString *)errorDescription errorFailureReason:(NSString *)errorFailureReason errorRecoverySuggestion:(NSString *)errorRecoverySuggestion
{
	NSDictionary *userInfo = @{
							   NSLocalizedDescriptionKey : errorDescription,
							   NSLocalizedFailureReasonErrorKey : errorFailureReason,
							   NSLocalizedRecoverySuggestionErrorKey : errorRecoverySuggestion
							   };
	
	return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

- (NSString *)fullDescription
{
    return [NSString stringWithFormat:@"\nFailure reason : %@\n   Description : %@\n    Suggestion : %@",
            ![[self localizedFailureReason] isEqualToString:@""]  ? [self localizedFailureReason] : @"N/A",
            ![[self localizedDescription] isEqualToString:@""] ? [self localizedDescription] : @"N/A",
            ![[self localizedRecoverySuggestion] isEqualToString:@""] ? [self localizedRecoverySuggestion] : @"N/A"];
}
@end
