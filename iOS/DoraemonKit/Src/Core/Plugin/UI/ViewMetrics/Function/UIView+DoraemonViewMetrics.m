//
//  UIView+DoraemonViewMetrics.m
//  DoraemonKit
//
//  Created by xgb on 2018/12/11.
//

#import "UIView+DoraemonViewMetrics.h"
#import "DoraemonViewMetricsConfig.h"
#import "NSObject+Doraemon.h"
#import <objc/runtime.h>
#import "DoraemonDefine.h"


@interface UIView ()

@property (nonatomic ,strong) CALayer *metricsBorderLayer;

@end


@implementation UIView (DoraemonViewMetrics)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[self class] doraemon_swizzleInstanceMethodWithOriginSel:@selector(layoutSubviews) swizzledSel:@selector(doraemon_layoutSubviews)];
    });
}

- (void)doraemon_layoutSubviews
{
    [self doraemon_layoutSubviews];
    if (DoraemonViewMetricsConfig.defaultConfig.opened) {
        [self doraemonMetricsRecursiveEnable:DoraemonViewMetricsConfig.defaultConfig.enable];
    }
}

- (void)doraemonMetricsRecursiveEnable:(BOOL)enable
{
    // 状态栏不显示元素边框
    UIView * statusBarView =  [[UIApplication sharedApplication] valueForKey:@"_statusBar"];
    if(statusBarView && [self isDescendantOfView:statusBarView.window]){
        return;
    }

    for (UIView *subView in self.subviews) {
        [subView doraemonMetricsRecursiveEnable:enable];
    }
    
    if (enable) {
        if (!self.metricsBorderLayer) {
            UIColor *borderColor = DoraemonViewMetricsConfig.defaultConfig.borderColor ? DoraemonViewMetricsConfig.defaultConfig.borderColor : UIColor.doraemon_randomColor;
            self.metricsBorderLayer = ({
                CALayer *layer = CALayer.new;
                layer.borderWidth = DoraemonViewMetricsConfig.defaultConfig.borderWidth;
                layer.borderColor = borderColor.CGColor;
                layer;
            });
            [self.layer addSublayer:self.metricsBorderLayer];
        }
        
        self.metricsBorderLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        self.metricsBorderLayer.hidden = NO;
    } else if (self.metricsBorderLayer) {
        self.metricsBorderLayer.hidden = YES;
    }
}

- (void)setMetricsBorderLayer:(CALayer *)metricsBorderLayer
{
    objc_setAssociatedObject(self, @selector(metricsBorderLayer), metricsBorderLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CALayer *)metricsBorderLayer
{
    return objc_getAssociatedObject(self, _cmd);
}
@end
