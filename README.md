# SCPStoreKitManager [![Version](https://img.shields.io/cocoapods/v/SCPStoreKitManager.svg?style=flat)](http://cocoadocs.org/docsets/SCPStoreKitManager)

Block based store kit manager for In-App Purchase for iOS7 with receipt validation. Please note that you must have iTunes Connect set up correctly with some IAPs already. The example App has no visual feed back to the user but you can follow it's progress via the console. The app can only work on a iDevice and can **not** be ran in a simulator.

####Required frameworks
* StoreKit

==================

####Installation

#####Pod


SCPStoreKitManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod 'SCPStoreKitManager'

#####Submodule

1. Add this repo as a submodule or download it as a .zip
2. Within the folder named `src` there is the required files in the folder named `SCPStoreKitManager`. If you don't wish to validate receipts then only copy the `Categories` folder and the `SCPStoreKitManager.h + .m` into your project.
3. Looking to your Project Navigator right mouse click on the `SCPStoreKitManager` folder and click *show in finder*. This should open up a new finder window to the location where you have the framework saved.
4. Navigating to the project build settings of your project, in the `Search Paths` section you need to add a path to the headers and libs. To do this double click on the *Header Search Paths* item. This should bring up a pop over. Going back to your finder window we opened in step 3 press and hold little folder next to the title of the finder window  and drag it into the *Header Search Paths* popover.
5. You should see something like `"$(SRCROOT)/ExampleProject/SCPStoreKitManager"`. You must now change the drop down value in the last column from `non-recursive` to `recursive`. Click away to save this.
6. Now double clicking on the *Library Search Paths* a similar popover should show. Going back to the finder window, navigate to `SCPStoreKitReceiptValidator > openSSL > lib`. Again with the `lib` folder selected press and hold the little folder next to the finder window title and drag it into the *Library Search Paths* popover.
7. Just like we did in step 5 you should see something like `"$(SRCROOT)/ExampleProject/SCPStoreKitManager/SCPStoreKitReceiptValidator/openSSL/lib"`. Click away to save this. 

NOTE : If you want to use your own implementation of OpenSSL then link these search paths to point to your implementation.

You should now be able to build the project and get no errors. If you do have errors, ensure that both search paths are set to `recursive`.

==================

####Usage

The framework is split into two parts. The first is to retrieve the In-App purchases from iTunes and handle the purchase of them. The second is receipt validation. You do not need to use the receipt validation but it is advised to protect your IAPs.

#####SCPStoreKitManager
This is a nice block based wrapper round StoreKits delegate methods.

There are four instance methods that are to accessed via the shared instance.

```
- (void)requestProductsWithIdentifiers:(NSSet *)productsSet productsReturnedSuccessfully:(ProductsReturnedSuccessfully)productsReturnedSuccessfullyBlock invalidProducts:(InvalidProducts)invalidProductsBlock failure:(Failure)failureBlock;
```

This method takes a `NSSet` of product identifiers. These product identifiers should match the *Product ID* of the IAP that you have set up in iTunes Connect. If you need help with this look at the [Apple Documentation](https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnectInAppPurchase_Guide/Chapters/Introduction.html#//apple_ref/doc/uid/TP40013727-CH1-SW1 "Apple's IAP Documentation")

This requests the IAP details for each product you ask for and upon a successful request it will call the `success` block returning an `NSArray` of `SKProduct`. If you have requested a product that is not on iTunes Connect then these identifiers will be returned as an `NSArray` of `NSString` of the identifiers that failed.

The failure block will catch any other errors such as no connectivity to iTunes.

######Example
```
//Request the product details from iTunes
[[SCPStoreKitManager sharedInstance] requestProductsWithIdentifiers:productIdentifiers
								   productsReturnedSuccessfully:^(NSArray *products) {
									   NSLog(@"Products : %@", products);
								   }
                                                    invalidProducts:^(NSArray *invalidProducts) {
                                                        NSLog(@"Invalid Products : %@", invalidProducts);
                                                    }
                                                            failure:^(NSError *error) {
                                                                NSLog(@"Error : %@", [error localizedDescription]);
                                                            }];
```

==================

```
- (void)requestPaymentForProduct:(SKProduct *)product paymentTransactionStatePurchasing:(PaymentTransactionStatePurchasing)paymentTransactionStatePurchasingBlock paymentTransactionStatePurchased:(PaymentTransactionStatePurchased)paymentTransactionStatePurchasedBlock paymentTransactionStateFailed:(PaymentTransactionStateFailed)paymentTransactionStateFailedBlock paymentTransactionStateRestored:(PaymentTransactionStateRestored)paymentTransactionStateRestoredBlock failure:(Failure)failureBlock;
```

This method takes a SKProduct that you wish to request payment for. There are four blocks that are called depending on the state of the SKProduct transaction. The use of these blocks is to allow you to update your UI along the process of taking payment. Each of these blocks with the exception of the failure block return an `NSArray` of `SKPaymentTransaction`. When the `paymentTransactionStatePurchased` block is called Apple has taken payment for the products that are returned in the transactions array. At this point you should unlock or add what is needed to honour the purchase.

######Example
```
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
```

==================

```
- (void)restorePurchasesPaymentTransactionStateRestored:(PaymentTransactionStateRestored)paymentTransactionStateRestoredBlock paymentTransactionStateFailed:(PaymentTransactionStateFailed)paymentTransactionStateFailedBlock failure:(Failure)failureBlock;
```
If you offer IAP you must provide a way for any IAP made to be restored [More info](http://matt.coneybeare.me/app-store-rejection-for-not-having-in-app-purchase-restoration/ "Blog post"). To do this call this method on the shared instance and all previous transactions will be returned to the `PaymentTransactionStateRestored` block in an `NSArray` of `SKPaymentTransaction`.

######Example
```
//Request to restore previous purchases
[[SCPStoreKitManager sharedInstance] restorePurchasesPaymentTransactionStateRestored:^(NSArray *transactions) {
      NSLog(@"Restored transactions : %@", transactions);
}
                                                       paymentTransactionStateFailed:^(NSArray *transactions) {
                                                           NSLog(@"Failed to restore transactions : %@", transactions);
                                                       }
                                                                             failure:^(NSError *error) {
                                                                                 NSLog(@"Failure : %@", [error localizedDescription]);
                                                                             }];
```

==================

```
- (NSString *)localizedPriceForProduct:(SKProduct *)product;
```
Method that takes a `SKProduct` and returns a `NSString` of the price for the product that matches the phones locale.

######Example
```
[productPriceLabel setText:[[SCPStoreKitManager sharedInstance] localizedPriceForProduct:product]];
```
==================

#####SCPStoreKitReceiptValidator
```
- (void)validateReceiptWithBundleIdentifier:(NSString *)bundleIdentifier bundleVersion:(NSString *)bundleVersion tryAgain:(BOOL)tryAgain showReceiptAlert:(BOOL)showReceiptAlert alertViewTitle:(NSString *)alertViewTitle alertViewMessage:(NSString *)alertViewMessage success:(Success)successBlock failure:(Failure)failureBlock;
```
One method that validates the app receipt is from Apple Inc and has not been tampered with. This method does take a few arguments but I believe that they are useful.

Explanation of arguments : 
* **(NSString *)bundleIdentifier**

    This should match your Apps bundle identifier. This is hardcoded into the app rather than retrieved from the info.plist. The reason for this is to stop anyone from just editing the plist to match a receipt that has purchased any ot all IAPs. 

* **bundleVersion:(NSString *)bundleVersion**

    Not only do you want to know if the receipt is for the correct app but also for the correct version. Again hardcoded to avoid plist editing.

* **(BOOL)tryAgain**

    When an App is first installed there is no receipt. This `BOOL` determines if the validator should try and request a new/up-to-date receipt from Apple. This can look strange because to do so the user must enter their Apple ID details. If this is set to `NO` then it will not attempt to refresh or request a receipt from Apple and only validate a receipt if their is already one one the device.
    
* **(BOOL)showReceiptAlert**

    If set to `YES` will show a UIAlertView informing the user of why they will be asked to enter their Apple ID details before the alert to enter their Apple ID shows. This can reassure the user because it can be quite worrying if as soon as you open the app it is asking for your Apple ID details without any prior notice or context. When the alert shows they are given a *Yes* or *No* option to request a receipt.
    
* **(NSString *)alertViewTitle and (NSString *)alertViewMessage**

    These two arguments allow you to supply the alert view with a custom title and message.

* **(Success)successBlock**

    Once the receipt has been validated you can be assured that the receipt is genuine. When this block is called you are passed a `SCPStoreKitReceipt`. See below for the details of `SCPStoreKitReceipt`. 

* **(Failure)failureBlock**   

    If the receipt is to be invalid you can handle this in the failure block.
    
######Example
```
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
                                                                                  NSLog(@"Previous purchase of '%@' on %@", [iapReceipt productIdentifier], [iapReceipt purchaseDate]);
                                                                              }];
                                                                              
                                                                          } failure:^(NSError *error) {
                                                                              NSLog(@"%@", [error fullDescription]);
                                                                          }];
```
==================

####Receipts
There are two types of receipts `SCPStoreKitReceipt` and `SCPStoreKitIAPReceipt`. Each of them holds deferent data that can be very useful. You do not `init` any of these receipts, you are given them by the `SCPStoreKitReceiptValidator` method.

All receipts have the same helper method :
```
- (NSDictionary *)fullDescription;
```
This simply outputs the receipt as a `NSDictionary`.

#####SCPStoreKitReceipt
This receipt holds the data we can use to validate that the receipt for the App is for this App and this device.

The properties are :
```
@property (nonatomic, strong, readonly) NSString *bundleIdentifier;
@property (nonatomic, strong, readonly) NSData *bundleIdentifierData;
@property (nonatomic, strong, readonly) NSData *hash;
@property (nonatomic, strong, readonly) NSData *opaqueValue;
@property (nonatomic, strong, readonly) NSString *originalVersion;
@property (nonatomic, strong, readonly) NSString *version;

@property (nonatomic, strong, readonly) NSMutableArray *inAppPurchases;
```
For more info on these properties look at the WWDC13 Session. Two worth noting are :
* **NSString *originalVersion**
  If your change you app from being a paid app to a freemium app you don't want to upset your current customers by making them pay for the IAPs when they paid for the app. With this property you can check when the app version was originally bought and if it falls before your freemium change then you know that you need to unlock all the features that the app had at the point of their original purchase. 

* **NSMutableArray *inAppPurchases**
  This array holds all the IAPs made for the Apps receipt. See below for the properties and how they can be used to validate their purchases.

#####SCPStoreKitIAPReceipt
This receipt holds all the details for a single IAP. There are some useful properties in this receipt and these are : 
```
@property (nonatomic, strong, readonly) NSString *productIdentifier;
@property (nonatomic, strong, readonly) NSNumber *quantity;
@property (nonatomic, strong, readonly) NSDate *cancellationDate;
@property (nonatomic, strong, readonly) NSDate *originalPurchaseDate;
@property (nonatomic, strong, readonly) NSDate *purchaseDate;
@property (nonatomic, strong, readonly) NSString *transactionIdentifier;
@property (nonatomic, strong, readonly) NSString *originalTransactionIdentifier;
@property (nonatomic, strong, readonly) NSDate *subscriptionExpiryDate;
@property (nonatomic, strong, readonly) NSNumber *webItemId;
```

Some ways to use these properties are :
* **NSString *productIdentifier**
  
  This is used so you know what product was bought and what features/products you need to unlock.

* **NSNumber *quantity**
  
  If it was a consumable item such as coins or tokens you can count how many of the item were purchased and then compare that against the users balance to check there hasn't been any tempering with balances. (.plist editing.) If this product gives the user 10 tokens and they have bought it twice then they should have a maximum of 20 tokens. If they have more then you know that something has been tampered with and deal with it. 

==================

####Contact
twitter : [@ste_prescott](https://twitter.com/ste_prescott "Twitter account").

==================

####License
This project made available under the MIT License.

Copyright (C) 2014 Ste Prescott

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
