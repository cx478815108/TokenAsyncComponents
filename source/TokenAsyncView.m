//
//  TokenAsyncView.m
//  NewHybrid
//
//  Created by 陈雄 on 2018/6/12.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenAsyncView.h"
#import "TokenAsyncLayer.h"

TokenRadius TokenRadiusMake(CGFloat leftTopRadius,
                            CGFloat rightTopRadius,
                            CGFloat leftBottomRadius,
                            CGFloat rightBottomRadius) {
    TokenRadius radius;
    radius.leftTopRadius     = leftTopRadius;
    radius.rightTopRadius    = rightTopRadius;
    radius.leftBottomRadius  = leftBottomRadius;
    radius.rightBottomRadius = rightBottomRadius;
    return radius;
}

BOOL TokenRadiusEqual(TokenRadius a,TokenRadius b){
    return (a.leftTopRadius     == b.leftTopRadius)    &&
           (a.rightTopRadius    == b.rightTopRadius)   &&
           (a.leftBottomRadius  == b.leftBottomRadius) &&
           (a.rightBottomRadius == b.rightBottomRadius);
}

static UIBezierPath *UIBezierPathFromTokenRadius(TokenRadius radius,CGRect bounds){
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path addArcWithCenter:CGPointMake(bounds.size.width - radius.rightTopRadius, bounds.size.height - radius.rightTopRadius) radius:radius.rightTopRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
    [path addArcWithCenter:CGPointMake(radius.leftTopRadius, bounds.size.height - radius.leftTopRadius) radius:radius.leftTopRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
    [path addArcWithCenter:CGPointMake(radius.leftBottomRadius, radius.leftBottomRadius) radius:radius.leftBottomRadius startAngle:M_PI endAngle:3.0 * M_PI_2 clockwise:YES];
    [path addArcWithCenter:CGPointMake(bounds.size.width - radius.rightBottomRadius, radius.rightBottomRadius) radius:radius.rightBottomRadius startAngle:3.0 * M_PI_2 endAngle:2.0 * M_PI clockwise:YES];
    return path;
}

@interface TokenAsyncView()<TokenAsyncLayerDelegate>
@end

@implementation TokenAsyncView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self prepareForDraw];

    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareForDraw];
    }
    return self;
}

-(void)prepareForDraw{
    _asyncDisplay                  = YES;
    _borderStyle                   = TokenBorderDirectionAll;
    _dotSpace                      = 2.0f;
    self.backgroundColor           = [UIColor clearColor];
    _ignoreOriginalBackgroundColor = YES;
}

+(Class)layerClass{
    return TokenAsyncLayer.class;
}

#pragma mark - setter
-(void)setFrame:(CGRect)frame{
    CGRect oldFrame = self.frame;
    [super setFrame:frame];
    if (!CGRectEqualToRect(oldFrame, oldFrame)) {
        [self.layer setNeedsDisplay];
    }
}

-(void)setBounds:(CGRect)bounds{
    CGRect oldbounds = self.bounds;
    [super setBounds:bounds];
    if (!CGRectEqualToRect(oldbounds, bounds)) {
        [self.layer setNeedsDisplay];
    }
}

-(void)setBackgroundColor:(UIColor *)backgroundColor{
    if (_ignoreOriginalBackgroundColor) {
        _ctxBackgroundColor = [backgroundColor copy];
        [self.layer setNeedsDisplay];
    }
    else {
        [super setBackgroundColor:backgroundColor];
    }
}

-(void)setAsyncDisplay:(BOOL)asyncDisplay{
    _asyncDisplay = asyncDisplay;
    ((TokenAsyncLayer *)self.layer).asyncDisplay = asyncDisplay;
}

-(void)setCornerRadius:(CGFloat)cornerRadius{
    if (_cornerRadius == cornerRadius) return;
    _cornerRadius = cornerRadius;
    _specialRadius = TokenRadiusMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
    [self.layer setNeedsDisplay];
}

-(void)setSpecialRadius:(TokenRadius)specialRadius{
    if (TokenRadiusEqual(_specialRadius, specialRadius)) return;
    _specialRadius = specialRadius;
    [self.layer setNeedsDisplay];
}

-(void)setBorderWidth:(CGFloat)borderWidth{
    if (_borderWidth == borderWidth) return;
    _borderWidth = borderWidth;
    [self.layer setNeedsDisplay];
}

-(void)setBorderColor:(UIColor *)borderColor{
    if (_borderColor == borderColor) return;
    _borderColor = [borderColor copy];
    [self.layer setNeedsDisplay];
}

-(void)setBorderStyle:(TokenBorderDirection)borderStyle{
    if (_borderStyle == borderStyle) return;
    _borderStyle = borderStyle;
    [self.layer setNeedsDisplay];
}

-(void)setCtxBackgroundColor:(UIColor *)ctxBackgroundColor{
    if (_ctxBackgroundColor == ctxBackgroundColor) return;
    _ctxBackgroundColor = [ctxBackgroundColor copy];
    [self.layer setNeedsDisplay];
}

-(void)setLineStyle:(TokenLineStyle)lineStyle{
    if (_lineStyle == lineStyle) return;
    _lineStyle = lineStyle;
    [self.layer setNeedsDisplay];
}

-(void)setDotSpace:(CGFloat)dotSpace{
    if (_dotSpace == dotSpace) return;
    _dotSpace = dotSpace;
    [self.layer setNeedsDisplay];
}

-(void)setShadow:(NSShadow *)shadow{
    if (_shadow == shadow) return;
    _shadow = [shadow copy];
    [self.layer setNeedsDisplay];
}

#pragma mark - TokenAsyncLayerDelegate
-(TokenDisplayTask *)produceAsyncDisplayTask {
    UIColor *backgroundColor         = self.ctxBackgroundColor;
    CGFloat borderWidth              = self.borderWidth;
    TokenLineStyle lineStyle         = self.lineStyle;
    UIEdgeInsets borderInsets        = self.borderInsets;
    UIColor *borderColor             = self.borderColor;
    TokenBorderDirection borderStyle = self.borderStyle;
    CGFloat dotSpace                 = self.dotSpace;
    NSShadow *shadow                 = self.shadow;
    TokenRadius radiusZero           = TokenRadiusMake(0, 0, 0, 0);
    TokenRadius specialRadius;         // transform
    specialRadius.leftBottomRadius   = self.specialRadius.leftTopRadius;
    specialRadius.rightTopRadius     = self.specialRadius.rightBottomRadius;
    specialRadius.leftTopRadius      = self.specialRadius.leftBottomRadius;
    specialRadius.rightBottomRadius  = self.specialRadius.rightTopRadius;

    TokenDisplayTask *task = [TokenDisplayTask new];
    task.displayBlock      = ^(CGContextRef context,CGRect bounds) {
        
        UIBezierPath *visiblePath;
        //cornerRadius
        if (!TokenRadiusEqual(specialRadius,radiusZero)) {
            visiblePath = UIBezierPathFromTokenRadius(specialRadius, bounds);
        }
        else {
            visiblePath = [UIBezierPath bezierPathWithRect:bounds];
        }
        
        //backgroundColor
        if (backgroundColor) { [backgroundColor setFill];}
        
        CGContextAddPath(context, visiblePath.CGPath);
        CGContextFillPath(context);
        
        if (shadow && shadow.shadowColor) {
            CGContextSaveGState(context);
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddRect(path, NULL, CGRectInset(bounds, -11, -11));
            CGPathAddPath(path, NULL, visiblePath.CGPath);
            CGPathCloseSubpath(path);
            CGContextAddPath(context, visiblePath.CGPath);
            CGContextClip(context);

            if ([shadow.shadowColor isKindOfClass:[UIColor class]]) {
                UIColor *color = shadow.shadowColor;
                CGContextSetShadowWithColor(context, shadow.shadowOffset,shadow.shadowBlurRadius, color.CGColor);
                [color setFill];
            }
            CGContextAddPath(context, path);
            CGContextEOFillPath(context);
            CGPathRelease(path);
            CGContextRestoreGState(context);
        }
        
        if (borderWidth < 0.1  ||
            borderColor == nil ||
            borderStyle == TokenBorderDirectionNone) return;
        
        // border
        CGContextSaveGState(context);
        if (TokenRadiusEqual(specialRadius, radiusZero)) {
            CGFloat width  = bounds.size.width;
            CGFloat height = bounds.size.width;
            
            CGPoint leftTopPoint     = CGPointMake(borderInsets.left, borderInsets.top);
            CGPoint rightTopPoint    = CGPointMake(width-borderInsets.right, borderInsets.top);
            CGPoint leftBottomPoint  = CGPointMake(borderInsets.left, height-borderInsets.bottom);
            CGPoint rightBottomPoint = CGPointMake(width-borderInsets.right, height-borderInsets.bottom);
            
            if (borderStyle & TokenBorderDirectionTop) { //border - top
                CGContextMoveToPoint(context, leftTopPoint.x, leftTopPoint.y);
                CGContextAddLineToPoint(context, rightTopPoint.x, rightTopPoint.y);
            }
            
            if (borderStyle & TokenBorderDirectionRight){ //border - right
                CGContextMoveToPoint(context, rightTopPoint.x, rightTopPoint.y);
                CGContextAddLineToPoint(context, rightBottomPoint.x, rightBottomPoint.y);
            }
            
            if (borderStyle & TokenBorderDirectionBottom){ //border - bottom
                CGContextMoveToPoint(context, leftBottomPoint.x, leftBottomPoint.y);
                CGContextAddLineToPoint(context, rightBottomPoint.x, rightBottomPoint.y);
            }
            
            if (borderStyle & TokenBorderDirectionLeft){ //border - left
                CGContextMoveToPoint(context, leftTopPoint.x, leftTopPoint.y);
                CGContextAddLineToPoint(context, leftBottomPoint.x, leftBottomPoint.y);
            }
        }
        
        else if (borderStyle == TokenBorderDirectionAll) {
            UIBezierPath *linePath = UIBezierPathFromTokenRadius(specialRadius, UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(borderWidth,borderWidth,borderWidth,borderWidth)));
            [linePath closePath];
            CGAffineTransform trans = CGAffineTransformTranslate(CGAffineTransformIdentity, borderWidth, borderWidth);
            CGPathRef lineCGPath    =  CGPathCreateMutableCopyByTransformingPath(linePath.CGPath, &trans);
            CGContextAddPath(context, lineCGPath);
            CGPathRelease(lineCGPath);
        }
            
        // line style
        TokenTextSetLinePatternInContext(lineStyle, borderWidth, 0, dotSpace, context);
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    };
    return task;
}

@end
