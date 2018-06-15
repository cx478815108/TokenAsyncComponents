//
//  TokenAsyncLayer.m
//  TokenOperation
//
//  Created by 陈雄 on 2018/5/23.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import "TokenAsyncLayer.h"
#import "TokenOperationQueue.h"
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>
#import <stdatomic.h>

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

-(void)display{
    super.contents = super.contents;
    if (self.asyncDisplay) {
        TokenTranscationCommit(^{ [self asyncGetDisplayContents];});
    }
    else {
        [self syncGetDisplayContents];
    }
}

-(void)cancelDisplay{
    atomic_fetch_add(&_stateMark, 1);
}

-(void)asyncGetDisplayContents{
    if (![self.delegate respondsToSelector:@selector(produceAsyncDisplayTask)]) return ;
    
    atomic_size_t displaySentinelValue = _stateMark;
    __weak TokenAsyncLayer *weakSelf   = self;
    BOOL (^isCanceledBlock)(void) = ^(void){
        __strong TokenAsyncLayer *self = weakSelf;
        BOOL result = (self == nil || (displaySentinelValue != atomic_load(&self->_stateMark)));
        return result;
    };
    
    TokenDisplayTask *task = [(id)self.delegate produceAsyncDisplayTask];
    CGRect  bounds         = self.bounds;
    BOOL    opaque         = self.opaque;
    CGFloat scale          = self.class.scale;
    
    TokenOperationQueue.sharedQueue
    .chain_runOperationWithPriority(TokenQueuePriorityHigh, ^{
        if (isCanceledBlock()) return ;
        !task.willDisplayBlock?:task.willDisplayBlock();
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGColorRef backgroundColor = (opaque && self.backgroundColor) ? CGColorRetain(self.backgroundColor) : NULL;
        
        if (opaque && context) {
            CGContextSaveGState(context);
            if (!backgroundColor || CGColorGetAlpha(backgroundColor) < 1) {
                CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                CGContextAddRect(context, CGRectMake(0, 0, bounds.size.width * scale, bounds.size.height * scale));
                CGContextFillPath(context);
            }
            if (backgroundColor) {
                CGContextSetFillColorWithColor(context, backgroundColor);
                CGContextAddRect(context, CGRectMake(0, 0, bounds.size.width * scale, bounds.size.height * scale));
                CGContextFillPath(context);
            }
            CGContextRestoreGState(context);
            CGColorRelease(backgroundColor);
        }
        
        if (context) {
            task.displayBlock(context, bounds);
        }
        
        if (isCanceledBlock()) {
            UIGraphicsEndImageContext();
            dispatch_async(dispatch_get_main_queue(), ^{
                !task.didDisplayBlock?:task.didDisplayBlock();
            });
            return;
        }
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
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

-(void)syncGetDisplayContents{
    if (![self.delegate respondsToSelector:@selector(produceAsyncDisplayTask)]) return ;
    [self cancelDisplay];
    TokenDisplayTask *task = [(id)self.delegate produceAsyncDisplayTask];
    CGRect  bounds         = self.bounds;
    BOOL    opaque         = self.opaque;
    CGFloat scale          = self.class.scale;
    
    !task.willDisplayBlock?:task.willDisplayBlock();
    UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (opaque && context) {
        CGSize size  = bounds.size;
        size.width  *= scale;
        size.height *= scale;
        CGContextSaveGState(context); {
            if (!self.backgroundColor || CGColorGetAlpha(self.backgroundColor) < 1) {
                CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height));
                CGContextFillPath(context);
            }
            if (self.backgroundColor) {
                CGContextSetFillColorWithColor(context, self.backgroundColor);
                CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height));
                CGContextFillPath(context);
            }
        } CGContextRestoreGState(context);
    }
    !task.displayBlock?:task.displayBlock(context,bounds);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.contents = (__bridge id)(image.CGImage);
    !task.didDisplayBlock?:task.didDisplayBlock();
}
@end

@implementation TokenDisplayTask
@end
