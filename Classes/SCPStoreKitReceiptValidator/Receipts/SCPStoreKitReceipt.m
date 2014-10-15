//
//  SCPStoreKitReceipt.m
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 12/12/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import "SCPStoreKitReceipt.h"

#import "pkcs7.h"
#import "x509.h"

typedef NS_ENUM(NSInteger, SCPAppReceiptASN1Type)
{
	SCPAppReceiptASN1TypeAttributeStart = 1,
	SCPAppReceiptASN1TypeBundleIdentifier = 2,
	SCPAppReceiptASN1TypeAppVersion = 3,
	SCPAppReceiptASN1TypeOpaqueValue = 4,
	SCPAppReceiptASN1TypeHash = 5,
	SCPAppReceiptASN1TypeAttributeEnd = 6,
	SCPAppReceiptASN1TypeInAppPurchaseReceipt = 17,
	SCPAppReceiptASN1TypeOriginalAppVersion = 19,
	SCPAppReceiptASN1TypeExpirationDate = 21,
};

@interface SCPStoreKitReceipt ()

@property (nonatomic, strong) NSString *bundleIdentifier;
@property (nonatomic, strong) NSData *bundleIdentifierData;
@property (nonatomic, strong) NSData *receiptHash;
@property (nonatomic, strong) NSData *opaqueValue;
@property (nonatomic, strong) NSString *originalVersion;
@property (nonatomic, strong) NSString *version;

@property (nonatomic, strong) NSMutableArray *inAppPurchases;

@end

@implementation SCPStoreKitReceipt

- (SCPStoreKitReceipt *)initFromAppStoreReceiptPath:(NSString *)receiptPath
{
	//Load the apple root cert
	NSData * appleIncRootCertificateData = [self appleIncRootCertificate];
	
	ERR_load_PKCS7_strings();
	ERR_load_X509_strings();
	OpenSSL_add_all_digests();
	
	const char * path = [[receiptPath stringByStandardizingPath] fileSystemRepresentation];
	FILE *fp = fopen(path, "rb");
	
	//Is there a receipt
	if(fp == NULL)
	{
		return nil;
	}
	
	PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
	fclose(fp);
	
	//Check it was encoded properly
	if(p7 == NULL)
	{
		return nil;
	}
	
	if(!PKCS7_type_is_signed(p7))
	{
		PKCS7_free(p7);
		return nil;
	}
	
	if(!PKCS7_type_is_data(p7->d.sign->contents))
	{
		PKCS7_free(p7);
		return nil;
	}
	
	int verifyReturnValue = 0;
	X509_STORE *store = X509_STORE_new();
	
	if(store)
	{
		const uint8_t *data = (uint8_t *)(appleIncRootCertificateData.bytes);
		X509 *appleCA = d2i_X509(NULL, &data, (long)appleIncRootCertificateData.length);
		
		if(appleCA)
		{
			BIO *payload = BIO_new(BIO_s_mem());
			X509_STORE_add_cert(store, appleCA);
			
			if(payload)
			{
				verifyReturnValue = PKCS7_verify(p7,NULL,store,NULL,payload,0);
				BIO_free(payload);
			}
			
			X509_free(appleCA);
		}
		
		X509_STORE_free(store);
	}
	
	EVP_cleanup();
	
	//If the receipt is not signed by Apple return nil
	if(verifyReturnValue != 1)
	{
		PKCS7_free(p7);
		return nil;
	}
	
	ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
	const uint8_t *p = octets->data;
	const uint8_t *end = p + octets->length;
	
	int type = 0;
	int xclass = 0;
	long length = 0;
	
	ASN1_get_object(&p, &length, &type, &xclass, end - p);
	
	if(type != V_ASN1_SET)
	{
		PKCS7_free(p7);
		return nil;
	}
	
	SCPStoreKitReceipt *receipt = [[SCPStoreKitReceipt alloc] init];
	
	//Loop through all the asn1c attributes
	while (p < end)
	{
		ASN1_get_object(&p, &length, &type, &xclass, end - p);
		
		if(type != V_ASN1_SEQUENCE)
		{
			break;
		}
		
		const uint8_t *seq_end = p + length;
		
		int attr_type = 0;
		int attr_version = 0;
		
		//Attribute type
		ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		
		if(type == V_ASN1_INTEGER && length == 1)
		{
			attr_type = p[0];
		}
		
		p += length;
		
		//Attribute version
		ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		
		if(type == V_ASN1_INTEGER && length == 1)
		{
			attr_version = p[0];
			attr_version = attr_version;
		}
		
		p += length;
		
		//Only parse attributes we're interested in
		if((attr_type > SCPAppReceiptASN1TypeAttributeStart && attr_type < SCPAppReceiptASN1TypeAttributeEnd) || attr_type == SCPAppReceiptASN1TypeInAppPurchaseReceipt || attr_type == SCPAppReceiptASN1TypeOriginalAppVersion || attr_type == SCPAppReceiptASN1TypeExpirationDate)
		{
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			
			if(type == V_ASN1_OCTET_STRING)
			{
				NSData *data = [NSData dataWithBytes:p length:(NSUInteger)length];
				
				//Bytes
				if(attr_type == SCPAppReceiptASN1TypeBundleIdentifier || attr_type == SCPAppReceiptASN1TypeOpaqueValue || attr_type == SCPAppReceiptASN1TypeHash)
				{
					switch (attr_type)
					{
						case SCPAppReceiptASN1TypeBundleIdentifier:
							//This is needed for hash generation
							[receipt setBundleIdentifierData:data];
							break;
						case SCPAppReceiptASN1TypeOpaqueValue:
							[receipt setOpaqueValue:data];
							break;
						case SCPAppReceiptASN1TypeHash:
                            [receipt setReceiptHash:data];
							break;
					}
				}
				
				//Strings
				if(attr_type == SCPAppReceiptASN1TypeBundleIdentifier || attr_type == SCPAppReceiptASN1TypeAppVersion || attr_type == SCPAppReceiptASN1TypeOriginalAppVersion)
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
							case SCPAppReceiptASN1TypeBundleIdentifier:
								[receipt setBundleIdentifier:string];
								break;
							case SCPAppReceiptASN1TypeAppVersion:
								[receipt setVersion:string];
								break;
							case SCPAppReceiptASN1TypeOriginalAppVersion:
								[receipt setOriginalVersion:string];
								break;
						}
					}
				}
				
				//In-App purchases
				if(attr_type == SCPAppReceiptASN1TypeInAppPurchaseReceipt)
				{
					SCPStoreKitIAPReceipt *iapReceipt = [[SCPStoreKitIAPReceipt alloc] initWithData:data];
					
					if(![receipt inAppPurchases])
					{
						[receipt setInAppPurchases:[NSMutableArray arrayWithObject:iapReceipt]];
					}
					else
					{
						[[receipt inAppPurchases] addObject:iapReceipt];
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
	
	PKCS7_free(p7);
	
	return receipt;
}

- (NSData *)appleIncRootCertificate
{
    return [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"SCPStoreKitReceiptValidatorResources.bundle/AppleIncRootCertificate" withExtension:@"cer"]];
}

- (NSDictionary *)fullDescription
{
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	
	[dictionary setObject:([self bundleIdentifier]) ? [self bundleIdentifier] : @"" forKey:@"bundleIdentifier"];
	[dictionary setObject:([self bundleIdentifierData]) ? [self bundleIdentifierData] : @"" forKey:@"bundleIdentifierData"];
	[dictionary setObject:([self receiptHash]) ? [self receiptHash] : @"" forKey:@"hash"];
	[dictionary setObject:([self opaqueValue]) ? [self opaqueValue] : @"" forKey:@"opaqueValue"];
	[dictionary setObject:([self originalVersion]) ? [self originalVersion] : @"" forKey:@"originalVersion"];
	[dictionary setObject:([self version]) ? [self version] : @"" forKey:@"version"];
	[dictionary setObject:([self inAppPurchases]) ? [self inAppPurchases] : @"" forKey:@"inAppPurchases"];
	
	return dictionary;
}

@end
