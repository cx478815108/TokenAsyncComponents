//
//  TokenAsyncView.h
//  NewHybrid
//
//  Created by 陈雄 on 2018/6/12.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TokenContextDrawer.h"

typedef NS_OPTIONS(NSUInteger, TokenBorderDirection) {
    TokenBorderDirectionNone         = 1 << 0,
    TokenBorderDirectionTop          = 1 << 1,
    TokenBorderDirectionBottom       = 1 << 2,
    TokenBorderDirectionLeft         = 1 << 3,
    TokenBorderDirectionRight        = 1 << 4,
    TokenBorderDirectionAll          = TokenBorderDirectionTop |
                                       TokenBorderDirectionBottom |
                                       TokenBorderDirectionLeft |
                                       TokenBorderDirectionRight
};

struct TokenRadius {
    CGFloat leftTopRadius;
    CGFloat rightTopRadius;
    CGFloat leftBottomRadius;
    CGFloat rightBottomRadius;
};

typedef struct TokenRadius TokenRadius;

TokenRadius TokenRadiusMake(CGFloat leftTopRadius,
                            CGFloat rightTopRadius,
                            CGFloat leftBottomRadius,
                            CGFloat rightBottomRadius);

BOOL TokenRadiusEqual(TokenRadius a,TokenRadius b);

@interface TokenAsyncView : UIView
@property(nonatomic ,assign) BOOL                  ignoreOriginalBackgroundColor; // default is YES.  The backgroundColor properity of UIView will be ignore
@property(nonatomic ,assign) BOOL                  asyncDisplay;
@property(nonatomic ,assign) TokenLineStyle        lineStyle;// will change the border line style see TokenContextDrawer.h
@property(nonatomic ,assign) CGFloat               dotSpace;     // the space
@property(nonatomic ,assign) CGFloat               cornerRadius;
@property(nonatomic ,assign) TokenRadius           specialRadius; //you can specify the left,right,top,bottom radius
@property(nonatomic ,assign) UIEdgeInsets          borderInsets;
@property(nonatomic ,assign) CGFloat               borderWidth;
@property(nonatomic ,assign) TokenBorderDirection  borderStyle;// see TokenContextDrawer.h
@property(nonatomic ,copy  ) UIColor              *borderColor;
@property(nonatomic ,copy  ) UIColor              *ctxBackgroundColor; //instead of backgroundColor properity of UIView
@property(nonatomic ,copy  ) NSShadow             *shadow; //inner shadow
@end
