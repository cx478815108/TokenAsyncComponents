//
//  TokenAsyncLabel.m
//  TokenOperation
//
//  Created by 陈雄 on 2018/5/22.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenAsyncLabel.h"
#import "TokenAsyncLayer.h"
#import "TokenOperationQueue.h"
#import <CoreText/CoreText.h>

@interface TokenAsyncLayer ()<TokenAsyncLayerDelegate>
@end

@implementation TokenAsyncLabel{
    NSMutableAttributedString *_displayText;
    TokenTextLayout           *_textLayout;
    struct {
        unsigned int plainTextNeedUpdate : 1;
        unsigned int fontNeedUpdate : 1;
        unsigned int colorNeedUpdate : 1;
        unsigned int numberOfLinesNeedUpdate : 1;
        unsigned int alignmentNeedUpdate : 1;
        unsigned int lineBreakModeNeedUpdate : 1;
        unsigned int trunctionNeedUpdate : 1;
        unsigned int trunctionFadeNeedUpdate : 1;
        unsigned int textInsetsNeedUpdate : 1;
        unsigned int trunctionDisplayTypeNeedUpdate : 1;
    } _updateInfo;
}

+(Class)layerClass{
    return TokenAsyncLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _displayText          = [NSMutableAttributedString new];
        _font                 = [UIFont systemFontOfSize:17.0f];
        _textColor            = [UIColor darkTextColor];
        _textAlignment        = NSTextAlignmentLeft;
        _lineBreakMode        = NSLineBreakByTruncatingTail;
        _truncationToken      = [[NSAttributedString alloc] initWithString:@"..."];
        _numberOfLines        = 1;
        _trunctionDisplayType = TokenTrunctionTypeToken;
        _trunctionFadeLength  = 30.0f;
        _textInsets = UIEdgeInsetsMake(2, 2, 0, 0);
    }
    return self;
}

-(void)forceUpdate{
    [self.layer setNeedsDisplay];
}

#pragma mark - setter
-(void)setAsyncDisplay:(BOOL)asyncDisplay{
    _asyncDisplay = asyncDisplay;
    ((TokenAsyncLayer *)self.layer).asyncDisplay = asyncDisplay;
}

-(void)setFrame:(CGRect)frame{
    CGSize oldSize = self.bounds.size;
    [super setFrame:frame];
    CGSize newSize = self.bounds.size;
    if (!CGSizeEqualToSize(oldSize, newSize)) {
        [self.layer setNeedsDisplay];
    }
}

-(void)setBounds:(CGRect)bounds{
    CGSize oldSize = self.bounds.size;
    [super setBounds:bounds];
    CGSize newSize = self.bounds.size;
    if (!CGSizeEqualToSize(oldSize, newSize)) {
        [self.layer setNeedsDisplay];
    }
}

-(void)setFont:(UIFont *)font {
    if (_font == font && _updateInfo.fontNeedUpdate == NO) return;
    _font = font?font:[UIFont systemFontOfSize:17.0f];
    [_displayText addAttribute:NSFontAttributeName value:_font range:NSMakeRange(0, _displayText.length)];
    _updateInfo.fontNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(void)setText:(NSString *)text {
    if ([_text isEqualToString:text] && _updateInfo.plainTextNeedUpdate == NO) return ;
    _updateInfo.plainTextNeedUpdate = NO;
    _text = text;
    [_displayText replaceCharactersInRange:NSMakeRange(0, _displayText.length) withString:text?text:@""];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment                = self.textAlignment;
    style.lineBreakMode            = self.lineBreakMode;
    [_displayText setAttributes:@{
                                  NSFontAttributeName:_font,
                                  NSForegroundColorAttributeName:_textColor,
                                  NSParagraphStyleAttributeName:style
                                  }
                          range:NSMakeRange(0, _displayText.length)];
    [self.layer setNeedsDisplay];
}

-(void)setAttributedText:(NSAttributedString *)attributedText {
    if ([_attributedText isEqualToAttributedString:attributedText]) { return ;}
    _updateInfo     = (typeof(_updateInfo)){YES,YES,YES,YES,YES,YES,YES,YES,YES,YES};
    _attributedText = attributedText?attributedText.copy:[NSMutableAttributedString new];
    _displayText    = [[NSMutableAttributedString alloc] initWithAttributedString:_attributedText];
    [self.layer setNeedsDisplay];
}

-(void)setNumberOfLines:(NSInteger)numberOfLines{
    if (_numberOfLines == numberOfLines &&
        _updateInfo.numberOfLinesNeedUpdate == NO) return;
    _numberOfLines = numberOfLines;
    _updateInfo.numberOfLinesNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(void)setTextColor:(UIColor *)textColor {
    if (_textColor == textColor && _updateInfo.colorNeedUpdate == NO) return;
    _textColor = textColor?textColor:[UIColor clearColor];
    [_displayText addAttribute:NSForegroundColorAttributeName value:_textColor range:NSMakeRange(0, _displayText.length)];
    _updateInfo.colorNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(void)setLineBreakMode:(NSLineBreakMode)lineBreakMode{
    if (_lineBreakMode == lineBreakMode &&
        _updateInfo.lineBreakModeNeedUpdate == NO) return;
    _lineBreakMode = lineBreakMode;
    _updateInfo.lineBreakModeNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment{
    if (_textAlignment == textAlignment &&
        _updateInfo.alignmentNeedUpdate == NO) return;
    _textAlignment = textAlignment;
    _updateInfo.alignmentNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(void)setTruncationToken:(NSAttributedString *)truncationToken{
    if (_truncationToken == truncationToken &&
        _updateInfo.trunctionNeedUpdate == NO) return;
    _truncationToken = [truncationToken copy];
    _updateInfo.trunctionNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(void)setTrunctionFadeLength:(CGFloat)trunctionFadeLength{
    if (_trunctionFadeLength == trunctionFadeLength &&
        !_updateInfo.trunctionFadeNeedUpdate == NO ) return ;
    _trunctionFadeLength = trunctionFadeLength;
    _updateInfo.trunctionFadeNeedUpdate = NO;
    if (_trunctionDisplayType == TokenTrunctionTypeToken) return;
    [self.layer setNeedsDisplay];
}

-(void)setTrunctionDisplayType:(TokenTrunctionType)trunctionDisplayType{
    if (_trunctionDisplayType == trunctionDisplayType &&
        !_updateInfo.trunctionDisplayTypeNeedUpdate == NO) return ;
    _trunctionDisplayType = trunctionDisplayType;
    _updateInfo.trunctionDisplayTypeNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(void)setTextInsets:(UIEdgeInsets)textInsets {
    if (UIEdgeInsetsEqualToEdgeInsets(_textInsets, textInsets)
        && !_updateInfo.textInsetsNeedUpdate == NO) return ;
    _textInsets = textInsets;
    _updateInfo.textInsetsNeedUpdate = NO;
    [self.layer setNeedsDisplay];
}

-(CGSize)intrinsicContentSize{
    CGSize size = CGSizeMake(self.preferredMaxLayoutWidth, CGFLOAT_MAX);
    TokenTextLayout *layout     = [TokenTextLayout layoutWithText:_displayText constraintedSize:size];
    layout.lineBreakMode        = _lineBreakMode;
    layout.truncationToken      = _truncationToken;
    layout.numberOfLines        = _numberOfLines;
    layout.exclusionPaths       = _exclusionPaths;
    layout.trunctionDisplayType = _trunctionDisplayType;
    layout.trunctionFadeLength  = _trunctionFadeLength;
    layout.textAlignment        = _textAlignment;
    [layout calculateLayout];
    return layout.textSize;
}

-(void)invalidTextLayout{
    _textLayout = nil;
}

#pragma mark - TokenAsyncLayerDelegate
-(TokenDisplayTask *)produceAsyncDisplayTask {
    NSAttributedString *text                 = [_displayText copy];
    NSArray             *exclusionPaths      = _exclusionPaths;
    NSInteger           numberOfLines        = _numberOfLines==0?NSIntegerMax:_numberOfLines;
    NSAttributedString *truncatingToken      = _truncationToken.copy;
    TokenTrunctionType  trunctionDisplayType = _trunctionDisplayType;
    CGFloat             trunctionFadeLength  = _trunctionFadeLength;
    NSTextAlignment     textAlignment        = _textAlignment;
    NSLineBreakMode     lineBreakMode        = _lineBreakMode;
    UIEdgeInsets        textInsets           = _textInsets;

    TokenDisplayTask *task = [TokenDisplayTask new];
    task.displayBlock      = ^(CGContextRef context,CGRect bounds) {

        @autoreleasepool{
            TokenTextLayout *layout     = [TokenTextLayout layoutWithText:text constraintedSize:bounds.size];
            layout.lineBreakMode        = lineBreakMode;
            layout.truncationToken      = truncatingToken;
            layout.numberOfLines        = numberOfLines;
            layout.exclusionPaths       = exclusionPaths;
            layout.trunctionDisplayType = trunctionDisplayType;
            layout.trunctionFadeLength  = trunctionFadeLength;
            layout.textAlignment        = textAlignment;
            layout.textInsets           = textInsets;
            [layout calculateLayout];
            [layout drawInContext:context];
        }
    };
    return task;
}
@end

