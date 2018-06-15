//
//  TokenAsyncLayer.h
//  TokenOperation
//
//  Created by 陈雄 on 2018/5/23.
//  Copyright © 2018年 com.feelings. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
@import UIKit;

typedef void (^TokenDisplayGetBlock)(CGContextRef context,CGRect bounds);

@interface TokenDisplayTask :NSObject
@property(nonatomic ,copy) dispatch_block_t     willDisplayBlock;
@property(nonatomic ,copy) TokenDisplayGetBlock displayBlock;
@property(nonatomic ,copy) dispatch_block_t     didDisplayBlock;
@end

@protocol TokenAsyncLayerDelegate<NSObject>
-(TokenDisplayTask *)produceAsyncDisplayTask;
@end

@interface TokenAsyncLayer : CALayer
@property(nonatomic ,assign) BOOL asyncDisplay;
@end
