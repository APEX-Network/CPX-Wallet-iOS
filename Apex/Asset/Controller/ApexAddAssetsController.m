//
//  ApexAddAssetsController.m
//  Apex
//
//  Created by chinapex on 2018/7/4.
//  Copyright © 2018 Gary. All rights reserved.
//

#import "ApexAddAssetsController.h"
#import "ApexSearchWalletToolBar.h"
#import "ApexAddAssetCell.h"

@interface ApexAddAssetsController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ApexSearchWalletToolBar *searchToolBar;
@property (nonatomic, strong) UILabel *titleL;
@property (nonatomic, strong) NSMutableArray *contentArr;
@end

@implementation ApexAddAssetsController
#pragma mark - ------life cycle------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUI];
    
    [self handleEvent];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    if (self.type == ApexWalletType_Neo) {
        [self prepareNeoData];
    }else{
        [self prepareEthData];
    }
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self.navigationController lt_setBackgroundColor:[UIColor clearColor]];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self.navigationController lt_setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - ------private------
- (void)setUI{
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.titleL];
    [self.view addSubview:self.backBtn];
    [self.view addSubview:self.searchToolBar];
    [self.view addSubview:self.tableView];
    
    
    [self.searchToolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(NavBarHeight);
        make.left.equalTo(self.view).offset(15);
        make.right.equalTo(self.view).offset(-15);
        make.height.mas_equalTo(50);
    }];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.searchToolBar.mas_bottom).offset(5);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ApexAddAssetCell" bundle:nil] forCellReuseIdentifier:@"cell"];

    self.navigationItem.titleView = self.titleL;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.backBtn];
}

- (void)prepareEthData{
    self.contentArr = [ETHAssetModelManage getLocalAssetModelsArr];
    ApexAssetModel *ethModel = nil;
    for (ApexAssetModel *model in [self.contentArr copy]) {
        if ([model.hex_hash isEqualToString:assetId_Eth]) {
            [self.contentArr removeObject:ethModel];
            ethModel = model;
            break;
        }
    }
    if(ethModel) [self.contentArr insertObject:ethModel atIndex:0];
    [self.tableView reloadData];
}

- (void)prepareNeoData{
    self.contentArr = [ApexAssetModelManage getLocalAssetModelsArr];
    if (self.contentArr.count == 0) {
        return;
    }
    ApexAssetModel *cpxModel = nil;
    ApexAssetModel *neoModel = nil;
    ApexAssetModel *gasModel = nil;
    //置顶neo gas cpx的展示
    for (ApexAssetModel *model in [self.contentArr copy]) {
        if ([model.hex_hash isEqualToString:assetId_NeoGas]) {
            [self.contentArr removeObject:model];
            gasModel = model;
        }
        if ([model.hex_hash isEqualToString:assetId_Neo]) {
            [self.contentArr removeObject:model];
            neoModel = model;
        }
        if ([model.hex_hash isEqualToString:assetId_CPX]) {
            [self.contentArr removeObject:model];
            cpxModel = model;
        }
    }
    
    [self.contentArr insertObject:gasModel atIndex:0];
    [self.contentArr insertObject:neoModel atIndex:0];
    [self.contentArr insertObject:cpxModel atIndex:0];
    
    [self.tableView reloadData];
}

- (BOOL)verifyIsSelect:(ApexAssetModel*)model{
    for (BalanceObject *obj in self.walletAssetArr) {
        if ([model.hex_hash isEqualToString:obj.asset]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - ------public------

#pragma mark - ------delegate & datasource------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.contentArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ApexAddAssetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.model = self.contentArr[indexPath.row];
    cell.indicator.selected = [self verifyIsSelect:cell.model];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    ApexAssetModel *model = self.contentArr[indexPath.row];
    if ([model.hex_hash isEqualToString:assetId_NeoGas] || [model.hex_hash isEqualToString:assetId_Neo] || [model.hex_hash isEqualToString:assetId_CPX]) {
        return;
    }
    
    ApexAddAssetCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.indicator.selected = !cell.indicator.selected;
    if (cell.indicator.selected) {
        [self.walletAssetArr addObject:[model convertToBalanceObject]];
    }else{
        [self.walletAssetArr removeObject:[model convertToBalanceObject]];
    }
}


#pragma mark - ------eventResponse------
- (void)handleEvent{
    
    [[self.backBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    
    self.searchToolBar.textDidChangeSub = [RACSubject subject];
    [self.searchToolBar.textDidChangeSub subscribeNext:^(NSString *key) {
        
        if (key.length == 0) {
            if (self.type == ApexWalletType_Neo) {
                [self prepareNeoData];
            }else{
                [self prepareEthData];
            }
        }else{
            NSMutableArray *temp = [NSMutableArray array];
            
            if (self.type == ApexWalletType_Neo) {
                for (ApexAssetModel *model in [ApexAssetModelManage getLocalAssetModelsArr]) {
                    if ([model.symbol.lowercaseString hasPrefix:key.lowercaseString] && ![model.hex_hash isEqualToString:assetId_CPX] && ![model.hex_hash isEqualToString:assetId_Neo] && ![model.hex_hash isEqualToString:assetId_NeoGas]) {
                        [temp addObject:model];
                    }
                }
            }else{
                for (ApexAssetModel *model in [ETHAssetModelManage getLocalAssetModelsArr]) {
                    if ([model.symbol.lowercaseString hasPrefix:key.lowercaseString]) {
                        [temp addObject:model];
                    }
                }
            }
            
            self.contentArr = temp;
        }
        
        [self.tableView reloadData];
    }];
}
#pragma mark - ------getter & setter------
- (UIButton *)backBtn{
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 30)];
        [_backBtn setImage:[UIImage imageNamed:@"back-4"] forState:UIControlStateNormal];
        _backBtn.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _backBtn;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (ApexSearchWalletToolBar *)searchToolBar{
    if (!_searchToolBar) {
        _searchToolBar = [[ApexSearchWalletToolBar alloc] init];
        [_searchToolBar setPlaceHolder:SOLocalizedStringFromTable(@"Assets", nil) color:UIColorHex(666666)];
        [_searchToolBar setTextColor:UIColorHex(666666) backgroundColor:[UIColorHex(999999) colorWithAlphaComponent:0.2]];
        [_searchToolBar setLeftView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search-1"]]];
    }
    return _searchToolBar;
}

- (UILabel *)titleL{
    if (!_titleL) {
        _titleL = [[UILabel alloc] init];
        _titleL.text = SOLocalizedStringFromTable(@"Add Assets", nil);
        _titleL.font = [UIFont systemFontOfSize:17];
        _titleL.textColor = [UIColor blackColor];
    }
    return _titleL;
}
@end
