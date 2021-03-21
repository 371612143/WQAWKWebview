//
//  WQADocumenuViewController.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/9/27.
//

#import "WQADocumenuViewController.h"
#import <CoreServices/UTCoreTypes.h>
#import <WQAWebCommonDefine.h>
#import <AVFoundation/AVCaptureDevice.h>

@interface WQADocumenuViewController()<UIDocumentMenuDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate>
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, copy) WQAResponseCallback JSCallback;
@end

@implementation WQADocumenuViewController

- (instancetype)initWithJSCallback:(WQAResponseCallback)callback {
    NSArray * documentTypes = @[(__bridge NSString *) kUTTypeDiskImage];
    if (self = [super initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeOpen]) {
        [self setUpDocumentMenu];
        self.JSCallback = callback;
    }
    return self;
}

- (void)setUpDocumentMenu {
    self.delegate = self;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.imagePicker.allowsEditing = YES;
    
    WEAK_SELF_DECLARED
    [self addOptionWithTitle:@"Photo Libray" image:nil order:UIDocumentMenuOrderFirst handler:^{
        STRONG_SELF_BEGIN
        [strongSelf showImagePickViewController:UIImagePickerControllerSourceTypePhotoLibrary];
        STRONG_SELF_END
    }];
    
    [self addOptionWithTitle:@"Take Photo or Video" image:nil order:UIDocumentMenuOrderFirst handler:^{
        STRONG_SELF_BEGIN
        [strongSelf showImagePickViewController:UIImagePickerControllerSourceTypeCamera];
        STRONG_SELF_END
    }];
    
}

- (void)showImagePickViewController:(UIImagePickerControllerSourceType)sourceType {
    self.imagePicker.sourceType = sourceType;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)uploadFile:(NSString *)path data:(NSData *)data {
    
}

#pragma mark UIDocumentMenuDelegate
- (void)documentMenuWasCancelled:(UIDocumentMenuViewController *)documentMenu {
    self.JSCallback(nil, @{@"code":@(1)});
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:documentPicker animated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    self.JSCallback(nil, @{@"code":@(1)});
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    for (NSURL *url in urls) {
        [self documentPicker:controller didPickDocumentAtURL:url];
    }
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.JSCallback(nil, @{@"code":@(1)});
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    NSURL *fileURL = (NSURL *)info[@"UIImagePickerControllerImageURL"];
    WEAK_SELF_DECLARED
    
    [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
}

@end
