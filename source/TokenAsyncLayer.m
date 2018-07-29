//
//  TokenAsyncLayer.m
//  TokenOperation
//
//  Created by 陈雄 on 2018/5/23.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenAsyncLayer.h"
#import "TokenOperationQueue.h"
#import <CoreGraphics/CoreGraphics.h>
#import <stdatomic.h>

static UIImage *TokenLayerDrawInContext(CGRect  bounds,
                                        BOOL    opaque,
                                        CGFloat scale,
                                        void (^contextBlock)(CGContextRef context)) {
    UIImage *image = nil;
    if (@available(iOS 10, *)) {
        UIGraphicsImageRendererFormat *format = [[UIGraphicsImageRendererFormat alloc] init];
        format.scale  = scale;
        format.opaque = opaque;
        UIGraphicsImageRenderer *imageRender = [[UIGraphicsImageRenderer alloc] initWithSize:bounds.size format:format];
        image = [imageRender imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
            !contextBlock?:contextBlock(rendererContext.CGContext);
        }];
    }
    else {
        UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        !contextBlock?:contextBlock(context);
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

@implementation TokenAsyncLayer{
    atomic_size_t _stateMark;
}

+(CGFloat)scale{
    static CGFloat scale;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scale = [UIScreen mainScreen].scale;
    });
    return scale;
}

+ (id)defaultValueForKey:(NSString *)key {
    if ([key isEqualToString:@"asyncDisplay"]) {
        return @(YES);
    } else {
        return [super defaultValueForKey:key];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _stateMark    = ATOMIC_VAR_INIT(0);
        _asyncDisplay = YES;
    }
    return self;
}

-(void)setNeedsDisplay{
    [self cancelDisplay];
    [super setNeedsDisplay];
}

-(void)cancelDisplay{
    atomic_fetch_add(&_stateMark, 1);
}

-(void)display{
    super.contents = super.contents;
    if (self.asyncDisplay) {
        TokenTranscationCommit(^{ [self asyncMakeDisplayContents:YES];});
    }
    else {
        [self asyncMakeDisplayContents:NO];
    }
}


-(void)asyncMakeDisplayContents:(BOOL)async{
    if (![self.delegate respondsToSelector:@selector(produceAsyncDisplayTask)]) return ;
    
    CGRect  bounds             = self.bounds;
    BOOL    opaque             = self.opaque;
    CGFloat scale              = self.class.scale;
    CGColorRef backgroundColor = (opaque && self.backgroundColor) ? self.backgroundColor : NULL;
    TokenDisplayTask *task = [(id)self.delegate produceAsyncDisplayTask];
    
    if (async) {
        
        atomic_size_t displaySentinelValue = _stateMark;
        __weak TokenAsyncLayer *weakSelf   = self;
        BOOL (^isCanceledBlock)(void)      = ^(void){
            __strong TokenAsyncLayer *self = weakSelf;
            BOOL result = (self == nil || (displaySentinelValue != atomic_load(&self->_stateMark)));
            return result;
        };
        
        TokenOperationQueue.sharedQueue
        .chain_runOperationWithPriority(TokenQueuePriorityHigh, ^{
            !task.willDisplayBlock?:task.willDisplayBlock();
            
            if (isCanceledBlock()) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !task.didDisplayBlock?:task.didDisplayBlock();
                });
                return ;
            }
            
            UIImage *image = TokenLayerDrawInContext(bounds, opaque, scale, ^(CGContextRef context) {
                if (isCanceledBlock() || !context) return;
                if (opaque) {
                    CGContextSaveGState(context);
                    CGContextAddRect(context, CGRectMake(0, 0, bounds.size.width * scale, bounds.size.height * scale));
                    if (!backgroundColor || CGColorGetAlpha(backgroundColor) < 1) {
                        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                    }
                    if (backgroundColor) {
                        CGContextSetFillColorWithColor(context, backgroundColor);
                    }
                    CGContextFillPath(context);
                    CGContextRestoreGState(context);
                }
                task.displayBlock(context, bounds);
            });
            
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (isCanceledBlock()) {
                        !task.didDisplayBlock?:task.didDisplayBlock();
                        return ;
                    }
                    self.contents = (__bridge id)image.CGImage;
                    !task.didDisplayBlock?:task.didDisplayBlock();
                });
            }
        });
    }
    else {
        atomic_fetch_add(&_stateMark, 1);
        !task.willDisplayBlock?:task.willDisplayBlock();
        UIImage *image = TokenLayerDrawInContext(bounds, opaque, scale, ^(CGContextRef context) {
            if (!context) return ;
            CGContextSaveGState(context);
            CGContextAddRect(context, CGRectMake(0, 0, bounds.size.width * scale, bounds.size.height * scale));
            if (!backgroundColor || CGColorGetAlpha(backgroundColor) < 1) {
                CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            }
            if (backgroundColor) {
                CGContextSetFillColorWithColor(context, backgroundColor);
            }
            CGContextFillPath(context);
            CGContextRestoreGState(context);
            !task.displayBlock?:task.displayBlock(context, bounds);
        });
        self.contents = (__bridge id)(image.CGImage);
        !task.didDisplayBlock?:task.didDisplayBlock();
    }
}
@end

@implementation TokenDisplayTask
@end
