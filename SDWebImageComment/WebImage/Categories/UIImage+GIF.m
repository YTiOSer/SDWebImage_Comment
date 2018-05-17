/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Laurin Brandner
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+GIF.h"
#import <ImageIO/ImageIO.h>
#import "objc/runtime.h"
#import "NSImage+WebCache.h"

@implementation UIImage (GIF)
// 返回静态图片
// 在4.0版本之后 GIF 图片使用 FLAnimatedImageView 来支持，SDWEBImage对GIF的处理都是只取第一帧图片
+ (UIImage *)sd_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);

    size_t count = CGImageSourceGetCount(source);

    UIImage *staticImage;

    if (count <= 1) {
        staticImage = [[UIImage alloc] initWithData:data];
    } else {
        // we will only retrieve the 1st frame. the full GIF support is available via the FLAnimatedImageView category.
        // this here is only code to allow drawing animated images as static ones
#if SD_WATCH
        CGFloat scale = 1;
        scale = [WKInterfaceDevice currentDevice].screenScale;
#elif SD_UIKIT
        // 缩放倍数
        CGFloat scale = 1;
        scale = [UIScreen mainScreen].scale;
#endif
        //取第一帧图片
        CGImageRef CGImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
#if SD_UIKIT || SD_WATCH
        UIImage *frameImage = [UIImage imageWithCGImage:CGImage scale:scale orientation:UIImageOrientationUp];
        staticImage = [UIImage animatedImageWithImages:@[frameImage] duration:0.0f];
#elif SD_MAC
        staticImage = [[UIImage alloc] initWithCGImage:CGImage size:NSZeroSize];
#endif
        CGImageRelease(CGImage);
    }

    CFRelease(source);
// 返回静态图片
    return staticImage;
}

- (BOOL)isGIF {
    return (self.images != nil);
}

@end
