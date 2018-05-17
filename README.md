![SDWebImage](https://raw.githubusercontent.com/rs/SDWebImage/master/SDWebImage_logo.png)

>在iOS项目常用的框架中，**[SDWebImage](https://github.com/rs/SDWebImage)** 是不可少的, 相信大部分的iOS 开发攻城狮都和`SDWebImage`打过交道, 使用是使用了,但是你了解阅读过它的源码,了解它的实现原理吗? 

>这两天闲下来, 我有时间阅读了`SDWebImage`的源码, 收获很大,为了整理下我理解的思路, 把它变成自己的知识,就写了这篇文章,向大家分享下我的阅读心得。

- ### SDWebImage简介
1. 提供 `UIImageView`, `UIButton`, `MKAnnotationView` 的分类，用来加载网络图片，并进行缓存管理;
2. **异步**方式来下载网络图片
3. 异步方式: `memory` (内存)＋ `disk` (磁盘) 来缓存网络图片，自动管理缓存;
4. 后台图片解码,转换及压缩;
5. 同一个 **URL** 不会重复下载;
6. 失效的 URL 不会被无限重试;
7. 支持 **GIF动画** 及 **WebP** 格式;
8. 开启 *子线程* 进行耗时操作，不阻塞主线程;
9. 使用 **GCD** 和 **ARC**;

- ### SDWebImage使用
1. `UIImageView`加载图片:
```
image_Icon.sd_setImage(with: URL(string: ""), placeholderImage: UIImage(named: ""))
```
2. 可使用 **闭包** 获取图片下载进度及成功失败状态:
```
image_Icon.sd_setImage(with: URL.init(string: ""), placeholderImage: UIImage.init(named: ""), options: .avoidAutoSetImage) { (image, error, cacheType, url) in
//image:加载的图片, error:加载错误, cacheType: 缓存类型, url:图片url
}
```
3. `SDWebImageManager`下载图片
```
let manager = SDWebImageManager.shared()
manager?.downloadImage(with: URL.init(string: ""), options: .avoidAutoSetImage, progress: { (receivedSize, expectedSize) in
//receivedSize:接受大小,expectedSize:总大小
}, completed: { (image, error, cacheType, isFinished, url) in
//image:加载的图片,error:错误,cacheType:缓存类型,isFinished是否加载完成,url: 图片url
})
```
4. `SDWebImageDownloader` 下载图片
我们如果遇到需要单独下载图片, 可使用 `SDWebImageDownloader` ,来下载图片, 但下载的图片 **不缓存** .
```
let downLoader = SDWebImageDownloader.shared()
downLoader?.downloadImage(with: URL.init(string: ""), options: .useNSURLCache, progress: { (receivedSize, expectedSize) in
//receivedSize:接受大小,expectedSize:总大小
}, completed: { (image, data, error, isFinished) in
//data: 图片解码后数据
if (image != nil) && isFinished{
//使用图片
}
})
```
5. `SDImageCache` 缓存图片
如果需要缓存图片, 可使用 `SDImageCache `, `SDImageCache`支持内存缓存和异步的磁盘缓存.
- 添加缓存(默认 **同时缓存到内存和磁盘** 中)
```
SDImageCache.shared().store(UIImage.init(named: ""), forKey: "")
```
- 也可设置只缓存内存,不缓存磁盘:
```
SDImageCache.shared().store(UIImage.init(named: ""), forKey: "", toDisk: false)
```
- 可通过key读取缓存,key默认是图片的url
```
SDImageCache.shared().queryDiskCache(forKey: "") { (image, cacheType) in

}
```
6. `UIButton` 加载图片
`UIButton` 加载图片,可以区分状态,如 normal, selected, highlighted等
```
btn.sd_setImage(with: URL.init(string: ""), for: .normal, placeholderImage: UIImage.init(named: "placeHolderImage"))
btn.sd_setImage(with: URL.init(string: ""), for: .highlighted, placeholderImage: UIImage.init(named: "placeHolderImage"))
```

- ### SDWebImage 架构图及流程图

1. `SDWebImage`调用只需简单的几行代码,对攻城狮来说十分便捷,这得益与代码的整体架构,整体机构图如下:
![](https://raw.githubusercontent.com/rs/SDWebImage/master/Docs/SDWebImageClassDiagram.png)

2. `SDWebImage` 核心在于 **下载,缓存及显示** 图片,这个流程如下:
![](https://raw.githubusercontent.com/rs/SDWebImage/master/Docs/SDWebImageSequenceDiagram.png)

注: 强烈建议好好看下上面的流程图, 对理解 `SDWebImage` 非常有帮助.

3. 类功能列表
`SDWebImage` 类区分的很清晰, 各个类功能也很明确, 各司其职, 封装的特别好.

| 类                                  | 功能                    |
| ------------------------------- | ----------------------------- | 
| `SDWebImageManager`  | 将图片下载`SDWebImageDownloader` 和图片缓存`SDImageCache` 两个独立的功能组合起来 |
| `SDWebImageDownloader` | 专门用来下载图片和优化图片加载的，跟缓存没有关系 |
|  `SDWebImageDownloaderOperation` |  继承于 `NSOperation`，用来处理下载任务 |
|  `SDImageCache` |  异步处理内存缓存和磁盘缓存,不阻塞主线程 |
|  `SDWebImageDecoder ` |  图片解码器，用于图片下载完成后进行解码 |
|  `SDWebImagePrefetcher ` |  预下载图片，方便后续使用，图片下载的优先级低，其内部由 `SDWebImageManager` 来处理图片下载和缓存 |
|  `UIView+WebCacheOperation ` |  图片加载operation，可取消和移除,可显示加载进度view |
|  `UIImageView+WebCache ` |  集成 `SDWebImageManager` 的图片下载和缓存功能到 `UIImageView` 的方法中，方便通过 `UIImageView` 直接调用 |
|  `UIImageView+HighlightedWebCache ` |  和 `UIImageView+WebCache` 功能相似，用于加载 **highlighted** 状态的图片 |
|  `UIButton+WebCache` |  集成 `SDWebImageManager` 的图片下载和缓存功能到 `UIImageView` 的方法中，方便通过 `UIButton` 直接调用 |
|  `MKAnnotationView+WebCache` |  集成 `SDWebImageManager` 的图片下载和缓存功能到 `MKAnnotationView` 的方法中，方便通过 `MKAnnotationView` 直接调用 |
|  `NSData+ImageContentType` |  用于获取图片数据的格式（如:JPEG、PNG、GIF等) |
|  `UIImage+GIF` |  用于加载 **GIF** 动图,还可判断图片是否是GIF格式 |
|  `UIImage+WebP` | 用于加载 **WebP** 图片 |
|  `UIImage+MultiFormat` | 根据不同格式的二进制数据转成 `UIImage` 对象 |


- ### SDWebImage 源码解读
`SDWebImage` 功能强大, 核心是图片的下载,缓存等操作, 下载又有预下载,url失效等细节,缓存有内存,磁盘缓存, 源码很详细,因为篇幅有限,这里我详细介绍下 `SDWebImage` 的核心逻辑, 也就是从下载到缓存,最后显示的流程.

>注: 强烈建议先下载我的带备注源码, 结合源码来理解, 这样能更好的学习!!!

以 `UIImageView`为例:
1. `UIImageView+WebCache` 提供了多个加载图片的方法:
```
-(void)sd_setImageWithURL:(nullable NSURL *)url; //之传入图片url
- (void)sd_setImageWithURL:(nullable NSURL *)url
placeholderImage:(nullable UIImage *)placeholder; //可设置占位图
- (void)sd_setImageWithURL:(nullable NSURL *)url
placeholderImage:(nullable UIImage *)placeholder
options:(SDWebImageOptions)options; //可设置占位图和加载方式
- (void)sd_setImageWithURL:(nullable NSURL *)url
completed:(nullable SDExternalCompletionBlock)completedBlock; //
- (void)sd_setImageWithURL:(nullable NSURL *)url
placeholderImage:(nullable UIImage *)placeholder
completed:(nullable SDExternalCompletionBlock)completedBlock; // 在完成的闭包中可获取到 加载的image error 缓存方式 及图片url
- (void)sd_setImageWithURL:(nullable NSURL *)url
placeholderImage:(nullable UIImage *)placeholder
options:(SDWebImageOptions)options
completed:(nullable SDExternalCompletionBlock)completedBlock; 
- (void)sd_setImageWithURL:(nullable NSURL *)url
placeholderImage:(nullable UIImage *)placeholder
options:(SDWebImageOptions)options
progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
completed:(nullable SDExternalCompletionBlock)completedBlock; //可获取到下载进度
- (void)sd_setImageWithPreviousCachedImageWithURL:(nullable NSURL *)url
placeholderImage:(nullable UIImage *)placeholder
options:(SDWebImageOptions)options
progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
completed:(nullable SDExternalCompletionBlock)completedBlock;
```
这几个方法其实内部最后调用的是一个方法,这个方法封装在 `UIView+WebCache` 中,具体代码加注释如下:
```
// 所有加载图片操作都调用这个方法
- (void)sd_internalSetImageWithURL:(nullable NSURL *)url
placeholderImage:(nullable UIImage *)placeholder
options:(SDWebImageOptions)options
operationKey:(nullable NSString *)operationKey
setImageBlock:(nullable SDSetImageBlock)setImageBlock
progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
completed:(nullable SDExternalCompletionBlock)completedBlock {
NSString *validOperationKey = operationKey ?: NSStringFromClass([self class]);
[self sd_cancelImageLoadOperationWithKey:validOperationKey]; //取消之前的下载任务
objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC); //利用runtime动态添加属性

if (!(options & SDWebImageDelayPlaceholder)) {
//如果模式不是 SDWebImageDelayPlaceholder, 则先设置占位图
dispatch_main_async_safe(^{
[self sd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock];
});
}

//url不为nil
if (url) {
// check if activityView is enabled or not
if ([self sd_showActivityIndicatorView]) {
[self sd_addActivityIndicator]; //根据设置判断是否显示进度条
}

__weak __typeof(self)wself = self;
id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager loadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
__strong __typeof (wself) sself = wself;
[sself sd_removeActivityIndicator]; //移除进度条
if (!sself) {
return; //如果self不存在 及已经被释放则return
}
dispatch_main_async_safe(^{
if (!sself) {
return;
}
if (image && (options & SDWebImageAvoidAutoSetImage) && completedBlock) {
// 设置的不自动设置图片, 则通过block返回image
completedBlock(image, error, cacheType, url);
return;
} else if (image) {
//设置图片
[sself sd_setImage:image imageData:data basedOnClassOrViaCustomSetImageBlock:setImageBlock];
[sself sd_setNeedsLayout];
} else {
if ((options & SDWebImageDelayPlaceholder)) {
// image下载不成功则设置占位图
[sself sd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock];
[sself sd_setNeedsLayout];
}
}
if (completedBlock && finished) {
completedBlock(image, error, cacheType, url);
}
});
}];
[self sd_setImageLoadOperation:operation forKey:validOperationKey];
} else {
//url 为nil, block返回error
dispatch_main_async_safe(^{
[self sd_removeActivityIndicator];
if (completedBlock) {
NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
completedBlock(nil, error, SDImageCacheTypeNone, url);
}
});
}
}
```

2. 看上面的代码,在加载图片第一步,会先把这个 `UIImageView` 动态添加的下载操作取消, 如果之前这个 `UIImageView` 没有添加过这个属性则不进行这个操作,这么做的原因是:  `SDWebImage` 将图片对应的下载操作放到 `UIView` 的一个自定义字典属性 `operationDictionary` 中，取消下载操作第一步也是从这个 UIView 的自定义字典属性 `operationDictionary` 中取出所有的下载操作，然后依次调用取消方法，最后将取消的操作从 `operationDictionary)` 字典属性中移除。具体代码+注释如下:
```
// 取消图片加载操作
- (void)sd_cancelImageLoadOperationWithKey:(nullable NSString *)key {
// Cancel in progress downloader from queue
SDOperationsDictionary *operationDictionary = [self operationDictionary]; //获取UIView上动态添加的属性
id operations = operationDictionary[key];
if (operations) { //如果有对应的加载操作
if ([operations isKindOfClass:[NSArray class]]) {
// SDWebImageOperation数组, 将数组中的每个加载操作都取消
for (id <SDWebImageOperation> operation in operations) {
if (operation) {
[operation cancel];
}
}
} else if ([operations conformsToProtocol:@protocol(SDWebImageOperation)]){
//实现 SDWebImageOperation 协议
[(id<SDWebImageOperation>) operations cancel];
}
[operationDictionary removeObjectForKey:key]; //取消后 移除这个属性
}
}
```

3. 移除之前没用的图片下载操作之后就创建一个新的图片下载操作，操作完成后讲操作设置到 `UIView` 的自定义字典属性 `operationDictionary` 中。这个操作是在 1 步骤中, 具体代码如下:
```
objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC); //利用runtime动态添加属性
/// 方法中具体加载操作...
[self sd_setImageLoadOperation:operation forKey:validOperationKey]; //给添加的属性赋值
```
4. 添加了新的下载操作, 点进来看下具体的代码, 发现先判断了url的有效性, `SDWebImage` 保存有一个失效的url列表,如果url请求失败了会加入这个列表,保证不重复请求失效的url.
先点击下载操作查看下下载代码:
```
id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager loadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
```
点进来后解读具体代码:
```
// Prevents app crashing on argument type error like sending NSNull instead of NSURL
if (![url isKindOfClass:NSURL.class]) { //url格式有问题致nil
url = nil;
}

__block SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new]; //new下载操作
__weak SDWebImageCombinedOperation *weakOperation = operation;

BOOL isFailedUrl = NO;
if (url) {
@synchronized (self.failedURLs) {
isFailedUrl = [self.failedURLs containsObject:url]; //判断url是否是失效过的url
}
}
//url长度为0 或 u设置了失败不再请求请求且url为失效url,返回error
if (url.absoluteString.length == 0 || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
[self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil] url:url];
return operation;
}
```
5. url没问题,则开始下载任务, 在下载之前,首先会根据图片的URL生成唯一的key,用来查找内存的磁盘中的缓存.
```
NSString *key = [self cacheKeyForURL:url]; //根据url生成唯一的key
//缓存
operation.cacheOperation = [self.imageCache queryCacheOperationForKey:key done:^(UIImage *cachedImage, NSData *cachedData, SDImageCacheType cacheType) {
```
点击查看查找缓存的具体代码, 首先会先根据key请求内存缓存, 若存在则block传回缓存图片, 若没有则开辟子线程(异步不阻塞主线程)查找磁盘中缓存, 若在磁盘中查找到,会将缓存数据在内存中也缓存份,然后block传回缓存数据.
```
- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key done:(nullable SDCacheQueryCompletedBlock)doneBlock {
if (!key) { //key为nil return nil
if (doneBlock) {
doneBlock(nil, nil, SDImageCacheTypeNone);
}
return nil;
}

// First check the in-memory cache... 先根据key查找内存缓存
UIImage *image = [self imageFromMemoryCacheForKey:key];
if (image) {
NSData *diskData = nil;
if ([image isGIF]) { //是否是GIF图片
diskData = [self diskImageDataBySearchingAllPathsForKey:key];
}
if (doneBlock) { //将内存缓存中找到的图片返回
doneBlock(image, diskData, SDImageCacheTypeMemory);
}
return nil;
}

NSOperation *operation = [NSOperation new]; //这里new operation,是为了使用NSOperation的取消方法,通过设置取消方法来达到取消异步从磁盘中读取缓存的操作
//开子线程 查找磁盘中的缓存
dispatch_async(self.ioQueue, ^{
if (operation.isCancelled) { //操作取消的话  直接return
// do not call the completion if cancelled
return;
}

@autoreleasepool { //根据key查找磁盘缓存
NSData *diskData = [self diskImageDataBySearchingAllPathsForKey:key];
UIImage *diskImage = [self diskImageForKey:key];
if (diskImage && self.config.shouldCacheImagesInMemory) {
NSUInteger cost = SDCacheCostForImage(diskImage); //在磁盘中查找到会在内存中也缓存份
[self.memCache setObject:diskImage forKey:key cost:cost];
}

if (doneBlock) {
dispatch_async(dispatch_get_main_queue(), ^{
doneBlock(diskImage, diskData, SDImageCacheTypeDisk);
});
}
}
});

return operation;
}
```
6. 如果内存和磁盘都没有读取到缓存,则进行下载操作.
```
SDWebImageDownloadToken *subOperationToken = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *downloadedData, NSError *error, BOOL finished) {
```
点进去查看具体的下载代码,设置请求超时时间, 然后创建 `NSMutableURLRequest` 用于请求, 然后新建一个 `SDWebImageDownloaderOperation` 下载任务, 设置参数后, 讲下载任务加入下载队列下载.
```
//传入图片的URL，图片下载过程的Block回调，图片完成的Block回调
- (nullable SDWebImageDownloadToken *)downloadImageWithURL:(nullable NSURL *)url
options:(SDWebImageDownloaderOptions)options
progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock {
__weak SDWebImageDownloader *wself = self;
// 传入对应的参数，addProgressCallback: completedBlock: forURL: createCallback: 方法
return [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^SDWebImageDownloaderOperation *{
__strong __typeof (wself) sself = wself;
//超时时间 默认15秒
NSTimeInterval timeoutInterval = sself.downloadTimeout;
if (timeoutInterval == 0.0) {
timeoutInterval = 15.0;
}

// In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
// Header的设置
NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:(options & SDWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
request.HTTPShouldHandleCookies = (options & SDWebImageDownloaderHandleCookies);
request.HTTPShouldUsePipelining = YES;
if (sself.headersFilter) {
request.allHTTPHeaderFields = sself.headersFilter(url, [sself.HTTPHeaders copy]);
}
else {
request.allHTTPHeaderFields = sself.HTTPHeaders;
}
//创建 SDWebImageDownloaderOperation，这个是下载任务的执行者。并设置对应的参数
SDWebImageDownloaderOperation *operation = [[sself.operationClass alloc] initWithRequest:request inSession:sself.session options:options];
operation.shouldDecompressImages = sself.shouldDecompressImages;
//用于请求认证
if (sself.urlCredential) {
operation.credential = sself.urlCredential;
} else if (sself.username && sself.password) {
operation.credential = [NSURLCredential credentialWithUser:sself.username password:sself.password persistence:NSURLCredentialPersistenceForSession];
}
//下载任务优先级
if (options & SDWebImageDownloaderHighPriority) {
operation.queuePriority = NSOperationQueuePriorityHigh;
} else if (options & SDWebImageDownloaderLowPriority) {
operation.queuePriority = NSOperationQueuePriorityLow;
}
//加入任务的执行队列
[sself.downloadQueue addOperation:operation];
if (sself.executionOrder == SDWebImageDownloaderLIFOExecutionOrder) {
// Emulate LIFO execution order by systematically adding new operations as last operation's dependency
[sself.lastAddedOperation addDependency:operation];
sself.lastAddedOperation = operation;
}

return operation;
}];
}
```
7. 如果该 url 是第一次加载的话，那么就会执行 createCallback 这个回调block ,然后在 createCallback 里面开始构建网络请求，在下载过程中执行各类进度 block 回调.
```
- (nullable SDWebImageDownloadToken *)addProgressCallback:(SDWebImageDownloaderProgressBlock)progressBlock
completedBlock:(SDWebImageDownloaderCompletedBlock)completedBlock
forURL:(nullable NSURL *)url
createCallback:(SDWebImageDownloaderOperation *(^)())createCallback {
// The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
if (url == nil) { //url为nil block传回nil
if (completedBlock != nil) {
completedBlock(nil, nil, nil, NO);
}
return nil;
}

__block SDWebImageDownloadToken *token = nil;
// dispatch_barrier_sync 是前面的任务结束后这个任务才执行, 这个执行完后下个才执行, 串行操作
dispatch_barrier_sync(self.barrierQueue, ^{
SDWebImageDownloaderOperation *operation = self.URLOperations[url]; //根据url取下载操作
if (!operation) { //如果url之前没有下载操作, 即第一次加载, 则 createCallback
operation = createCallback();
self.URLOperations[url] = operation;

__weak SDWebImageDownloaderOperation *woperation = operation;
operation.completionBlock = ^{
SDWebImageDownloaderOperation *soperation = woperation;
if (!soperation) return;
if (self.URLOperations[url] == soperation) {
[self.URLOperations removeObjectForKey:url];
};
};
}
id downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock completed:completedBlock];

token = [SDWebImageDownloadToken new];
token.url = url;
token.downloadOperationCancelToken = downloadOperationCancelToken;
});

return token;
}
```
8. 图片下载完成后, 会回到完成的的 block 回调中做图片转换处理和缓存操作.
![转换和缓存](https://upload-images.jianshu.io/upload_images/8283020-5b8ff1ea222d8cb4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

9. 下载和解码缓存后, 就只剩最后一步,即回到` UIImageView` 控件的设置图片方法 block 回调中，给对应的 `UIImageView` 设置图片, 整个加载流程到这里就完成了.
```
dispatch_main_async_safe(^{
if (!sself) {
return;
}
if (image && (options & SDWebImageAvoidAutoSetImage) && completedBlock) {
// 设置的不自动设置图片, 则通过block返回image
completedBlock(image, error, cacheType, url);
return;
} else if (image) {
//设置图片
[sself sd_setImage:image imageData:data basedOnClassOrViaCustomSetImageBlock:setImageBlock];
[sself sd_setNeedsLayout];
} else {
if ((options & SDWebImageDelayPlaceholder)) {
// image下载不成功则设置占位图
[sself sd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock];
[sself sd_setNeedsLayout];
}
}
if (completedBlock && finished) {
completedBlock(image, error, cacheType, url);
}
});
}];
```

- ###  `SDWebImage` 使用中常见问题
1. 使用 `UITableViewCell` 中的` imageView` 加载不同尺寸的网络图片时会出现尺寸缩放问题.
>解决方案：可以自定义 `UITableViewCell`，重写 `-layoutSubviews` 方法，调整位置尺寸；或者直接弃用 `UITableViewCell` 的 `imageView`，自己添加一个 `imageView` 作为子控件。
2. `SDWebImage` 在进行缓存时忽略了所有服务器返回的 `caching control` 设置，并且在缓存时没有做时间限制，这也就意味着图片 **URL** 必须是静态的了，要求服务器上一个 **URL** 对应的图片内容不允许更新。但是如果存储图片的服务器不由自己控制，也就是说 图片内容更新了，**URL** 却没有更新，这种情况怎么办？
> 解决方案：在调用 `sd_setImageWithURL: placeholderImage: options:` 方法时设置 `options` 参数为 `SDWebImageRefreshCached`，这样虽然会降低性能，但是下载图片时会照顾到服务器返回的 `caching control`。
3. 在加载图片时，如何添加默认的 `progress indicator` ？
>解决方案：在调用 `-sd_setImageWithURL:` 方法之前，先调用展示进度条方法, 完成后不需要管, 因为 `SDWebImage`里面完成后已经对进度条进行隐藏.
```
/**
*  Show activity UIActivityIndicatorView
*/
- (void)sd_setShowActivityIndicatorView:(BOOL)show;

*  set desired UIActivityIndicatorViewStyle
*
*  @param style The style of the UIActivityIndicatorView
*/
- (void)sd_setIndicatorStyle:(UIActivityIndicatorViewStyle)style;
```
4. `SDWebImage` 在加载图片网络请求的 `NSURLConnection` 的代理中对httpCode 做了判断，当 httpCode 为 304 的时候放弃下载，读取缓存,如果遇到304请求需要请求的课修改代码, 具体代码如下:
![](https://upload-images.jianshu.io/upload_images/8283020-17512971f62582af.png)

- ### 总结
`SDWebImage` 是一个非常好的图片加载框架，提供的使用方法和接口对开发者来说非常友好。其内部实现多是采用 block 的方式来实现回调，代码阅读起来可能没有那么直观, 但是使用起来非常便捷。
我写这篇文章主要是结合`SDWebImage`的源码给大家讲解 `SDWebImage` 加载图片的大概流程，里面细节很多, 我解读的只是其中的大流程, 具体细节可结合文章然后下载我带备注的源码好好阅读,希望对大家有所帮助。文章中有不对的地方,可以给我评论，我会在第一时间改正, 如果这篇文章对你所有帮助, 可以 `star` 下哈。









