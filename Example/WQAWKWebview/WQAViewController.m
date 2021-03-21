//
//  WQAViewController.m
//  WQAWebviewComponent_Example
//
//

#import "WQAViewController.h"
#import "WebViewController.h"
#import <WQAResourceManager.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface WQAViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray<NSString *> *items;
@end

@implementation WQAViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _items = @[@"Webview", @"Webview2"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat cacheSize = [[WQAResourceManager sharedInstance] diskCacheSize];
    NSLog(@"cacheSize: %f", cacheSize);
    NSURL *url = [NSURL URLWithString:@"http://www.testurl.com:8080/subpath/subsubpath.html?uid=123&gid=456#fragment=wwww"];
    NSLog(@"%@, %@, %@, %@, %@, %@, %@, %@, %@", url.path, url.pathExtension, url.absoluteString, url.scheme, url.host, url.port, url.query, url.fragment, url.filePathURL.absoluteString);
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    WKWebView *web1 = [[WKWebView alloc] initWithFrame:CGRectZero];
    WKWebView *web2 = [[WKWebView alloc] initWithFrame:CGRectZero];
    WKWebView *web3 = [[WKWebView alloc] initWithFrame:CGRectZero];
    NSLog(@"processPool %@ %@ %@", web1.configuration.processPool, web2.configuration.processPool, web3.configuration.processPool);
    NSAssert(web1.configuration.processPool == web2.configuration.processPool && web2.configuration.processPool == web3.configuration.processPool, @"process instance");
    [self.view addSubview:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_items[indexPath.row]];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:_items[indexPath.row]];
    }
    cell.textLabel.text = _items[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            [self showWebVCWithUrl:@"https://www.163.com/"];
            break;
        case 1:
            [self showWebVCWithUrl:@"https://ocmock.org/download/"];
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showWebVCWithUrl:(NSString *)url {
    WebViewController *vc = [[WebViewController alloc] initWithUrl:url];
    vc.edgesForExtendedLayout = UIRectEdgeNone;
    WQABridgeInvokeItem *item = [WQABridgeInvokeItem bridgeItemWithHandler:self handler:^(id  _Nullable data, WQAResponseCallback  _Nullable responseCallback) {

    }];
    [vc.bridgeHandlerLoad.WQAScriptBridge registerInvocationForName:@"InvokeTestFinished" invocation:item];

    [self.navigationController pushViewController:vc animated:YES];
}
@end

