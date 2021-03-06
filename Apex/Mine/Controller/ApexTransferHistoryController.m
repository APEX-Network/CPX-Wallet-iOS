//
//  ApexTransferHistoryController.m
//  Apex
//
//  Created by chinapex on 2018/7/12.
//  Copyright © 2018 Gary. All rights reserved.
//

#import "ApexTransferHistoryController.h"
#import "ApexTransactionRecordView.h"
#import "ApexTransactionDetailController.h"
#import "ApexNoWalletView.h"

@interface ApexTransferHistoryController ()
@property (nonatomic, strong) ApexTransactionRecordView *transactionView;
@property (nonatomic, strong) UILabel *titleL;
@property (nonatomic, strong) UIImageView *fakeNavBar; /**<  */
@property (nonatomic, strong) ApexNoWalletView *noWalletView; /**<  */
@end

@implementation ApexTransferHistoryController

#pragma mark - ------life cycle------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    [self setNav];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController lt_setBackgroundColor:[UIColor clearColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self judgeIfHadWallet];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController lt_setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - ------private------
- (void)initUI{

    self.navigationItem.titleView = self.titleL;
    [self.view addSubview:self.transactionView];
    [self.view addSubview:self.fakeNavBar];
    
    [self.fakeNavBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(NavBarHeight);
    }];
    
    [self.transactionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.fakeNavBar.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    [self.transactionView reloadTransactionData];
}

- (void)setNav{
    UIImage *image = [UIImage imageNamed:@"back-4"];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(back)];
}

- (void)judgeIfHadWallet{
    NSMutableArray *arr = [[ApexWalletManager shareManager] getWalletsArr];
    [arr addObject:[[ETHWalletManager shareManager] getWalletsArr]];
    if (arr.count == 0) {
        [self.transactionView addSubview:self.noWalletView];
        [self.noWalletView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.transactionView);
        }];
        self.noWalletView.hidden = NO;
    }else{
        self.noWalletView.hidden = YES;
    }
}

#pragma mark - ------public------

#pragma mark - ------delegate & datasource------

#pragma mark - ------eventResponse------
- (void)routeEventWithName:(NSString *)eventName userInfo:(NSDictionary *)userinfo{
    if ([eventName isEqualToString:RouteNameEvent_TransactionRecordDetail]){
        ApexWalletModel *model = userinfo[@"wallet"];
        ApexTransactionDetailController *detailVC = [[ApexTransactionDetailController alloc] init];
        detailVC.model = model;
        detailVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:detailVC animated:YES];
    }
    
}

- (void)back{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - ------getter & setter------
- (ApexTransactionRecordView *)transactionView{
    if (!_transactionView) {
        _transactionView = [[ApexTransactionRecordView alloc] initWithFrame:self.view.bounds];
    }
    return _transactionView;
}

- (UILabel *)titleL{
    if (!_titleL) {
        _titleL = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
        _titleL.textAlignment = NSTextAlignmentCenter;
        _titleL.text = SOLocalizedStringFromTable(@"Transaction Records", nil);
        _titleL.textColor = [UIColor whiteColor];
    }
    return _titleL;
}

- (UIImageView *)fakeNavBar{
    if (!_fakeNavBar) {
        _fakeNavBar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"barImage"]];
    }
    return _fakeNavBar;
}

- (ApexNoWalletView *)noWalletView{
    if (!_noWalletView) {
        _noWalletView = [[ApexNoWalletView alloc] init];
        [_noWalletView setMessage:SOLocalizedStringFromTable(@"Data Empty", nil)];
        [_noWalletView setBtnHidden:YES];
    }
    return _noWalletView;
}
@end
