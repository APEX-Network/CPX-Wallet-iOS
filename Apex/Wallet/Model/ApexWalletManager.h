//
//  ApexWalletManager.h
//  Apex
//
//  Created by chinapex on 2018/5/21.
//  Copyright © 2018年 Chinapex. All rights reserved.
//

#import <Foundation/Foundation.h>
#define walletsKey @"walletsKey"
@interface ApexWalletManager : NSObject
+ (void)saveWallet:(NSString*)wallet;
+ (void)changeWalletName:(NSString*)name forAddress:(NSString*)address;
+ (id)getWalletsArr; /**< string : address/name */
+ (void)deleteWalletForAddress:(NSString*)address;

/** 获取钱包余额 */
+ (void)getAccountStateWithAddress:(NSString*)address Success:(void (^)(AFHTTPRequestOperation  *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/** 获取交易明细 */
+ (void)getRawTransactionWithTxid:(NSString*)txid Success:(void (^)(AFHTTPRequestOperation  *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/** 广播交易 */
+ (void)broadCastTransactionWithData:(NSString*)data Success:(void (^)(AFHTTPRequestOperation  *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
@end
