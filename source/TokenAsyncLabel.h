//
//  TokenAsyncLabel.h
//  TokenOperation
//
//  Created by 陈雄 on 2018/5/22.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TokenContextDrawer.h"

@interface TokenAsyncLabel : UIView
@property(nonatomic ,copy  ) NSString                *text;
@property(nonatomic ,strong) UIFont                  *font;
@property(nonatomic ,strong) UIColor                 *textColor;
@property(nonatomic ,copy  ) NSAttributedString      *attributedText;
@property(nonatomic ,strong) NSArray<UIBezierPath *> *exclusionPaths;// not implemented
@property(nonatomic ,assign) NSTextAlignment          textAlignment;
@property(nonatomic ,assign) NSLineBreakMode          lineBreakMode;
@property(nonatomic ,assign) NSInteger                numberOfLines;
@property(nonatomic ,copy  ) NSAttributedString      *truncationToken; // default is "..."
@property(nonatomic ,assign) TokenTrunctionType       trunctionDisplayType;
@property(nonatomic ,assign) CGFloat                  trunctionFadeLength; // default is 30.0f
@property(nonatomic ,assign) UIEdgeInsets             textInsets;
@property(nonatomic ,assign) CGFloat                  preferredMaxLayoutWidth;
@property(nonatomic ,assign) BOOL                     asyncDisplay;
-(void)forceUpdate;
@end
