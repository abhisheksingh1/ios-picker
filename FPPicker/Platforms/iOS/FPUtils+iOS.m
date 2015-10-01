//
//  FPUtils+iOS.m
//  FPPicker
//
//  Created by Ruben Nine on 13/08/14.
//  Copyright (c) 2014 Filepicker.io. All rights reserved.
//

#import "FPUtils+iOS.h"
#import "FPPrivateConfig.h"

@import UIKit;
@import Photos;

@implementation FPUtils (iOS)

+ (UIImage *)fixImageRotationIfNecessary:(UIImage *)image
{
    /*
     * http://stackoverflow.com/questions/10170009/image-became-horizontal-after-successfully-uploaded-on-server-using-http-post
     */

    CGImageRef imgRef = image.CGImage;

    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);


    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);

    /*
       int kMaxResolution = 640; // Or whatever

       if (width > kMaxResolution || height > kMaxResolution) {
       CGFloat ratio = width/height;
       if (ratio > 1) {
       bounds.size.width = kMaxResolution;
       bounds.size.height = roundf(bounds.size.width / ratio);
       }
       else {
       bounds.size.height = kMaxResolution;
       bounds.size.width = roundf(bounds.size.height * ratio);
       }
       }
     */

    CGFloat scaleRatio = CGRectGetWidth(bounds) / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;

    switch (orient)
    {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;

        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;

        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;

        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = CGRectGetHeight(bounds);
            bounds.size.height = CGRectGetWidth(bounds);
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = CGRectGetHeight(bounds);
            bounds.size.height = CGRectGetWidth(bounds);
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = CGRectGetHeight(bounds);
            bounds.size.height = CGRectGetWidth(bounds);
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;

        case UIImageOrientationRight: //EXIF = 8
            boundHeight = CGRectGetHeight(bounds);
            bounds.size.height = CGRectGetWidth(bounds);
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;

        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }

    UIGraphicsBeginImageContext(bounds.size);

    CGContextRef context = UIGraphicsGetCurrentContext();

    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft)
    {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else
    {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }

    CGContextConcatCTM(context, transform);

    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageCopy;
}

+ (UIImage *)compressImage:(UIImage *)image
     withCompressionFactor:(CGFloat)compressionFactor
            andOrientation:(UIImageOrientation)orientation
{
    NSData *imageData = UIImageJPEGRepresentation(image, compressionFactor);
    UIImage *compressedImage = [[UIImage alloc] initWithData:imageData];

    imageData = nil;

    UIImage *compressedAndRotatedImage = [UIImage imageWithCGImage:compressedImage.CGImage
                                                             scale:1.0
                                                       orientation:orientation];

    return compressedAndRotatedImage;
}

+ (void)asyncFetchAssetThumbnailFromPHAsset:(PHAsset *)asset
                                 completion:(FPFetchPHAssetImageBlock)completionBlock
{
    NSInteger retinaScale = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(100 * retinaScale, 100 * retinaScale);

    PHImageRequestOptions *cropToSquare = [PHImageRequestOptions new];

    cropToSquare.resizeMode = PHImageRequestOptionsResizeModeExact;
    cropToSquare.networkAccessAllowed = YES;

    CGFloat cropSideLength = MIN(asset.pixelWidth, asset.pixelHeight);
    CGRect square = CGRectMake(0, 0, cropSideLength, cropSideLength);
    CGRect cropRect = CGRectApplyAffineTransform(square,
                                                 CGAffineTransformMakeScale(1.0 / asset.pixelWidth,
                                                                            1.0 / asset.pixelHeight));

    cropToSquare.normalizedCropRect = cropRect;

    [[PHImageManager defaultManager] requestImageForAsset:(PHAsset *)asset
                                               targetSize:retinaSquare
                                              contentMode:PHImageContentModeAspectFit
                                                  options:cropToSquare
                                            resultHandler: ^(UIImage *result, NSDictionary *info) {
        completionBlock(result);
    }];
}

@end
