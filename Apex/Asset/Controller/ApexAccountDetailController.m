//
//  ApexAccountDetailController.m
//  Apex
//
//  Created by chinapex on 2018/6/4.
//  Copyright © 2018年 Gary. All rights reserved.
//

#import "ApexAccountDetailController.h"
#import "ApexWalletDetailController.h"
#import "ApexAssetCell.h"
#import "ApexAccountStateModel.h"
#import "CYLEmptyView.h"
#import "ApexMorePanelController.h"
#import "ApexDrawTransAnimator.h"
#import "ApexAddAssetsController.h"
#import "ETHTransferHistoryManager.h"
#import "ApexTransferHistoryManager.h"
#import "ApexCopyLable.h"
#import "ApexAccountDetailViewModel.h"

#define RouteNameEvent_ShowMorePanel @"RouteNameEvent_ShowMorePanel"

@interface ApexAccountDetailController ()<UINavigationControllerDelegate>
@property (nonatomic, strong) ApexCopyLable *addressL;
@property (nonatomic, strong) ApexAccountStateModel *accountModel;
//@property (nonatomic, strong) CYLEmptyView *emptyV;
@property (nonatomic, strong) NSMutableArray *assetArr;
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong) ApexDrawTransAnimator *transAnimator;
@property (nonatomic, strong) NSMutableDictionary *assetMap; //资产对应的余额字典
@property (nonatomic, strong) UIImageView *backIV;
@property (nonatomic, assign) BOOL isNavClear; /**<  */
@property (nonatomic, assign) ApexWalletType type; /**<  */
@property (nonatomic, strong) ApexAccountDetailViewModel *viewModel; /**<  */
@end

@implementation ApexAccountDetailController

#pragma mark - ------life cycle------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setNav];
    
    if (_type == ApexWalletType_Neo) {
        [self requestNeoAsset];
        
    }else if (_type == ApexWalletType_Eth){
        
        [self requestETHAsset];
    }
    
    [self setEdgeGesture];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if (!_isNavClear) {
        [self.navigationController lt_setBackgroundColor:[UIColor clearColor]];
        _isNavClear = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController lt_setBackgroundColor:[UIColor clearColor]];
}


#pragma mark - ------private------
- (void)initUI{

    [self.view insertSubview:self.backIV atIndex:0];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ApexAssetCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    
    [self.accessoryBaseView addSubview:self.addressL];
    [self.addressL mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(self.addressL.superview);
        make.centerX.equalTo(self.addressL.superview);
        make.centerY.equalTo(self.addressL.superview);
    }];
    
    MJRefreshStateHeader *header = [MJRefreshStateHeader headerWithRefreshingBlock:^{
        if (self.type == ApexWalletType_Neo) {
            [self requestNeoAsset];
        }else if (self.type == ApexWalletType_Eth){
            [self requestETHAsset];
        }
    }];
    header.stateLabel.textColor = [ApexUIHelper grayColor240];
    header.lastUpdatedTimeLabel.textColor = [ApexUIHelper grayColor240];
    self.tableView.mj_header = header;
    self.tableView.mj_header.automaticallyChangeAlpha = YES;
}

- (void)setEdgeGesture{
    [[ApexDrawTransPercentDriven shareDriven] setPercentDrivenForFromViewController:self edgePan:^(UIScreenEdgePanGestureRecognizer *edgePan) {
        switch (edgePan.state) {
            case UIGestureRecognizerStateBegan:
            {
                [self pushAction];
            }
                break;
            default:
                break;
        }
    }];
}

- (void)setNav{
    self.navigationController.delegate = self;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.moreBtn];
}

- (void)creataAssetMap{
    self.assetMap = [NSMutableDictionary dictionary];
    for (BalanceObject *balance in self.assetArr) {
        [self.assetMap setValue:balance.value forKey:balance.asset];
    }
}

#pragma mark - 获取钱包ETH资产
- (void)getLoacalEthAsset{
    self.title = self.walletModel.name;
    self.addressL.text = self.walletModel.address;
    self.assetArr = self.walletModel.assetArr;
    [self.tableView reloadData];
    [self creataAssetMap];
}

- (void)requestETHAsset{
    [self getLoacalEthAsset];
    
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
       
        [ETHWalletManager requestETHBalanceOfAddress:self.walletModel.address success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
            
            BalanceObject *obj = [BalanceObject new];
            obj.asset = assetId_Eth;
            obj.value = responseObject;
            [subscriber sendNext:@{assetId_Eth:obj}];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];
    
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
       
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        if (self.assetArr.count <= 1) [subscriber sendNext:dict];
        for (BalanceObject *obj in self.assetArr) {
            //非eth
            if (![obj.asset isEqualToString:assetId_Eth]) {
                ApexAssetModel *assetModel = [obj getRelativeETHAssetModel];
                
                [ETHWalletManager requestERC20BalanceOfContract:obj.asset Address:self.walletModel.address decimal:assetModel.precision success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                    obj.value = responseObject;
                    [dict setObject:obj forKey:obj.asset];
                    if (dict.allKeys.count == self.assetArr.count - 1) {
                        [subscriber sendNext:dict];
                    }
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [subscriber sendError:error];
                }];
            }
        }
        return nil;
    }];
    
    RACSignal *combineSig = [RACSignal combineLatest:@[request1,request2] reduce:^id(NSDictionary *eth, NSDictionary *erc20){
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict addEntriesFromDictionary:eth];
        [dict addEntriesFromDictionary:erc20];
        return dict;
    }];
    
    [[self rac_liftSelector:@selector(updateEthAndErc20:) withSignals:combineSig, nil] subscribeError:^(NSError * _Nullable error) {
        [self.tableView.mj_header endRefreshing];
        [self showMessage:SOLocalizedStringFromTable(@"Request Failed, Please Check Your Network Status", nil)];
    }];
}

- (void)updateEthAndErc20:(NSDictionary*)dict{
    [self.tableView.mj_header endRefreshing];
    for (BalanceObject *obj in self.assetArr) {
        obj.value = ((BalanceObject*)dict[obj.asset]).value;
    }
    
    [[ETHWalletManager shareManager] updateWallet:self.walletModel WithAssetsArr:self.assetArr];
    [self.tableView reloadData];
}

#pragma mark - 获取钱包Neo资产
- (void)getLoacalNeoAsset{
    self.title = self.walletModel.name;
    self.addressL.text = self.walletModel.address;
    self.assetArr = self.walletModel.assetArr;
    [[ApexWalletManager shareManager] reSortAssetArr:self.assetArr];
    [self creataAssetMap];
}

- (void)requestNeoAsset{
    [self getLoacalNeoAsset];
    @weakify(self);
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
       
        [ApexWalletManager getAccountStateWithAddress:self.walletModel.address Success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
            @strongify(self);
            self.accountModel = [ApexAccountStateModel yy_modelWithDictionary:responseObject];
            [subscriber sendNext:self.accountModel.balances];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
            [self showMessage:SOLocalizedStringFromTable(@"Request Failed, Please Check Your Network Status", nil)];
        }];
        
        return nil;
    }];
    
    
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
       
        NSMutableArray *array = [NSMutableArray array];
        NSMutableArray *nep5Keys = [self.assetMap.allKeys mutableCopy];
        [nep5Keys removeObject:assetId_NeoGas];
        [nep5Keys removeObject:assetId_Neo];
        
        for (NSString *assetId in nep5Keys) {
            if (![assetId isEqualToString:assetId_Neo] && ![assetId isEqualToString:assetId_NeoGas]) {
                //代币
                [ApexWalletManager getNep5AssetAccountStateWithAddress:self.walletModel.address andAssetId:assetId Success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    [array addObject:responseObject];
                    
                    if (array.count == nep5Keys.count) {
                        [subscriber sendNext:array];
                    }
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [subscriber sendError:error];
                }];
            }
        }
        
        return nil;
    }];
    
    [[self rac_liftSelector:@selector(updateWithR1:R2:) withSignals:request1,request2, nil] subscribeError:^(NSError * _Nullable error) {
        [self.tableView.mj_header endRefreshing];
        [self showMessage:SOLocalizedStringFromTable(@"Request Failed, Please Check Your Network Status", nil)];
    }];
}

- (void)updateWithR1:(id)r1 R2:(id)r2{
    [self.tableView.mj_header endRefreshing];
    //asset
    [self updateAssets:r1];
    //nep5
    [self updateAssets:r2];
    [self.tableView reloadData];
}

- (void)updateAssets:(NSArray*)balanceArr{
    
    BOOL isNep5Arr = YES;
    for (BalanceObject *objct in balanceArr) {
        if ([objct.asset isEqualToString:assetId_Neo] || [objct.asset isEqualToString:assetId_NeoGas]) {
            isNep5Arr = false;
            break;
        }
    }
    
    //非nep5资产
    if (!isNep5Arr) {
    
        for (BalanceObject *obj in self.assetArr) {
            if (([obj.asset isEqualToString:assetId_NeoGas] || [obj.asset isEqualToString:assetId_Neo]) && ![balanceArr containsObject:obj]) {
                NSLog(@"缺失%@",obj.asset);
                obj.value = @"0";
            }
        }
    }
    
    if (balanceArr.count == 0) {
        //网络请求没有返回任何资产,本地资产置0
        for (BalanceObject *localObj in self.assetArr) {
            localObj.value = @"0";
        }
        
    }else{
        
        for (BalanceObject *remoteObj in balanceArr) {
            
            if ([self.assetMap.allKeys containsObject:remoteObj.asset]) {
                //更新余额
                BalanceObject *equalObj = nil;
                for (BalanceObject *localObj in [self.assetArr copy]) {
                    if ([localObj.asset isEqualToString:remoteObj.asset]) {
                        equalObj = localObj;
                        break;
                    }
                }
                if (equalObj) {
                    [self.assetArr removeObject:equalObj];
                    [self.assetArr addObject:remoteObj];
                }
            }else{
                //余额置0或者添加余额
                BalanceObject *equalObj = nil;
                for (BalanceObject *localObj in [self.assetArr copy]) {
                    if ([localObj.asset isEqualToString:remoteObj.asset]) {
                        equalObj = localObj;
                        break;
                    }
                }
                if (equalObj) {
                    equalObj.value = @"0";
                }else{
                    [self.assetArr addObject:remoteObj];
                }
            }
        
        }
    }
    //更新本地存储的钱包资产
    [[ApexWalletManager shareManager] updateWallet:self.walletModel WithAssetsArr:self.assetArr];
}

#pragma mark - ------transition-----
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        if ([toVC isKindOfClass:[ApexMorePanelController class]]) {
            return [CYLTansitionManager transitionObjectwithTransitionStyle:CYLTransitionStyle_Push animateDuration:0.5 andTransitionAnimation:self.transAnimator];
        }else{
            return nil;
        }
    }else {
        if ([fromVC isKindOfClass:[ApexMorePanelController class]]) {
            return [CYLTansitionManager transitionObjectwithTransitionStyle:CYLTransitionStyle_Pop animateDuration:0.5 andTransitionAnimation:self.transAnimator];
        }else{
            return nil;
        }
    }
}

/**
 实现此方法后 所有的转场动画过程都要由ApexDrawTransPercentDriven的百分比决定*/
- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController{
    
    return [ApexDrawTransPercentDriven shareDriven];
}


#pragma mark - ------public------

#pragma mark - ------delegate & datasource------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    NSInteger count = self.assetArr.count;
    return count == 0 ? 1 : count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ApexAssetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.type = _type;
    if (self.assetArr.count == 0) {
        cell.hidden = YES;
    }else{
        cell.model = self.assetArr[indexPath.section];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ApexWalletDetailController *vc = [[ApexWalletDetailController alloc] init];
    vc.wallModel = self.walletModel;
    vc.balanceModel = self.assetArr[indexPath.section];
    [self.navigationController pushViewController:vc animated:YES];
}
#pragma mark - ------eventResponse------
- (void)routeEventWithName:(NSString *)eventName userInfo:(NSDictionary *)userinfo{
    if([eventName isEqualToString:RouteNameEvent_ShowMorePanel]){
        [self pushAction];
    }
}

- (void)addressCopy{
    UIPasteboard *pastBoard = [UIPasteboard generalPasteboard];
    pastBoard.string = self.walletModel.address;
    [self showMessage:SOLocalizedStringFromTable(@"CopySuccess", nil)];
}

- (void)pushAction{
    ApexAddAssetsController *addVC = [[ApexAddAssetsController alloc] init];
    addVC.walletAssetArr = self.assetArr;
    addVC.type = self.type;
    [self.navigationController pushViewController:addVC animated:YES];
}

#pragma mark - ------getter & setter------
- (void)setWalletModel:(ApexWalletModel *)walletModel{
    _walletModel = walletModel;
    
    if ([walletModel isKindOfClass:ETHWalletModel.class]) {
        _type = ApexWalletType_Eth;
        [[ETHTransferHistoryManager shareManager] secreteUpdateUserTransactionHistoryAddress:walletModel.address];
    }else{
        _type = ApexWalletType_Neo;
        [[ApexTransferHistoryManager shareManager] secreteUpdateUserTransactionHistoryAddress:walletModel.address];
    }
}

- (ApexAccountDetailViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[ApexAccountDetailViewModel alloc] init];
    }
    return _viewModel;
}

- (ApexCopyLable *)addressL{
    if (!_addressL) {
        _addressL = [[ApexCopyLable alloc] init];
        _addressL.frame = CGRectMake(222,134,309,37);
        _addressL.textAlignment = NSTextAlignmentCenter;
        _addressL.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        _addressL.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1];
        _addressL.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [[tap rac_gestureSignal] subscribeNext:^(__kindof UIGestureRecognizer * _Nullable x) {
            [self addressCopy];
        }];
        [_addressL addGestureRecognizer:tap];
    }
    return _addressL;
}

- (NSMutableArray *)assetArr{
    if (!_assetArr) {
        _assetArr = [NSMutableArray array];
    }
    return _assetArr;
}

- (UIButton *)moreBtn{
    if (!_moreBtn) {
        _moreBtn = [[UIButton alloc] init];
        _moreBtn.frame = CGRectMake(0, 0, 40, 40);
        [_moreBtn setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
        [[_moreBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
            [self routeEventWithName:RouteNameEvent_ShowMorePanel userInfo:@{}];
        }];
    }
    return _moreBtn;
}

- (ApexDrawTransAnimator *)transAnimator{
    if (!_transAnimator) {
        _transAnimator = [[ApexDrawTransAnimator alloc] init];
//        _transAnimator.fakeView = [self.view snapshotViewAfterScreenUpdates:NO];
    }
    return _transAnimator;
}

- (UIImageView *)backIV{
    if (!_backIV) {
        _backIV = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _backIV.image = [UIImage imageNamed:@"backImage"];
    }
    return _backIV;
}
@end
