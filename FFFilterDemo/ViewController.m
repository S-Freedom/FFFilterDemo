//
//  ViewController.m
//  FFFilterDemo
//
//  Created by 黄鹏飞 on 16/3/7.
//  Copyright © 2016年 黄鹏飞. All rights reserved.
//

#import "ViewController.h"
#import <Accelerate/Accelerate.h>
@interface ViewController ()
@property (strong,nonatomic) UIImageView *ruImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 输出滤镜名称
    
//    NSArray *filterNames = [CIFilter filterNamesInCategory:kCICategoryBuiltIn];
//    [filterNames enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSLog(@"obj : %@",obj);
//    }];
    
//    [self test2];
    
    UIImage *image = [self blurryImage:[UIImage imageNamed:@"200925655196-5430.jpg"] withBlurLevel:1];
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.frame = CGRectMake(100, 100, 100, 100);
    imageView.image = image;
    self.ruImageView = imageView;
    [self.view addSubview:imageView];
}

/**   使用vImage 进行毛玻璃模糊处理
 *  使用vImage API进行图像的模糊处理
 *
 *  @param image 原图像
 *  @param blur  模糊度（0.0~1.0）
 *
 *  @return 模糊处理之后的图像
 */
- (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur {
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }//判断曝光度
    int boxSize = (int)(blur * 100);//放大100，就是小数点之后两位有效
    boxSize = boxSize - (boxSize % 2) + 1;//如果是偶数，+1，变奇数
    
    CGImageRef img = image.CGImage;//获取图片指针
    
    vImage_Buffer inBuffer, outBuffer;//获取缓冲区
    vImage_Error error;//一个错误类，在后调用画图函数的时候要用
    
    void *pixelBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);//放回一个图片供应者信息
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);//拷贝数据，并转化
    
    inBuffer.width = CGImageGetWidth(img);//放回位图的宽度
    inBuffer.height = CGImageGetHeight(img);//放回位图的高度
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);//放回位图的
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);//填写图片信息
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) *
                         CGImageGetHeight(img));//创建一个空间
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer,
                                       &outBuffer,
                                       NULL,
                                       0,
                                       0,
                                       boxSize,//这个数一定要是奇数的，因此我们一开始的时候需要转化
                                       boxSize,//这个数一定要是奇数的，因此我们一开始的时候需要转化
                                       NULL,
                                       kvImageEdgeExtend);
    
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    //将刚刚得出的数据，画出来。
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
                                             outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return returnImage;
}



// 毛玻璃2
- (void)test2{
    UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"200925655196-5430.jpg"]];
    imageView.frame = CGRectMake(100, 100, 100, 100);
    self.ruImageView = imageView;
    UIVisualEffectView *ruVisualEffectView = [[UIVisualEffectView alloc]initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    ruVisualEffectView.frame = self.ruImageView.bounds;
    ruVisualEffectView.alpha = 1.0f;
    [self.ruImageView addSubview:ruVisualEffectView];
    [self.view addSubview:imageView];
}

// 毛玻璃1
- (void)test1{
    //     创建一个输入源,
    CIImage *inputImage = [CIImage imageWithContentsOfURL:[NSURL URLWithString:@"http://logo.cndesign.com/2009/2/5/200925655196-5430.jpg"]];
    
    // 构建一个滤镜图标
    CIColor *sepiaColor = [CIColor colorWithRed:0.76 green:0.65 blue:0.54];
    
    // 构建一个CIColorMonochrome 滤镜, 并配置输入图像与滤镜参数
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome" withInputParameters:@{@"inputColor":sepiaColor,@"inputIntensity":@1.0}];
    [monochromeFilter setValue:inputImage forKey:@"inputImage"]; // 通过KVC 设置图像
    
    // 先创建一个CIVignette 滤镜
    CIFilter *vignetterFilter = [CIFilter filterWithName:@"CIVignette" withInputParameters:@{@"inputRadius":@2.0,@"inputIntensity":@1.0}];
    [vignetterFilter setValue:monochromeFilter.outputImage forKey:@"inputImage"]; // 以monochrome 的输出作为这个滤镜的输入
    
    // 得到一个滤镜处理后的图片, 并转换至 UIImage
    CIContext *ciContexgt = [CIContext contextWithOptions:nil];
    // 将 ciImage 过度到CGImageRef 类型
    CGImageRef cgImageRef = [ciContexgt createCGImage:vignetterFilter.outputImage fromRect:inputImage.extent];
    // 最后转换成 UIImage 类型
    UIImage *image = [UIImage imageWithCGImage:cgImageRef];
    
    //    UIImage *image = [UIImage imageNamed:@"200925655196-5430.jpg"];
    
    UIImageView *imageView = [[UIImageView alloc]initWithImage:image];
    CGRect rect = [UIScreen mainScreen].bounds;
    CGFloat scale = 1.0;
    CGFloat width = 0;
    CGFloat height = 0;
    scale = image.size.width / image.size.height;
    if(image.size.width > rect.size.width){
        width = rect.size.width;
        height = rect.size.height * scale ;
    }else{
        width = image.size.width;
        height = image.size.height;
    }
    imageView.frame = CGRectMake(0, 0, width,height);
    imageView.center = self.view.center;
    [self.view addSubview:imageView];
}

@end
