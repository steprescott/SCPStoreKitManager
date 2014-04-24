//
//  SCPViewController.m
//  SCPStoreKitManager
//
//  Created by Ste Prescott on 21/11/2013.
//  Copyright (c) 2013 Ste Prescott. All rights reserved.
//

#import "SCPViewController.h"

#import "SCPStoreKitManager.h"
#import "SCPStoreKitReceiptValidator.h"

typedef NS_ENUM(NSUInteger, ProductCellViewTags) {
    productNameLabelTag = 100,
	productDescriptionTag = 101,
	productPriceTag = 102,
};

static NSString *productCellIdentifier = @"productCell";

@interface SCPViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *products;

- (IBAction)restorePurchasesButtonPressed:(id)sender;

@end

@implementation SCPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Validate the Apps receipt
	[[SCPStoreKitReceiptValidator sharedInstance] validateReceiptWithBundleIdentifier:@"me.ste.SCPStoreKitManager"
                                                                        bundleVersion:@"1.0"
                                                                             tryAgain:YES
                                                                     showReceiptAlert:YES
                                                                       alertViewTitle:nil
                                                                     alertViewMessage:nil
                                                                              success:^(SCPStoreKitReceipt *receipt) {
                                                                                  
                                                                                  //Here you would do some further checks such as :
                                                                                    //Validate that the number of coins/tokens the user has does not exceed the number they have paid for
                                                                                    //Unlock any non-consumable items
                                                                                  
                                                                                  NSLog(@"App receipt : %@", [receipt fullDescription]);
                                                                                  
                                                                                  //Enumerate through the IAPs and unlock their features
                                                                                  [[receipt inAppPurchases] enumerateObjectsUsingBlock:^(SCPStoreKitIAPReceipt *iapReceipt, NSUInteger idx, BOOL *stop) {
                                                                                      NSLog(@"IAP receipt :%@", [iapReceipt fullDescription]);
                                                                                  }];
                                                                                  
                                                                              } failure:^(NSError *error) {
                                                                                  NSLog(@"%@", [error fullDescription]);
                                                                              }];
	
    //These are the product identifiers for the IAP that you made in iTunes Connect. (Their 'Product ID')
	NSSet *productIdentifiers = [NSSet setWithArray:@[@"consumableItem", @"nonConsumableItem"]];
	
    //Request the product details from iTunes
    [[SCPStoreKitManager sharedInstance] requestProductsWithIdentifiers:productIdentifiers
										   productsReturnedSuccessfully:^(NSArray *products) {
											   NSLog(@"Products : %@", products);
                                               self.products = products;
                                               [_tableView reloadData];
										   }
                                                        invalidProducts:^(NSArray *invalidProducts) {
                                                            NSLog(@"Invalid Products : %@", invalidProducts);
                                                        }
                                                                failure:^(NSError *error) {
                                                                    NSLog(@"Error : %@", [error localizedDescription]);
                                                                }];
}

#pragma mark - IBActions

- (IBAction)restorePurchasesButtonPressed:(id)sender
{
    //Request to restor previous purchases
	[[SCPStoreKitManager sharedInstance] restorePurchasesPaymentTransactionStateRestored:^(NSArray *transactions) {
        NSLog(@"Restored transactions : %@", transactions);
	}
                                                           paymentTransactionStateFailed:^(NSArray *transactions) {
                                                               NSLog(@"Failed to restore transactions : %@", transactions);
                                                           }
                                                                                 failure:^(NSError *error) {
                                                                                     NSLog(@"Failure : %@", [error localizedDescription]);
                                                                                 }];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SKProduct *product = _products[indexPath.row];
	
	//Dequeue cell
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:productCellIdentifier];
	
	UILabel *productNameLabel = (UILabel *)[cell viewWithTag:productNameLabelTag];
	UILabel *productDescriptionLabel = (UILabel *)[cell viewWithTag:productDescriptionTag];
	UILabel *productPriceLabel = (UILabel *)[cell viewWithTag:productPriceTag];
	
	[productNameLabel setText:[product localizedTitle]];
	[productDescriptionLabel setText:[product localizedDescription]];
	[productPriceLabel setText:[[SCPStoreKitManager sharedInstance] localizedPriceForProduct:product]];
	
	return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
    //Request payment for product
	[[SCPStoreKitManager sharedInstance] requestPaymentForProduct:_products[indexPath.row]
								paymentTransactionStatePurchasing:^(NSArray *transactions) {
                                    NSLog(@"Purchasing products : %@", transactions);
                                }
                                 paymentTransactionStatePurchased:^(NSArray *transactions) {
                                     NSLog(@"Purchased products : %@", transactions);
                                 }
                                    paymentTransactionStateFailed:^(NSArray *transactions) {
                                        NSLog(@"Failed products : %@", transactions);
                                    }
                                  paymentTransactionStateRestored:^(NSArray *transactions) {
                                      NSLog(@"Restored products : %@", transactions);
                                  }
                                                          failure:^(NSError *error) {
                                                              NSLog(@"Failure : %@", [error localizedDescription]);
                                                          }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
