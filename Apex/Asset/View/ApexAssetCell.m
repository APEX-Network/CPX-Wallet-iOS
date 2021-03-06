//
//  ApexAssetCell.m
//  Apex
//
//  Created by chinapex on 2018/6/4.
//  Copyright © 2018年 Gary. All rights reserved.
//

#import "ApexAssetCell.h"
#import "CYLEmptyView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ApexAssetCell()
@property (weak, nonatomic) IBOutlet UILabel *assetNameL;
@property (weak, nonatomic) IBOutlet UILabel *assetNameLTwo;
@property (weak, nonatomic) IBOutlet UILabel *balanceL;
@property (weak, nonatomic) IBOutlet UIButton *mappignBtn;
@property (weak, nonatomic) IBOutlet UIImageView *assetIcon;

@end

@implementation ApexAssetCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initUI];
}

- (void)initUI{
    self.layer.cornerRadius = 3;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = [UIColor colorWithHexString:@"dddddd"].CGColor;
    self.layer.borderWidth = 1.0/kScale;
//    self.layer.shadowColor = [UIColor grayColor].CGColor;
//    self.layer.shadowOffset = CGSizeMake(0, 1);
//    self.layer.shadowOpacity = 0.8;
//    self.layer.shadowRadius = 3;
    
    [_mappignBtn setTitleColor:[ApexUIHelper grayColor] forState:UIControlStateNormal];
    _mappignBtn.layer.borderColor = [ApexUIHelper grayColor].CGColor;
    _mappignBtn.layer.borderWidth = 1.0/kScale;
    _mappignBtn.layer.cornerRadius = 4;
    _mappignBtn.backgroundColor = [ApexUIHelper grayColor240];
    [_mappignBtn setTitle:SOLocalizedStringFromTable(@"Go Mapping", nil) forState:UIControlStateNormal];
    
    [_balanceL setAdjustsFontSizeToFitWidth:YES];
    
//    _assetIcon.image = NEOPlaceHolder;
}

- (void)setModel:(BalanceObject *)model{
    _model = model;
    if ([model.value isKindOfClass:NSNumber.class]) {
        model.value = ((NSNumber*)model.value).stringValue;
    }
    _balanceL.text = model.value.floatValue == 0 ? @"0" : model.value;
    
    if (_type == ApexWalletType_Neo) {
        //neo钱包资产详情
        
        ApexAssetModel *assetModel = [[ApexWalletManager shareManager] assetModelByBalanceModel:model];
        _assetNameL.text = assetModel.symbol;
        _assetNameLTwo.text = @"";
        
        if ([model.asset containsString:assetId_CPX]) {
            _mappignBtn.hidden = NO;
            self.assetIcon.image = CPX_Logo;
        }else if([model.asset containsString:assetId_NeoGas] || [model.asset containsString:assetId_Neo]){
            _mappignBtn.hidden = YES;
            self.assetIcon.image = NEOPlaceHolder;
        }else{
            _mappignBtn.hidden = YES;
            UIImage *image = [UIImage imageNamed:model.asset inBundle:[ApexAssetModelManage resourceBundle] compatibleWithTraitCollection:nil];
            if (image) {
                self.assetIcon.image = image;
            }else{
                image = [UIImage imageNamed:model.asset];
                
                self.assetIcon.image = image ? image : NEOPlaceHolder;
            }
        }
        
    }else{
        //eth钱包资产详情
        if (_model.value.floatValue >= 0.00000001) {
            _balanceL.text = [[NSString stringWithFormat:@"%.18f",_balanceL.text.doubleValue] substringToIndex:10];
        }
        
        ApexAssetModel *assetModel = [[ETHWalletManager shareManager] assetModelByBalanceModel:model];
        _mappignBtn.hidden = YES;
        _assetNameL.text = assetModel.symbol;
        _assetNameLTwo.text = @"";
        
        [_assetIcon sd_setImageWithURL:[NSURL URLWithString:assetModel.image_url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (!image) {
                _assetIcon.image = ETHPlaceHolder;
            }
        }];
    }
}
@end
