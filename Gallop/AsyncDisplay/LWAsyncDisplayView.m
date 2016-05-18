/*
 https://github.com/waynezxcv/Gallop

 Copyright (c) 2016 waynezxcv <liuweiself@126.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */


#import "LWAsyncDisplayView.h"
#import "GallopUtils.h"
#import "CALayer+WebCache.h"
#import "CALayer+GallopAddtions.h"
#import "NSObject+SwizzleMethod.h"


typedef void(^foundLinkCompleteBlock)(LWTextStorage* foundTextStorage,id linkAttributes);


@interface LWAsyncDisplayView ()

@property (nonatomic,strong) NSMutableArray* imageContainers;
@property (nonatomic,assign) BOOL autoReuseImageContainer;
@property (nonatomic,assign) NSInteger maxImageStorageCount;

@end


@implementation LWAsyncDisplayView{
    NSArray* _textStorages;
    NSArray* _imageStorages;
    LWTextHighlight* _highlight;
    BOOL _showingHighlight;
    BOOL _cleanedImageContainer;
    BOOL _setedImageContents;
    BOOL _displayed;
}

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame maxImageStorageCount:(NSInteger)count {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
        self.autoReuseImageContainer = NO;
        self.maxImageStorageCount = count;
        for (NSInteger i = 0; i < self.maxImageStorageCount; i ++) {
            //            LWImageContainer* container = [LWImageContainer layer];
            //            [self.layer addSublayer:container];
            //            [self.imageContainers addObject:container];
        }
    }
    return self;
}


- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.opaque = YES;
    self.layer.contentsScale = [GallopUtils contentsScale];
    _showingHighlight = NO;
    _cleanedImageContainer = YES;
    _setedImageContents = NO;
    _displayed = NO;
}

- (void)setLayout:(LWLayout *)layout {
    if (_layout == layout || [_layout isEqual:layout]) {
        return;
    }
    [self _cleanup];
    _layout = layout;
    [self _updateLayout];

}

- (void)setFrame:(CGRect)frame {
    CGSize oldSize = self.bounds.size;
    CGSize newSize = frame.size;
    if (!CGSizeEqualToSize(oldSize, newSize) &&
        !CGSizeEqualToSize(newSize,CGSizeZero)) {
        [super setFrame:frame];
        [self _setNeedDisplay];
    }
}

- (void)setBounds:(CGRect)bounds {
    CGSize oldSize = self.bounds.size;
    CGSize newSize = bounds.size;
    if (!CGSizeEqualToSize(oldSize, newSize) &&
        !CGSizeEqualToSize(newSize,CGSizeZero)) {
        [super setBounds:bounds];
        [self _setNeedDisplay];
    }
}

#pragma mark - Private

- (void)_cleanup {

    for (LWTextStorage* textStorage in _textStorages) {
        [textStorage.textLayout removeAttachmentFromSuperViewOrLayer];
    }
    if (!_cleanedImageContainer) {
        for (NSInteger i = 0; i < self.imageContainers.count; i ++) {
            //            LWImageContainer* container = self.imageContainers[i];
            //            [container cleanup];
        }
    }

    LWLayout* layout = _layout;
    _layout = nil;

    LWTextHighlight* highlight = _highlight;
    _highlight = nil;

    NSArray* textStroages = _textStorages;
    _textStorages = nil;

    NSArray* imageStorages = _imageStorages;
    _imageStorages = nil;

    _showingHighlight = NO;
    _cleanedImageContainer = YES;
    _setedImageContents = NO;
    _displayed = NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [textStroages count];
        [layout class];
        [highlight class];
        [imageStorages count];
    });
}

- (void)_updateLayout {
    _imageStorages = self.layout.imageStorages;
    _setedImageContents = NO;

    _textStorages = self.layout.textStorages;
    _displayed = NO;


    [self _auotoUpdateImgeContainersIfNeed];
    [self _setImageStorages];
    [self _setNeedDisplay];
}

- (void)_auotoUpdateImgeContainersIfNeed {
    if (self.autoReuseImageContainer == YES) {
        [self _autoReuseImageContainers];
        [self _autoSetImageStorages];
    }
}

- (void)_autoSetImageStorages {
    if (!_setedImageContents) {
        for (NSInteger i = 0 ; i < _imageStorages.count; i ++) {
            LWImageStorage* imageStorage = _imageStorages[i];
            //            LWImageContainer* container = self.imageContainers[i];
            //            if (imageStorage.type == LWImageStorageWebImage) {
            //                [container delayLayoutImageStorage:imageStorage];
            //                [container setContentWithImageStorage:imageStorage];
            //            }
        }
        _setedImageContents = YES;
        _cleanedImageContainer = NO;
    }
}

- (void)_setImageStorages {
    if (!self.autoReuseImageContainer && !_setedImageContents) {
        for (NSInteger i = 0; i < _imageStorages.count; i ++) {
            LWImageStorage* imageStorage = _imageStorages[i];
            if (self.imageContainers.count > i) {
                //                LWImageContainer* container = self.imageContainers[i];
                //                if (imageStorage.type == LWImageStorageWebImage) {
                //                    [container delayLayoutImageStorage:imageStorage];
                //                    [container setContentWithImageStorage:imageStorage];
                //                }
            }
        }
        _setedImageContents = YES;
        _cleanedImageContainer = NO;
    }
}

- (void)_autoReuseImageContainers {
    if (self.isNeedRestImageContainers) {
        NSInteger delta = self.imageContainers.count - _imageStorages.count;
        if (delta < 0) {
            for (NSInteger i = 0; i < _imageStorages.count; i ++) {
                if (i < ABS(delta)) {
                    //                    LWImageContainer* container = [LWImageContainer layer];
                    //                    [self.layer addSublayer:container];
                    //                    [self.imageContainers addObject:container];
                }
            }
        } else if (delta > 0 ) {
            for (NSInteger i = 0; i < self.imageContainers.count; i ++ ) {
                if (i >= _imageStorages.count) {
                    //                    LWImageContainer* container = self.imageContainers[i];
                    //                    [container cleanup];
                }
            }
        }
    }
}

- (BOOL)isNeedRestImageContainers {
    if (self.imageContainers.count == _imageStorages.count) {
        return NO;
    }
    return YES;
}

#pragma mark - Display
- (void)_setNeedDisplay {
    if (!_displayed) {
        [self _commitDisplay];
    }
}

- (void)_commitDisplay {
    [self lw_addDisplayTransactionsWithasyncDisplay:^(CGContextRef context, CGSize size) {
        [self _drawStoragesInContext:context];
    } complete:^(id displayContent, BOOL isFinished) {
        if (isFinished) {
            _displayed = YES;
        }
    }];
}

- (void)setNeedRedDraw {
    [self lw_asyncDisplay:^(CGContextRef context, CGSize size) {
        [self _drawStoragesInContext:context];
    } complete:^(id displayContent, BOOL isFinished) {
        if (isFinished) {
            _displayed = YES;
        }
    }];
}

- (void)_drawStoragesInContext:(CGContextRef)context {
    if (_showingHighlight && _highlight) {
        for (NSString* rectString in _highlight.positions) {
            CGRect rect = CGRectFromString(rectString);
            UIBezierPath* beizerPath = [UIBezierPath bezierPathWithRoundedRect:rect
                                                                  cornerRadius:2.0f];
            [_highlight.hightlightColor setFill];
            [beizerPath fill];
        }
    }

    for (LWTextStorage* textStorage in _textStorages) {
        [textStorage.textLayout drawIncontext:context
                                         size:textStorage.textLayout.textBoundingSize
                                        point:textStorage.frame.origin
                                containerView:self
                               containerLayer:self.layer];
    }
    for (LWImageStorage* imageStorage in _imageStorages) {
        //        if (imageStorage.type == LWImageStorageLocalImage) {
        //            [imageStorage.image drawInRect:imageStorage.frame];
        //        }
    }
}


#pragma mark - Touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    BOOL found = NO;
    UITouch* touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    for (LWTextStorage* textStorage in _textStorages) {
        if (textStorage == nil) {
            continue;
        }
        if ([textStorage isKindOfClass:[LWTextStorage class]]) {
            CTFrameRef textFrame = textStorage.textLayout.ctFrame;
            if (textFrame == NULL) {
                continue;
            }
            LWTextHighlight* hightlight = [self _isNeedShowHighlight:textStorage
                                                          touchPoint:touchPoint];
            if (hightlight) {
                [self _showHighlight:hightlight];
                found = YES;
            }
        }
    }
    if (!found) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    BOOL found = NO;

    UITouch* touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    for (LWTextStorage* textStorage in _textStorages) {
        if (textStorage == nil) {
            continue;
        }
        if ([textStorage isKindOfClass:[LWTextStorage class]]) {
            CTFrameRef textFrame = textStorage.textLayout.ctFrame;
            if (textFrame == NULL) {
                continue;
            }
            LWTextHighlight* hightlight = [self _isNeedShowHighlight:textStorage
                                                          touchPoint:touchPoint];
            if (hightlight) {
                [self _showHighlight:hightlight];
                found = YES;
            } else {
                [self _hideHightlight];
            }
        }
    }
    if (!found) {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    __block BOOL found = NO;
    UITouch* touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    for (LWImageStorage* imageStorage in _imageStorages) {
        if (imageStorage == nil) {
            continue;
        }
        if (CGRectContainsPoint(imageStorage.frame, touchPoint)) {
            //            if ([self.delegate respondsToSelector:@selector(lwAsyncDisplayView:didCilickedImageStorage:touch:)]) {
            //                found = YES;
            //                [self.delegate lwAsyncDisplayView:self didCilickedImageStorage:imageStorage touch:touch];
            //            }
        }
    }
    for (LWTextStorage* textStorage in _textStorages) {
        if (textStorage == nil) {
            continue;
        }
        if ([textStorage isKindOfClass:[LWTextStorage class]]) {
            CTFrameRef textFrame = textStorage.textLayout.ctFrame;
            if (textFrame == NULL) {
                continue;
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                found = [self _handleLinkTouchIfNeed:textStorage touchPoint:touchPoint];
                [self _removeHightlight];
            });
        }
    }
    if (!found) {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
}


- (LWTextHighlight *)_isNeedShowHighlight:(LWTextStorage *)textStorage touchPoint:(CGPoint)touchPoint {
    __block LWTextHighlight* highlight;
    [self _foundLinkWithTextStroage:textStorage touchPoint:touchPoint
                         completion:^(LWTextStorage *foundTextStorage, id linkAttributes) {
                             for (LWTextHighlight* foundHighlight in foundTextStorage.textLayout.textHighlights) {
                                 if ([foundHighlight.content isEqual:linkAttributes]) {
                                     highlight = foundHighlight;
                                 }
                             }
                         }];
    return highlight;
}


- (BOOL)_handleLinkTouchIfNeed:(LWTextStorage *)textStorage touchPoint:(CGPoint)touchPoint {
    __block BOOL found = NO;
    __weak typeof(self) weakSelf = self;
    [self _foundLinkWithTextStroage:textStorage touchPoint:touchPoint
                         completion:^(LWTextStorage *foundTextStorage, id linkAttributes) {
                             __strong typeof(weakSelf) strongSelf = weakSelf;
                             //                             if ([strongSelf.delegate respondsToSelector:@selector(lwAsyncDisplayView:didCilickedLinkWithfData:)] &&
                             //                                 [strongSelf.delegate conformsToProtocol:@protocol(LWAsyncDisplayViewDelegate)]) {
                             //                                 [strongSelf.delegate lwAsyncDisplayView:strongSelf didCilickedLinkWithfData:linkAttributes];
                             //                                 found = YES;
                             //                             }
                         }];
    return found;
}

- (void)_foundLinkWithTextStroage:(LWTextStorage *)textStorage
                       touchPoint:(CGPoint) touchPoint
                       completion:(foundLinkCompleteBlock)completion {
    CTFrameRef textFrame = textStorage.textLayout.ctFrame;
    CFArrayRef lines = CTFrameGetLines(textFrame);
    CGPoint origins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
    CGPathRef path = CTFrameGetPath(textFrame);
    CGRect boundsRect = CGPathGetBoundingBox(path);
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformMakeTranslation(0, boundsRect.size.height);
    transform = CGAffineTransformScale(transform, 1.f, -1.f);
    for (int i= 0; i < CFArrayGetCount(lines); i++) {
        CGPoint linePoint = origins[i];
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGRect flippedRect = [self _getLineBounds:line point:linePoint];
        CGRect rect = CGRectApplyAffineTransform(flippedRect, transform);
        CGRect adjustRect = CGRectMake(rect.origin.x + boundsRect.origin.x,
                                       rect.origin.y + boundsRect.origin.y,
                                       rect.size.width,
                                       rect.size.height);
        if (CGRectContainsPoint(adjustRect, touchPoint)) {
            CGPoint relativePoint = CGPointMake(touchPoint.x - CGRectGetMinX(adjustRect),
                                                touchPoint.y - CGRectGetMinY(adjustRect));
            CFIndex index = CTLineGetStringIndexForPosition(line, relativePoint);
            CTRunRef touchedRun;
            NSArray* runObjArray = (NSArray *)CTLineGetGlyphRuns(line);
            for (NSInteger i = 0; i < runObjArray.count; i ++) {
                CTRunRef runObj = (__bridge CTRunRef)[runObjArray objectAtIndex:i];
                CFRange range = CTRunGetStringRange((CTRunRef)runObj);
                if (NSLocationInRange(index, NSMakeRange(range.location, range.length))) {
                    touchedRun = runObj;
                    NSDictionary* runAttribues = (NSDictionary *)CTRunGetAttributes(touchedRun);
                    if ([runAttribues objectForKey:LWTextLinkAttributedName]) {
                        completion(textStorage,[runAttribues objectForKey:LWTextLinkAttributedName]);
                        break;
                    }
                }
            }
        }
    }
}

- (void)_showHighlight:(LWTextHighlight *)highlight {
    _showingHighlight = YES;
    _highlight = highlight;
    [self setNeedRedDraw];
}

- (void)_hideHightlight {
    if (!_showingHighlight) {
        return;
    }
    _showingHighlight = NO;
    [self setNeedRedDraw];
}

- (void)_removeHightlight {
    [self _hideHightlight];
    _highlight = nil;
}

- (CGRect)_getLineBounds:(CTLineRef)line point:(CGPoint)point {
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGFloat height = ascent + descent;
    return CGRectMake(point.x, point.y - descent, width, height);
}

#pragma mark - Getter

- (NSMutableArray *)imageContainers {
    if (_imageContainers) {
        return _imageContainers;
    }
    _imageContainers = [[NSMutableArray alloc] init];
    return _imageContainers;
}


@end
