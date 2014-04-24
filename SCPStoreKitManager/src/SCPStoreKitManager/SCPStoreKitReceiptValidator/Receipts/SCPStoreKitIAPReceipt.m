//
//  SCPStoreKitIAPReceipt.m
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 12/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import "SCPStoreKitIAPReceipt.h"

#import "asn1.h"

typedef NS_ENUM(NSInteger, SCPAppReceiptASN1TypeIAP)
{
	SCPAppReceiptASN1TypeIAPAttributeStart = 1700,
	SCPAppReceiptASN1TypeIAPQuantity = 1701,
	SCPAppReceiptASN1TypeIAPProductIdentifier = 1702,
	SCPAppReceiptASN1TypeIAPTransactionIdentifier = 1703,
	SCPAppReceiptASN1TypeIAPPurchaseDate = 1704,
	SCPAppReceiptASN1TypeIAPOriginalTransactionIdentifier = 1705,
	SCPAppReceiptASN1TypeIAPOriginalPurchaseDate = 1706,
	SCPAppReceiptASN1TypeIAPAttributeEnd = 1707,
	SCPAppReceiptASN1TypeIAPSubscriptionExpirationDate = 1708,
	SCPAppReceiptASN1TypeIAPWebOrderLineItemID = 1711,
	SCPAppReceiptASN1TypeIAPCancellationDate = 1712
};

@interface SCPStoreKitIAPReceipt ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) NSString *productIdentifier;
@property (nonatomic, strong) NSNumber *quantity;
@property (nonatomic, strong) NSDate *cancellationDate;
@property (nonatomic, strong) NSDate *originalPurchaseDate;
@property (nonatomic, strong) NSDate *purchaseDate;
@property (nonatomic, strong) NSString *transactionIdentifier;
@property (nonatomic, strong) NSString *originalTransactionIdentifier;
@property (nonatomic, strong) NSDate *subscriptionExpiryDate;
@property (nonatomic, strong) NSNumber *webItemId;

@end

@implementation SCPStoreKitIAPReceipt

- (SCPStoreKitIAPReceipt *)initWithData:(NSData *)inAppPurchasesData
{
	int type = 0;
	int xclass = 0;
	long length = 0;
    
	NSUInteger dataLenght = [inAppPurchasesData length];
	const uint8_t *p = [inAppPurchasesData bytes];
    
	const uint8_t *end = p + dataLenght;
    
	SCPStoreKitIAPReceipt *iapReceipt = [[SCPStoreKitIAPReceipt alloc] init];
	
    self.dateFormatter = [[NSDateFormatter alloc] init];
	[_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	[_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
	
	while (p < end)
	{
		ASN1_get_object(&p, &length, &type, &xclass, end - p);
        
		const uint8_t *set_end = p + length;
        
		if(type != V_ASN1_SET)
		{
			break;
		}
        
		while (p < set_end)
		{
			ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
			
			if(type != V_ASN1_SEQUENCE)
			{
				break;
            }
            
			const uint8_t *seq_end = p + length;
            
			int attr_type = 0;
			int attr_version = 0;
            
			//Attribute type
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			
			if(type == V_ASN1_INTEGER)
			{
				if(length == 1)
				{
					attr_type = p[0];
				}
				else if(length == 2)
				{
					attr_type = p[0] * 0x100 + p[1];
				}
			}
			
			p += length;
            
			//Attribute version
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			
			if(type == V_ASN1_INTEGER && length == 1)
			{
				attr_version = p[0];
			}
			
			p += length;
            
			//Only parse attributes we're interested in
			if((attr_type > SCPAppReceiptASN1TypeIAPAttributeStart && attr_type < SCPAppReceiptASN1TypeIAPAttributeEnd) || attr_type == SCPAppReceiptASN1TypeIAPSubscriptionExpirationDate || attr_type == SCPAppReceiptASN1TypeIAPWebOrderLineItemID || attr_type == SCPAppReceiptASN1TypeIAPCancellationDate)
			{
				ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
				
				if(type == V_ASN1_OCTET_STRING)
				{
					//Integers
					if(attr_type == SCPAppReceiptASN1TypeIAPQuantity || attr_type == SCPAppReceiptASN1TypeIAPWebOrderLineItemID)
					{
						int num_type = 0;
						long num_length = 0;
						const uint8_t *num_p = p;
						ASN1_get_object(&num_p, &num_length, &num_type, &xclass, seq_end - num_p);
						
						if(num_type == V_ASN1_INTEGER)
						{
							NSUInteger quantity = 0;
							if(num_length)
							{
								quantity += num_p[0];
								
								if(num_length > 1)
								{
									quantity += num_p[1] * 0x100;
									
									if(num_length > 2)
									{
										
										quantity += num_p[2] * 0x10000;
										
										if(num_length > 3)
										{
											quantity += num_p[3] * 0x1000000;
										}
									}
								}
							}
                            
							NSNumber *number = [[NSNumber alloc] initWithUnsignedInteger:quantity];
							
                            if(attr_type == SCPAppReceiptASN1TypeIAPQuantity)
							{
								[iapReceipt setQuantity:number];
                            }
							else if(attr_type == SCPAppReceiptASN1TypeIAPWebOrderLineItemID)
							{
								[iapReceipt setWebItemId:number];
                            }
						}
					}
                    
					//Strings
					if(attr_type == SCPAppReceiptASN1TypeIAPProductIdentifier || attr_type == SCPAppReceiptASN1TypeIAPTransactionIdentifier || attr_type == SCPAppReceiptASN1TypeIAPOriginalTransactionIdentifier || attr_type == SCPAppReceiptASN1TypeIAPPurchaseDate || attr_type == SCPAppReceiptASN1TypeIAPOriginalPurchaseDate || attr_type == SCPAppReceiptASN1TypeIAPSubscriptionExpirationDate || attr_type == SCPAppReceiptASN1TypeIAPCancellationDate)
					{
                        
						int str_type = 0;
						long str_length = 0;
						const uint8_t *str_p = p;
						ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
						
						if(str_type == V_ASN1_UTF8STRING)
						{
							NSString *string = [[NSString alloc] initWithBytes:str_p
																		length:(NSUInteger)str_length
																	  encoding:NSUTF8StringEncoding];
							
							switch (attr_type)
							{
								case SCPAppReceiptASN1TypeIAPProductIdentifier:
									[iapReceipt setProductIdentifier:string];
									break;
								case SCPAppReceiptASN1TypeIAPTransactionIdentifier:
									[iapReceipt setTransactionIdentifier:string];
									break;
								case SCPAppReceiptASN1TypeIAPOriginalTransactionIdentifier:
									[iapReceipt setOriginalTransactionIdentifier:string];
									break;
							}
						}
						
						if(str_type == V_ASN1_IA5STRING)
						{
							NSString *dateAsString = [[NSString alloc] initWithBytes:str_p
																		length:(NSUInteger)str_length
																	  encoding:NSASCIIStringEncoding];
							
							NSDate *date = [_dateFormatter dateFromString:dateAsString];
							
							switch (attr_type)
							{
								case SCPAppReceiptASN1TypeIAPPurchaseDate:
									[iapReceipt setPurchaseDate:date];
									break;
								case SCPAppReceiptASN1TypeIAPOriginalPurchaseDate:
									[iapReceipt setOriginalPurchaseDate:date];
									break;
								case SCPAppReceiptASN1TypeIAPSubscriptionExpirationDate:
									[iapReceipt setSubscriptionExpiryDate:date];
									break;
								case SCPAppReceiptASN1TypeIAPCancellationDate:
									[iapReceipt setCancellationDate:date];
									break;
							}
						}
					}
				}
                
				p += length;
			}
            
			//Skip any remaining fields in this SEQUENCE
			while (p < seq_end)
			{
				ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
				p += length;
			}
		}
        
		//Skip any remaining fields in this SET
		while (p < set_end)
		{
			ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
			p += length;
		}
	}
    
	return iapReceipt;
}

- (NSDictionary *)receiptDescription
{
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	
	[dictionary setObject:([self productIdentifier]) ? [self productIdentifier] : @"" forKey:@"productIdentifier"];
	[dictionary setObject:([self quantity]) ? [self quantity] : @"" forKey:@"quantity"];
	[dictionary setObject:([self cancellationDate]) ? [self cancellationDate] : @"" forKey:@"cancellationDate"];
	[dictionary setObject:([self originalPurchaseDate]) ? [self originalPurchaseDate] : @"" forKey:@"originalPurchaseDate"];
	[dictionary setObject:([self purchaseDate]) ? [self purchaseDate] : @"" forKey:@"purchaseDate"];
	[dictionary setObject:([self transactionIdentifier]) ? [self transactionIdentifier] : @"" forKey:@"transactionIdentifier"];
	[dictionary setObject:([self originalTransactionIdentifier]) ? [self originalTransactionIdentifier] : @"" forKey:@"originalTransactionIdentifier"];
	[dictionary setObject:([self subscriptionExpiryDate]) ? [self subscriptionExpiryDate] : @"" forKey:@"subscriptionExpiryDate"];
	[dictionary setObject:([self webItemId]) ? [self webItemId] : @"" forKey:@"webItemId"];
	
	return dictionary;
}

@end
