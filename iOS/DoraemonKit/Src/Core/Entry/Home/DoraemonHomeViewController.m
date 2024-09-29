//
//  DoraemonHomeViewController.m
//  DoraemonKit
//
//  Created by dengyouhua on 2019/9/4.
//

#import "DoraemonHomeViewController.h"
#import "UIView+Doraemon.h"
#import "UIColor+Doraemon.h"
#import "DoraemonManager.h"
#import "DoraemonPluginProtocol.h"
#import "DoraemonHomeWindow.h"
#import "DoraemonDefine.h"
#import "DoraemonHomeCell.h"
#import "DoraemonHomeHeadCell.h"
#import "DoraemonHomeFootCell.h"
#import "DoraemonHomeCloseCell.h"
#import "UIViewController+Doraemon.h"
#import "DoraemonBuriedPointManager.h"
#import "DoraemonSettingViewController.h"
#import "DoraemonCacheManager.h"

static NSString *DoraemonHomeCellID = @"DoraemonHomeCellID";
static NSString *DoraemonHomeHeadCellID = @"DoraemonHomeHeadCellID";
static NSString *DoraemonHomeFootCellID = @"DoraemonHomeFootCellID";
static NSString *DoraemonHomeCloseCellID = @"DoraemonHomeCloseCellID";

@interface DoraemonHomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic,strong) NSMutableArray *dataArray;

@end

@implementation DoraemonHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DoKit";
    [self setLeftNavBarItems:nil];
    [self setRightNavTitle:DoraemonLocalizedString(@"设置")];
    
    
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    } else {
#endif
        self.view.backgroundColor = [UIColor whiteColor];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
    }
#endif
    NSMutableArray *dataArray = [[DoraemonCacheManager sharedInstance] allKitShowManagerData];
    _dataArray = dataArray;
    [self.view addSubview:self.collectionView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kitManagerUpdate:) name:DoraemonKitManagerUpdateNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.collectionView.frame = [self fullscreen];
}

- (void)rightNavTitleClick:(id)clickView{
    DoraemonSettingViewController *vc = [[DoraemonSettingViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)kitManagerUpdate:(NSNotification *)aNotification {
    _dataArray = [[DoraemonCacheManager sharedInstance] allKitShowManagerData];
    [self.collectionView reloadData];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -- UICollectionView
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *fl = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:fl];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
        if (@available(iOS 13.0, *)) {
            _collectionView.backgroundColor = [UIColor systemBackgroundColor];
        } else {
#endif
            _collectionView.backgroundColor = [UIColor whiteColor];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
        }
#endif
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[DoraemonHomeCell class] forCellWithReuseIdentifier:DoraemonHomeCellID];
        [_collectionView registerClass:[DoraemonHomeCloseCell class] forCellWithReuseIdentifier:DoraemonHomeCloseCellID];
        [_collectionView registerClass:[DoraemonHomeHeadCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:DoraemonHomeHeadCellID];
        [_collectionView registerClass:[DoraemonHomeFootCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:DoraemonHomeFootCellID];
    }
    
    return _collectionView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < _dataArray.count) {
        return CGSizeMake(kDoraemonSizeFrom750_Landscape(160), kDoraemonSizeFrom750_Landscape(128));
    } else {
        return CGSizeMake(DoraemonScreenWidth, kDoraemonSizeFrom750_Landscape(100));
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section < _dataArray.count) {
        return CGSizeMake(DoraemonScreenWidth, kDoraemonSizeFrom750_Landscape(88));
    } else {
        return CGSizeMake(DoraemonScreenWidth, 0);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section < _dataArray.count) {
        return CGSizeMake(DoraemonScreenWidth, kDoraemonSizeFrom750_Landscape(24));
    } else {
        return CGSizeMake(DoraemonScreenWidth, kDoraemonSizeFrom750_Landscape(80));
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    view.layer.zPosition = 0.0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _dataArray.count + 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section < self.dataArray.count) {
        NSDictionary *dict = _dataArray[section];
        NSArray *pluginArray = dict[@"pluginArray"];
        return pluginArray.count;
    } else {
        return 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    
    if (section < _dataArray.count) {
        DoraemonHomeCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:DoraemonHomeCellID forIndexPath:indexPath];
        NSDictionary *dict = _dataArray[section];
        NSArray *pluginArray = dict[@"pluginArray"];
        NSDictionary *item = pluginArray[row];
        [cell update:item[@"icon"] name:item[@"name"]];
        [cell updateImage:item[@"image"]];
        return cell;
    } else {
        DoraemonHomeCloseCell *closeCell = [collectionView dequeueReusableCellWithReuseIdentifier:DoraemonHomeCloseCellID forIndexPath: indexPath];
        return closeCell;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        DoraemonHomeHeadCell *head = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:DoraemonHomeHeadCellID  forIndexPath:indexPath];
        [head renderUIWithTitle:nil];
        NSInteger section = indexPath.section;
        if (section < _dataArray.count) {
            NSDictionary *dict = _dataArray[section];
            [head renderUIWithTitle:dict[@"moduleName"]];
        }
        
        view = head;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        DoraemonHomeFootCell *foot = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:DoraemonHomeFootCellID forIndexPath:indexPath];
        UIColor *dyColor;
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
        if (@available(iOS 13.0, *)) {
            __weak typeof(self) weakSelf = self;
            dyColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                    return [UIColor doraemon_colorWithString:@"#F4F5F6"];
                } else {
                    if (indexPath.section >= weakSelf.dataArray.count) {
                        return [UIColor systemBackgroundColor];
                    } else {
                        return [UIColor doraemon_colorWithString:@"#353537"];
                    }
                }
            }];
        } else {
#endif
            dyColor = [UIColor doraemon_colorWithString:@"#F4F5F6"];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
        }
#endif
        if (indexPath.section >= self.dataArray.count) {
            NSString *str = DoraemonLocalizedString(@"当前版本");
            NSString *last = [NSString stringWithFormat:@"%@：V%@", str, DoKitVersion];
            foot.title.text = last;
            foot.title.textColor = [UIColor doraemon_colorWithString:@"#999999"];
            foot.title.textAlignment = NSTextAlignmentCenter;
            foot.title.font = [UIFont systemFontOfSize:kDoraemonSizeFrom750_Landscape(24)]; // kDoraemonSizeFrom750
        } else {
            foot.title.text = nil;
        }
        foot.backgroundColor = dyColor;
        view = foot;
    }else{
        view = [[UICollectionReusableView alloc] init];
    }
    
    return view;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (section < _dataArray.count)
        return UIEdgeInsetsMake(0, kDoraemonSizeFrom750_Landscape(24), kDoraemonSizeFrom750_Landscape(24), kDoraemonSizeFrom750_Landscape(24));//分别为上、左、下、右
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    if (section < self.dataArray.count) {
        NSDictionary *dict = _dataArray[section];
        NSArray *pluginArray = dict[@"pluginArray"];
        NSDictionary *itemData = pluginArray[indexPath.row];
        NSString *pluginName = itemData[@"pluginName"];
        if(pluginName){
            DoKitBP(itemData[@"buriedPoint"])
            Class pluginClass = NSClassFromString(pluginName);
            id<DoraemonPluginProtocol> plugin = [[pluginClass alloc] init];
            if ([plugin respondsToSelector:@selector(pluginDidLoad)]) {
                [plugin pluginDidLoad];
            }
            if ([plugin respondsToSelector:@selector(pluginDidLoad:)]) {
                [plugin pluginDidLoad:(NSDictionary *)itemData];
            }
            
            void (^handleBlock)(NSDictionary *itemData) = [DoraemonManager shareInstance].keyBlockDic[itemData[@"key"]];
            if (handleBlock) {
                handleBlock(itemData);
            }
        }
    }
}


@end
