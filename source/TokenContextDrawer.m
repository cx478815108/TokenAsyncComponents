//
//  TokenTextDrawer.m
//  TokenOperation
//
//  Created by 陈雄 on 2018/6/6.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenContextDrawer.h"
#import <CoreText/CoreText.h>

NSString *const TokenTextBorderAttributeName = @"TokenTextBorderAttribute";

CGFloat TokenScreenScale()
{
    // do not use UIKit API in the background thread
    static CGFloat scale = 0.0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 0);
        scale = CGContextGetCTM(UIGraphicsGetCurrentContext()).a;
        UIGraphicsEndImageContext();
    });
    return scale;
}

CGFloat TokenRoundPixelValue(CGFloat f)
{
    CGFloat scale = TokenScreenScale();
    return round(f * scale) / scale;
}

CTLineTruncationType TokenLineTruncationTypeFromLineBreakMode(NSLineBreakMode mode){
    CTLineTruncationType truncationType = kCTLineTruncationEnd;
    switch (mode) {
        case NSLineBreakByTruncatingTail:{
            truncationType = kCTLineTruncationEnd;
        } break;
        case NSLineBreakByTruncatingHead:{
            truncationType = kCTLineTruncationStart;
        } break;
        case NSLineBreakByTruncatingMiddle: {
            truncationType = kCTLineTruncationMiddle;
        } break;
        case NSLineBreakByClipping: {
            truncationType = kCTLineTruncationEnd;
        } break;
        default: break;
    }
    return truncationType;
}

void TokenTextSetLinePatternInContext(TokenLineStyle style,
                                      CGFloat width,
                                      CGFloat phase,
                                      CGFloat space,
                                      CGContextRef context){
    
    CGContextSetLineWidth(context, width);
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    
    CGFloat dash = 12, dot = 5;
    NSUInteger pattern = style & 0xF00;
    if (pattern == TokenLineStylePatternSolid) {
        CGContextSetLineDash(context, phase, NULL, 0);
    } else if (pattern == TokenLineStylePatternDot) {
        CGFloat lengths[2] = {width * dot, width * space};
        CGContextSetLineDash(context, phase, lengths, 2);
    } else if (pattern == TokenLineStylePatternDash) {
        CGFloat lengths[2] = {width * dash, width * space};
        CGContextSetLineDash(context, phase, lengths, 2);
    } else if (pattern == TokenLineStylePatternDashDot) {
        CGFloat lengths[4] = {width * dash, width * space, width * dot, width * space};
        CGContextSetLineDash(context, phase, lengths, 4);
    } else if (pattern == TokenLineStylePatternDashDotDot) {
        CGFloat lengths[6] = {width * dash, width * space,width * dot, width * space, width * dot, width * space};
        CGContextSetLineDash(context, phase, lengths, 6);
    } else if (pattern == TokenLineStylePatternCircleDot) {
        CGFloat lengths[2] = {width * 0, width * 3};
        CGContextSetLineDash(context, phase, lengths, 2);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineJoin(context, kCGLineJoinRound);
    }
}

#pragma mark -
@interface TokenTextLine()
@property(nonatomic,strong) NSMutableArray <TokenTextBorder *>*textBorders;
@property(nonatomic,strong) NSMutableArray <NSValue *>*textBorderFrames;
@end

@implementation TokenTextLine
+ (instancetype)lineWithCTLine:(CTLineRef)CTLine position:(CGPoint)position{
    if (!CTLine) return nil;
    TokenTextLine *line = [TokenTextLine new];
    line->_position = position;
    [line setCTLine:CTLine];
    return line;
}

-(void)setCTLine:(CTLineRef)CTLine{
    if (_CTLine == CTLine) return;
    if (CTLine) CFRetain(CTLine);
    if (_CTLine) CFRelease(_CTLine);
    _CTLine = CTLine;
    CGFloat lineWidth,ascent,descent;
    lineWidth = CTLineGetTypographicBounds(_CTLine, &ascent, &descent, NULL);
    _size  = CGSizeMake(lineWidth, ascent);
}

- (void)dealloc {
    if (_CTLine) CFRelease(_CTLine);
}
@end

#pragma mark -
@implementation TokenTextBorder
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_backgroundColor forKey:@"backgroundColor"];
    [aCoder encodeObject:_borderColor forKey:@"borderColor"];
    [aCoder encodeObject:@(_lineStyle) forKey:@"lineStyle"];
    [aCoder encodeObject:@(_borderWidth) forKey:@"borderWidth"];
    [aCoder encodeObject:@(_dashSpace) forKey:@"dashSpace"];
    [aCoder encodeObject:@(_cornerRadius) forKey:@"cornerRadius"];
    [aCoder encodeObject:[NSValue valueWithUIEdgeInsets:_insets] forKey:@"insets"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _backgroundColor = [aDecoder decodeObjectForKey:@"backgroundColor"];
        _borderColor     = [aDecoder decodeObjectForKey:@"borderColor"];
        _lineStyle       = [(NSNumber *)[aDecoder decodeObjectForKey:@"lineStyle"] integerValue];
        _borderWidth     = [(NSNumber *)[aDecoder decodeObjectForKey:@"borderWidth"] floatValue];
        _dashSpace       = [(NSNumber *)[aDecoder decodeObjectForKey:@"dashSpace"] floatValue];
        _cornerRadius    = [(NSNumber *)[aDecoder decodeObjectForKey:@"cornerRadius"] floatValue];
        _insets          = [(NSValue  *)[aDecoder decodeObjectForKey:@"insets"] UIEdgeInsetsValue];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    TokenTextBorder *obj = [self.class new];
    obj.lineStyle        = self.lineStyle;
    obj.borderWidth      = self.borderWidth;
    obj.dashSpace        = self.dashSpace;
    obj.borderColor      = self.borderColor;
    obj.backgroundColor  = self.backgroundColor;
    obj.insets           = self.insets;
    obj.cornerRadius     = self.cornerRadius;
    return obj;
}

@end

#pragma mark -

@interface TokenTextLayout()
@property(nonatomic ,assign) BOOL           needDrawTextBorder;
@property(nonatomic ,weak  ) TokenTextLine *trunctionLine;
@end

@implementation TokenTextLayout
- (instancetype)init
{
    self = [super init];
    if (self) {
        _textInsets           = UIEdgeInsetsZero;
        _lines                = @[].mutableCopy;
        _truncationToken      = [[NSAttributedString alloc] initWithString:@"..."];
        _trunctionDisplayType = TokenTrunctionTypeToken;
        _numberOfLines        = 1;
        _lineBreakMode        = NSLineBreakByTruncatingTail;
    }
    return self;
}

-(void)setNumberOfLines:(NSInteger)numberOfLines{
    _numberOfLines = numberOfLines==0?NSIntegerMax:numberOfLines;
}

+(instancetype)layoutWithText:(NSAttributedString *)text constraintedSize:(CGSize)constraintedSize{
    TokenTextLayout *layout = [[TokenTextLayout alloc] init];
    layout.text             = text;
    layout.constraintedSize = constraintedSize;
    return layout;
}

-(void)setText:(NSAttributedString *)text{
    _text = text?[text copy]:[[NSAttributedString alloc] initWithString:@""];
}

-(void)willCalculateLayout{
    __block BOOL result = NO;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:_text];
    [text enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, text.length) options:kNilOptions usingBlock:^(NSParagraphStyle *value, NSRange range, BOOL * _Nonnull stop) {
        if (value) {
            NSMutableParagraphStyle *style = [value isKindOfClass:[NSMutableParagraphStyle class]]?(id)value:(value.mutableCopy);
            style.alignment     = self->_textAlignment;
            style.lineBreakMode = NSLineBreakByWordWrapping;
            [text addAttributes:@{NSParagraphStyleAttributeName:style} range:range];
            result = YES;
        }
    }];

    if (!result) {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.alignment     = _textAlignment;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        [text addAttributes:@{NSParagraphStyleAttributeName:style} range:NSMakeRange(0, text.length)];
    }
    _text = text;
}

-(TokenTextLine *)creatTrunctionLineWithCTLine:(CTLineRef)ctLine
                                     lineWidth:(CGFloat)lineWidth
                                      position:(CGPoint)position {
    
    if (self.lineBreakMode == NSLineBreakByClipping ||
        self.trunctionDisplayType == TokenTrunctionTypeLinearGradient ) {
        TokenTextLine *textLine = [TokenTextLine lineWithCTLine:ctLine position:position];
        return textLine;
    }
    
    CFRange cf_range                        = CTLineGetStringRange(ctLine);
    NSRange ns_range                        = NSMakeRange(cf_range.location, cf_range.length);
    NSMutableAttributedString *lastLineText = [self.text attributedSubstringFromRange:ns_range].mutableCopy;
    [lastLineText appendAttributedString:self.truncationToken];
    
    CTLineTruncationType truncationType = TokenLineTruncationTypeFromLineBreakMode(self.lineBreakMode);
    CTLineRef ctLastLineExtend      = CTLineCreateWithAttributedString((CFAttributedStringRef)lastLineText);
    CTLineRef truncationTokenLine   = CTLineCreateWithAttributedString((CFAttributedStringRef)self.truncationToken);
    CTLineRef ctTruncatedLine       = CTLineCreateTruncatedLine(ctLastLineExtend,
                                                                lineWidth,
                                                                truncationType,
                                                                truncationTokenLine);
    TokenTextLine *textLine = [TokenTextLine lineWithCTLine:ctTruncatedLine position:position];
    CFRelease(ctLastLineExtend);
    CFRelease(truncationTokenLine);
    CFRelease(ctTruncatedLine);
    return textLine;
}

-(void)calculateLayout {
    [self willCalculateLayout];
    NSMutableDictionary *frameAttrs   = [NSMutableDictionary dictionary];
    frameAttrs[(id)kCTFramePathFillRuleAttributeName]     = @(kCTFramePathFillWindingNumber);
    if (_exclusionPaths && _exclusionPaths.count) {
        frameAttrs[(id)kCTFramePathFillRuleAttributeName] = @(kCTFramePathFillEvenOdd);
    }
    
    NSAttributedString *text = _text;
    if (text == nil) { return;}

    //creat TextPath
    CGRect bounds = UIEdgeInsetsInsetRect((CGRect){0,0,_constraintedSize}, _textInsets);
    CGMutablePathRef textPath    = CGPathCreateMutable();
    CGPathAddRect(textPath, NULL, bounds);
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(text));
    CTFrameRef       frame       = CTFramesetterCreateFrame(frameSetter,
                                                            CFRangeMake(0, text.length),
                                                            textPath,
                                                            (CFTypeRef)frameAttrs);
    CGPathRelease(textPath);
    CFArrayRef lines  = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    CFRange visibleCFRange = CTFrameGetVisibleStringRange(frame);
    NSRange visibleNSRange = NSMakeRange(visibleCFRange.location, visibleCFRange.length);
    
    // now we can calculate the lines
    for (NSInteger i = 0; i < lineCount; i++) {
        CTLineRef line  = CFArrayGetValueAtIndex(lines, i);
        CGPoint linePosition = lineOrigins[i];
        linePosition.x = TokenRoundPixelValue(linePosition.x) +_textInsets.left;
        linePosition.y = TokenRoundPixelValue(linePosition.y);
        
        TokenTextLine *textLine;
        NSInteger limitLine = MIN(self.numberOfLines, lineCount);
        
        //arrive the specific line
        if (i == limitLine -1 && i < lineCount - 1) {
            CGFloat lineWidth  = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
            textLine           = [self creatTrunctionLineWithCTLine:line lineWidth:lineWidth position:linePosition];
            [self.lines addObject:textLine];
            self.trunctionLine = textLine;
            break;
        }
        else {
            //last line
            if(i == lineCount - 1 && visibleNSRange.length < text.length) {
                CGFloat lineWidth  = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
                textLine           = [self creatTrunctionLineWithCTLine:line
                                                              lineWidth:lineWidth
                                                               position:linePosition];
                self.trunctionLine = textLine;
                [self.lines addObject:textLine];
                
            }
            else {
                textLine = [TokenTextLine lineWithCTLine:line position:linePosition];
                [self.lines addObject:textLine];
            }
        }
    }
    
    //borders
    void (^block)(NSDictionary *attrs, NSRange range, BOOL *stop) = ^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if (attrs[TokenTextBorderAttributeName]) {
            self.needDrawTextBorder = YES;
        }
    };
    [text enumerateAttributesInRange:visibleNSRange
                             options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                          usingBlock:block];
    
    if (self.needDrawTextBorder) {
        [self calculateBorders];
    }
}

-(void)calculateBorders {
    
    // get frame from CTRun
    CGRect (^lineGetTextBorderRunFrame)(TokenTextLine *line,CTRunRef run) = ^(TokenTextLine *line,CTRunRef run){
        
        CFIndex glyphCount = CTRunGetGlyphCount(run);
        if (glyphCount == 0) {
            return CGRectZero;
        }
        CGFloat ascent,descent,leading,runWidth;
        runWidth         = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
        CGPoint positions[glyphCount];
        CTRunGetPositions(run, CFRangeMake(0, 0), positions);
        return CGRectMake(TokenRoundPixelValue(positions[0].x+line.position.x),
                          TokenRoundPixelValue(line.position.y - descent),
                          TokenRoundPixelValue(runWidth),
                          TokenRoundPixelValue(line.size.height)+1);
    };
    
    for (TokenTextLine *line in self.lines) {
        if (line.textBorderFrames == nil) line.textBorderFrames = @[].mutableCopy;
        if (line.textBorders      == nil) line.textBorders      = @[].mutableCopy;
        
        CFArrayRef runs      = CTLineGetGlyphRuns(line.CTLine);
        CFIndex    runCount  = CFArrayGetCount(runs);
        NSInteger  passCount = 0;
        for (NSInteger i = 0; i < runCount; i++) {
            CTRunRef run       = CFArrayGetValueAtIndex(runs, i);
            CFIndex glyphCount = CTRunGetGlyphCount(run);
            if (glyphCount == 0) continue;
            
            TokenTextBorder *textBorder = CFDictionaryGetValue(CTRunGetAttributes(run),
                                                               (__bridge const void *)TokenTextBorderAttributeName);
            if (textBorder == nil) continue;
            
            if (passCount) {
                passCount -= 1;
                continue;
            }
            
            CGRect textBorderRunFrame = lineGetTextBorderRunFrame(line,run);
            
            NSInteger j = i+1;
            while (j<runCount) {
                CTRunRef nextRun = CFArrayGetValueAtIndex(runs, j);
                TokenTextBorder *nextTextBorder = CFDictionaryGetValue(CTRunGetAttributes(nextRun),
                                                                    (__bridge const void *)TokenTextBorderAttributeName);
                CGRect nextBorderFrame = lineGetTextBorderRunFrame(line,nextRun);
                if (textBorder == nextTextBorder) {
                    textBorderRunFrame = CGRectUnion(textBorderRunFrame, nextBorderFrame);
                    passCount++;
                }
                j++;
            }
            [line.textBorderFrames addObject:[NSValue valueWithCGRect:textBorderRunFrame]];
            [line.textBorders addObject:textBorder];
        }
    }
}

-(void)drawInContext:(CGContextRef)context {
    CGContextSaveGState(context);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.constraintedSize.height);
    CGContextScaleCTM(context, 1.0,-1.0);

    if (self.trunctionDisplayType == TokenTrunctionTypeLinearGradient && self.trunctionLine) {
        CGRect  bounds       = (CGRect){0,0,self.constraintedSize};
        CGSize  size         = self.trunctionLine.size;
        CGPoint position     = self.trunctionLine.position;
        CGRect  maskPosition = (CGRect){position.x,position.y-2,size.width,size.height};
        CGImageRef maskImage = [self creatLinearGradientMaskImageWithImageSize:self.constraintedSize
                                                           linearGradientFrame:maskPosition
                                                                    fadeLength:self.trunctionFadeLength
                                                                      fadeHead:NO
                                                                      fadeTail:YES];
        CGContextClipToMask(context, bounds, maskImage);
        CGImageRelease(maskImage);
    }
    
    // draw border
    if (self.needDrawTextBorder) {
        NSInteger lineCount = self.lines.count;
        for (NSInteger i = 0; i<lineCount; i++) {
            TokenTextLine *line = self.lines[i];
            NSInteger borderCount = line.textBorders.count;
            if (borderCount == 0) { continue;}
            if (borderCount != line.textBorderFrames.count) break;
            
            for (NSInteger j = 0; j < borderCount; j++) {
                CGContextSaveGState(context);
                TokenTextBorder *border = line.textBorders[j];
                CGRect textBorderFrame = line.textBorderFrames[j].CGRectValue;
                UIEdgeInsets newInsets = UIEdgeInsetsMake(border.insets.bottom,
                                                          border.insets.left,
                                                          border.insets.top,
                                                          border.insets.right);
                
                textBorderFrame = UIEdgeInsetsInsetRect(textBorderFrame, newInsets);
                if (border.cornerRadius) {
                    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:textBorderFrame
                                                                    cornerRadius:border.cornerRadius];
                    CGContextAddPath(context, path.CGPath);
                }
                else CGContextAddRect(context, textBorderFrame);
                if (border.backgroundColor)  CGContextSetFillColorWithColor(context, border.backgroundColor.CGColor);
                if (border.borderColor)  CGContextSetStrokeColorWithColor(context, border.borderColor.CGColor);
                TokenTextSetLinePatternInContext(border.lineStyle,
                                                 TokenRoundPixelValue(border.borderWidth),
                                                 0,
                                                 border.dashSpace,
                                                 context);
                if (border.backgroundColor != nil) {
                    if (border.borderWidth && border.borderColor) { CGContextDrawPath(context, kCGPathFillStroke);}
                    else CGContextDrawPath(context, kCGPathFill);
                }
                else CGContextDrawPath(context, kCGPathStroke);
                CGContextRestoreGState(context);
            }
        }
    }
    
    // draw Text
    {
        for (NSInteger i = 0; i < self.lines.count; i++) {
            TokenTextLine *textLine = self.lines[i];
            CGPoint position = textLine.position;
            CGContextSetTextMatrix(context, CGAffineTransformIdentity);
            CGContextSetTextPosition(context, position.x,position.y);
            CTLineDraw(textLine.CTLine, context);
        }
    }
    CGContextRestoreGState(context);
}

-(CGImageRef)creatLinearGradientMaskImageWithImageSize:(CGSize)imageSize
                                 linearGradientFrame:(CGRect)linearGradientFrame
                                          fadeLength:(CGFloat)fadeLength
                                            fadeHead:(BOOL)fadeHead
                                            fadeTail:(BOOL)fadeTail{
    // Create an opaque context.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 8,
                                                 4*imageSize.width,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNone);
    
    // White background will mask opaque, black gradient will mask transparent.
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context,(CGRect){0,0,imageSize});
    
    // Create gradient from white to black.
    CGFloat locs[2]        = { 0.0f, 1.0f };
    CGFloat components[4]  = { 1.0f, 1.0f, 0.0f, 1.0f };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locs, 2);
    CGColorSpaceRelease(colorSpace);
    
    // Draw head and/or tail gradient.
    CGRect rect = (CGRect){0,0,imageSize};
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat minX = CGRectGetMinX(rect);
    
    if (fadeTail) {
        CGFloat startX = maxX - fadeLength;
        CGPoint startPoint = CGPointMake(startX, CGRectGetMidY(rect));
        CGPoint endPoint = CGPointMake(maxX, CGRectGetMidY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    }
    
    if (fadeHead) {
        CGFloat startX = minX + fadeLength;
        CGPoint startPoint = CGPointMake(startX, CGRectGetMidY(rect));
        CGPoint endPoint = CGPointMake(minX, CGRectGetMidY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CGPathAddRect(path, NULL, linearGradientFrame);
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextDrawPath(context, kCGPathEOFill);
    CGPathRelease(path);
    
    CGImageRef ref = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return ref;
}

-(CGSize)textSize{
    CGFloat maxWidth  = 0.0f;
    CGFloat maxHeight = 0.0f;;
    for (NSInteger i = 0; i < self.lines.count; i++) {
        TokenTextLine *textLine = self.lines[i];
        maxWidth = MAX(textLine.size.width, maxWidth);
        maxHeight += textLine.size.height;
    }
    return CGSizeMake(TokenRoundPixelValue(maxWidth), TokenRoundPixelValue(maxHeight));
}

@end
