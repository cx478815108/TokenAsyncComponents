//
//  TokenTextDrawer.h
//  TokenOperation
//
//  Created by 陈雄 on 2018/6/6.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreText;
@import UIKit;

UIKIT_EXTERN NSString *const TokenTextBorderAttributeName;

CGFloat TokenScreenScale(void);
CGFloat TokenRoundPixelValue(CGFloat f);
CTLineTruncationType TokenLineTruncationTypeFromLineBreakMode(NSLineBreakMode mode);

typedef NS_OPTIONS (NSInteger, TokenLineStyle) {
    // basic style (bitmask:0xFF)
    TokenLineStyleNone       = 0x00, ///< (        ) Do not draw a line (Default).
    TokenLineStyleSingle     = 0x01, ///< (──────) Draw a single line.

    // style pattern (bitmask:0xF00)
    TokenLineStylePatternSolid      = 0x000, ///< (────────) Draw a solid line (Default).
    TokenLineStylePatternDot        = 0x100, ///< (‑ ‑ ‑ ‑ ‑ ‑) Draw a line of dots.
    TokenLineStylePatternDash       = 0x200, ///< (— — — —) Draw a line of dashes.
    TokenLineStylePatternDashDot    = 0x300, ///< (— ‑ — ‑ — ‑) Draw a line of alternating dashes and dots.
    TokenLineStylePatternDashDotDot = 0x400, ///< (— ‑ ‑ — ‑ ‑) Draw a line of alternating dashes and two dots.
    TokenLineStylePatternCircleDot  = 0x900, ///< (••••••••••••) Draw a line of small circle dots.
};

typedef NS_ENUM(NSUInteger, TokenTrunctionType) {
    TokenTrunctionTypeToken,
    TokenTrunctionTypeLinearGradient
};

void TokenTextSetLinePatternInContext(TokenLineStyle style,
                                      CGFloat width,
                                      CGFloat phase,
                                      CGFloat space,
                                      CGContextRef context) __attribute__((unused));

@interface TokenTextLine : NSObject
@property (nonatomic, readonly) CTLineRef CTLine;
@property (nonatomic, readonly) NSRange   stringRange;
@property (nonatomic, readonly) CGSize    size;
@property (nonatomic, readonly) CGPoint   position;
@end

@interface TokenTextBorder : NSObject<NSCoding,NSCopying>
@property(nonatomic,assign) TokenLineStyle     lineStyle;
@property(nonatomic,assign) CGFloat            borderWidth;
@property(nonatomic,assign) CGFloat            dashSpace;
@property(nonatomic,copy  ) UIColor           *borderColor;
@property(nonatomic,copy  ) UIColor           *backgroundColor;
@property(nonatomic,assign) UIEdgeInsets       insets;
@property(nonatomic,assign) CGFloat            cornerRadius;
@end

@interface TokenTextLayout: NSObject
@property(nonatomic ,copy  ) NSAttributedString               *text;
@property(nonatomic ,assign) UIEdgeInsets                      textInsets;
@property(nonatomic ,strong) NSMutableArray <TokenTextLine *> *lines;
@property(nonatomic ,strong) NSArray <UIBezierPath *>         *exclusionPaths;
@property(nonatomic ,copy  ) NSAttributedString               *truncationToken;
@property(nonatomic ,assign) TokenTrunctionType                trunctionDisplayType;
@property(nonatomic ,assign) CGFloat                           trunctionFadeLength;
@property(nonatomic ,assign) NSInteger                         numberOfLines;
@property(nonatomic ,assign) NSLineBreakMode                   lineBreakMode;
@property(nonatomic ,assign) NSTextAlignment                   textAlignment;
@property(nonatomic ,assign) CGSize                            constraintedSize;

+(instancetype)layoutWithText:(NSAttributedString *)text
             constraintedSize:(CGSize)constraintedSize;

-(void)calculateLayout;
-(void)drawInContext:(CGContextRef)context;

-(CGSize)textSize;
@end
