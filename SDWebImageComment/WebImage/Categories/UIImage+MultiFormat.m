/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+MultiFormat.h"
#import "UIImage+GIF.h"
#import "NSData+ImageContentType.h"
#import <ImageIO/ImageIO.h>

#ifdef SD_WEBP
#import "UIImage+WebP.h"
#endif

@implementation UIImage (MultiFormat)

+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data {
    if (!data) {
        return nil;
    }
    
    UIImage *image;
    //识别图片格式
    SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
    if (imageFormat == SDImageFormatGIF) {
    // gif图片处理，得到静态图片
        image = [UIImage sd_animatedGIFWithData:data];
    }
//是否开启了 WEBP 格式支持
#ifdef SD_WEBP
    // webp图片处理
    else if (imageFormat == SDImageFormatWebP)
    {
        // 得到webp格式图片
        image = [UIImage sd_imageWithWebPData:data];
    }
#endif
    // 静态图片处理
    else {
        image = [[UIImage alloc] initWithData:data];
#if SD_UIKIT || SD_WATCH
        //图片方向处理
        UIImageOrientation orientation = [self sd_imageOrientationFromImageData:data];
        // 图片的方向默认是UIImageOrientationUp，若是本来图片的方向就是UIImageOrientationUp那么就不需要重新处理图片的方向
        if (orientation != UIImageOrientationUp) {
            image = [UIImage imageWithCGImage:image.CGImage
                                        scale:image.scale
                                  orientation:orientation];
        }
#endif
    }


    return image;
}

#if SD_UIKIT || SD_WATCH
//获取图片的方向
+(UIImageOrientation)sd_imageOrientationFromImageData:(nonnull NSData *)imageData {
    UIImageOrientation result = UIImageOrientationUp;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if (imageSource) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val;
            int exifOrientation;
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) {
                CFNumberGetValue(val, kCFNumberIntType, &exifOrientation);
                result = [self sd_exifOrientationToiOSOrientation:exifOrientation];
            } // else - if it's not set it remains at up
            CFRelease((CFTypeRef) properties);
        } else {
            //NSLog(@"NO PROPERTIES, FAIL");
        }
        CFRelease(imageSource);
    }
    return result;
}

#pragma mark EXIF orientation tag converter
// Convert an EXIF image orientation to an iOS one.
// reference see here: http://sylvana.net/jpegcrop/exif_orientation.html
// 转化图片方向
+ (UIImageOrientation) sd_exifOrientationToiOSOrientation:(int)exifOrientation {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case 1:
            orientation = UIImageOrientationUp;
            break;

        case 3:
            orientation = UIImageOrientationDown;
            break;

        case 8:
            orientation = UIImageOrientationLeft;
            break;

        case 6:
            orientation = UIImageOrientationRight;
            break;

        case 2:
            orientation = UIImageOrientationUpMirrored;
            break;

        case 4:
            orientation = UIImageOrientationDownMirrored;
            break;

        case 5:
            orientation = UIImageOrientationLeftMirrored;
            break;

        case 7:
            orientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return orientation;
}
#endif

- (nullable NSData *)sd_imageData {
    return [self sd_imageDataAsFormat:SDImageFormatUndefined];
}

- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat {
    NSData *imageData = nil;
    if (self) {
#if SD_UIKIT || SD_WATCH
        int alphaInfo = CGImageGetAlphaInfo(self.CGImage);
        BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                          alphaInfo == kCGImageAlphaNoneSkipFirst ||
                          alphaInfo == kCGImageAlphaNoneSkipLast);
        
        BOOL usePNG = hasAlpha;
        
        // the imageFormat param has priority here. But if the format is undefined, we relly on the alpha channel
        if (imageFormat != SDImageFormatUndefined) {
            usePNG = (imageFormat == SDImageFormatPNG);
        }
        
        if (usePNG) {
            imageData = UIImagePNGRepresentation(self);
        } else {
            imageData = UIImageJPEGRepresentation(self, (CGFloat)1.0);
        }
#else
        NSBitmapImageFileType imageFileType = NSJPEGFileType;
        if (imageFormat == SDImageFormatGIF) {
            imageFileType = NSGIFFileType;
        } else if (imageFormat == SDImageFormatPNG) {
            imageFileType = NSPNGFileType;
        }
        
        imageData = [NSBitmapImageRep representationOfImageRepsInArray:self.representations
                                                             usingType:imageFileType
                                                            properties:@{}];
#endif
    }
    return imageData;
}


@end
