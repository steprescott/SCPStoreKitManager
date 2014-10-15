//
//  SCPStoreKitReceiptValidator.m
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 10/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import "SCPStoreKitReceiptValidator.h"
#import "NSError+SCPStoreKitManager.h"

#import "x509.h"


@interface SCPStoreKitReceiptValidator ()

@property (nonatomic, strong) Success successBlock;
@property (nonatomic, strong) Failure failureBlock;

@property (nonatomic, strong) NSString *bundleVersion;
@property (nonatomic, strong) NSString *bundleIdentifier;

@property (nonatomic, assign) BOOL shouldShowReceiptAlert;
@property (nonatomic, strong) NSString *customAlertViewTitle;
@property (nonatomic, strong) NSString *customAlertViewMessage;

@end

@implementation SCPStoreKitReceiptValidator

+ (id)sharedInstance
{
    static SCPStoreKitReceiptValidator *sharedInstance = nil;
	
    static dispatch_once_t onceToken;
	
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
	
    return sharedInstance;
}

- (void)validateReceiptWithBundleIdentifier:(NSString *)bundleIdentifier bundleVersion:(NSString *)bundleVersion tryAgain:(BOOL)tryAgain showReceiptAlert:(BOOL)showReceiptAlert alertViewTitle:(NSString *)alertViewTitle alertViewMessage:(NSString *)alertViewMessage success:(Success)successBlock failure:(Failure)failureBlock
{
	self.successBlock = successBlock;
	self.failureBlock = failureBlock;
	
	self.bundleVersion = bundleVersion;
	self.bundleIdentifier = bundleIdentifier;
    
    self.shouldShowReceiptAlert = showReceiptAlert;
    
    if(alertViewTitle && ![alertViewTitle isEqualToString:@""])
    {
        self.customAlertViewTitle = alertViewTitle;
    }
    
    if(alertViewMessage && ![alertViewMessage isEqualToString:@""])
    {
        self.customAlertViewMessage = alertViewMessage;
    }
	
	NSString *appReceiptPath = [[[NSBundle mainBundle] appStoreReceiptURL] path];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:appReceiptPath])
	{
		//If there is no receipt, we need to request one.
        //Determine if we should show an alert before requesting the receipt
		[self showRequestNewReceiptAlert];
		return;
	}
	
	//See if the current receipt is valid or not
    [self verifyReceiptAtPath:appReceiptPath success:_successBlock failure:^(NSError *error) {

        if(tryAgain)
		{
            //Determine if we should show an alert before requesting the receipt
            [self showRequestNewReceiptAlert];
        }
		else
		{
            if(_failureBlock)
			{
				_failureBlock(error);
			}
			return;
        }
		
	}];
}

- (void)showRequestNewReceiptAlert
{
    //Do we need to show an alert before we ask the user to put in their Apple ID details
    if(_shouldShowReceiptAlert)
    {
        NSString *title = (_customAlertViewTitle) ? _customAlertViewTitle : @"In App purchase receipt";
        NSString *message = (_customAlertViewMessage) ? _customAlertViewMessage : @"We need to request a purchase receipt from Apple. To do this you will be asked to enter your Apple ID details.\n\nDo you want to request the receipt \nto restor purchases?";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
        
        [alertView show];
    }
    else
    {
        //Try one more time to get a valid receipt
        [self requestNewReceipt];
    }
}

- (void)requestNewReceipt
{
    //Begin a request for a receipt from Apple
    SKReceiptRefreshRequest *receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
    [receiptRefreshRequest setDelegate:self];
    [receiptRefreshRequest start];
}

- (void)verifyReceiptAtPath:(NSString *)receiptPath success:(Success)successBlock failure:(Failure)failureBlock
{
	if(![_bundleVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]])
	{
		if(failureBlock)
		{
			NSError *error = [NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodeVersionNumberInvalid errorDescription:@"Version number invalid" errorFailureReason:@"" errorRecoverySuggestion:@"Make sure the passed version number matches that of the info.plist"];
			failureBlock(error);
		}
		return;
	}
	
	if(![_bundleIdentifier isEqualToString:[[NSBundle mainBundle] bundleIdentifier]])
	{
		if(failureBlock)
		{
			NSError *error = [NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodeBundleIdentifierInvalid errorDescription:@"Version bundle identifier" errorFailureReason:@"" errorRecoverySuggestion:@"Make sure the passed bundle identifier matches that of the info.plist"];
			failureBlock(error);
		}
		return;
	}
	
	SCPStoreKitReceipt *receipt = [[SCPStoreKitReceipt alloc] initFromAppStoreReceiptPath:receiptPath];
	
	//If it failed return
	if(!receipt)
	{
		if(failureBlock)
		{
			NSError *error = [NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodeCouldNotParseAppStoreReceipt errorDescription:@"Receipt could not be parsed to a NSDictionary" errorFailureReason:@"" errorRecoverySuggestion:@""];
			failureBlock(error);
		}
		return;
    }
    
	//To further validate get the UUID of the current device
    unsigned char uuidBytes[16];
    NSUUID *vendorUUID = [[UIDevice currentDevice] identifierForVendor];
    [vendorUUID getUUIDBytes:uuidBytes];
    
	//Build up the data in order appending the data from the receipt
	NSMutableData *input = [NSMutableData data];
	[input appendBytes:uuidBytes length:sizeof(uuidBytes)];
	[input appendData:[receipt opaqueValue]];
	[input appendData:[receipt bundleIdentifierData]];
    
	//Hash the data
	NSMutableData *hash = [NSMutableData dataWithLength:SHA_DIGEST_LENGTH];
	SHA1([input bytes], [input length], [hash mutableBytes]);
    
	//Check that the current bundleID, bundleVersion and the Hash is equal to that of the receipt
	if([_bundleIdentifier isEqualToString:[receipt bundleIdentifier]] && [_bundleVersion isEqualToString:[receipt version]] && [hash isEqualToData:[receipt receiptHash]])
	{
		if(successBlock)
		{
			successBlock(receipt);
		}
		return;
	}
    
	//Receipt is not for this device or app
	if(failureBlock)
	{
		NSError *error = [NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodeCouldNotValidateReceipt errorDescription:@"Could not validate receipt" errorFailureReason:@"The receipt is not for this device or app" errorRecoverySuggestion:@""];
		failureBlock(error);
	}
}

#pragma mark - SKRequestDelegate methods

- (void)requestDidFinish:(SKRequest *)request
{
    NSString  *appReceiptPath = [[[NSBundle mainBundle] appStoreReceiptURL] path];
	
    if([[NSFileManager defaultManager] fileExistsAtPath:appReceiptPath])
	{
        [self validateReceiptWithBundleIdentifier:_bundleIdentifier bundleVersion:_bundleVersion tryAgain:NO showReceiptAlert:_shouldShowReceiptAlert alertViewTitle:_customAlertViewTitle alertViewMessage:_customAlertViewMessage success:_successBlock failure:_failureBlock];
    }
	else
	{
		if(_failureBlock)
		{
			NSError *error = [NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodeCouldNotRefreshAppReceipt errorDescription:@"Receipt request complete but there is still no receipt" errorFailureReason:@"This can happen if the user cancels the login screen for the store" errorRecoverySuggestion:@""];
			_failureBlock(error);
		}
    }
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSLog(@"Product response : %@", response);
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSString *appRecPath = [[[NSBundle mainBundle] appStoreReceiptURL] path];
	
    if([[NSFileManager defaultManager] fileExistsAtPath:appRecPath])
	{
		if(_failureBlock)
		{
			NSError *error = [NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodeAppReceiptInvalid errorDescription:@"The existing receipt is invalid" errorFailureReason:@"There is an existing receipt but failed to get a new one" errorRecoverySuggestion:@""];
			_failureBlock(error);
		}
    }
	else
	{
		if(_failureBlock)
		{
			NSError *error = [NSError errorWithDomain:SCPStoreKitDomain code:SCPErrorCodeNoAppReceipt errorDescription:@"There is no existing receipt" errorFailureReason:@"Unable to request a new receipt" errorRecoverySuggestion:@""];
			_failureBlock(error);
		}
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != [alertView cancelButtonIndex])
    {
        [self requestNewReceipt];
    }
}

@end
