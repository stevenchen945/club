//
//  PersionController.m
//  club
//
//  Created by steven on 13-5-10.
//  Copyright (c) 2013年 ibm. All rights reserved.
//

#import "PersionController.h"
#import "HTTPTools.h"
#import "AppDelegate.h"
#import "JSONKit.h"
#import "Share.h"
#import "ShareCell.h"
#import "Cache.h"

@interface PersionController ()

@end

@implementation PersionController

@synthesize listData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"个人中心", @"个人中心");
        self.tabBarItem.image = [UIImage imageNamed:@"profile"];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    
	if (_refreshHeaderView == nil) {
		
		EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - 65, self.view.frame.size.width, 65)];
		view.delegate = self;
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"111"]];
        imgView.frame = view.bounds;
        view.backGroundView = imgView;
        view.backgroundColor = [UIColor clearColor];
		[self.tableView addSubview:view];
		_refreshHeaderView = view;
        //  update the last update date
        [_refreshHeaderView refreshLastUpdatedDate];
		
        [self.view setNeedsLayout];
        [self.tableView setNeedsLayout];
        if (self.tableView.frame.size.height < self.tableView.contentSize.height) {
            EGORefreshTableHeaderView *footerView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0, self.tableView.contentSize.height, 320, 65)];
            footerView.delegate = self;
            footerView.footerRefresh = YES;
            footerView.backgroundColor = [UIColor clearColor];
            [self.tableView addSubview:footerView];
            _footerRefreshView = footerView;
            [_footerRefreshView refreshLastUpdatedDate];
            
        }
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self loadHeader] ;
    self.listData = [self getLists];
    [self.tableView reloadData];
}


-(void) loadHeader
{
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    
    NSString *response = [HTTPTools sendAuthHttpUrl:[NSString stringWithFormat:@"/api/users/show.json?id=%@&authid=%@", appDelegate.currUserId, appDelegate.username] Method:@"GET" UserName:appDelegate.username Password:appDelegate.password] ;
    
    NSDictionary *dict = [response objectFromJSONString];
    
    self.titleItem.title = [NSString stringWithFormat:@"%@的大杂烩",[dict objectForKey: @"screen_name"]] ;
    
    self.personName.text = [dict objectForKey: @"screen_name"] ;
    
    [self downloadImageActor:[dict objectForKey: @"profile_image_url"]] ;
    
    [self.actorButton setBackgroundImage:self.profileImage forState:UIControlStateNormal] ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [listData count] ;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 列寬
    CGFloat contentWidth = 260; //self.tableView.frame.size.width;
    // 用何種字體進行顯示
    UIFont *font = [UIFont systemFontOfSize:16];
    
    // 該行要顯示的內容
    Share *msg = [listData objectAtIndex:indexPath.row];
    NSString *content = msg.msgBody ;
    // 計算出顯示完內容需要的最小尺寸
    CGSize size = [content sizeWithFont:font constrainedToSize:CGSizeMake(contentWidth, 1000) lineBreakMode:UILineBreakModeWordWrap];
    
    // 這裏返回需要的高度
    
    if(size.height > 80){
        size.height = 80 ;
    }
    
    if(msg.msgAttach == nil || [@"" isEqualToString:msg.msgAttach]){
        size.height = size.height  + 80 + 20 ;
    }else{
        size.height = size.height  + 80 + 20 + 100 ;
    }
    
    return size.height;
}

- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    
    appDelegate.currShare = (Share *)[listData objectAtIndex:row];
    
    [appDelegate gotoShareDetailPage] ;
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // 列寬
    CGFloat contentWidth = 260 ;
    // 用何種字體進行顯示
    UIFont *font = [UIFont systemFontOfSize:16];
    
    NSUInteger row = [indexPath row];
    
    Share *msg = (Share *)[listData objectAtIndex:row];
    
    static NSString *TableSampleIdentifier = @"ShareCellIdentifier";
    
    ShareCell *cell = [tableView dequeueReusableCellWithIdentifier:
                       TableSampleIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ShareCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    CGSize size = [msg.msgBody sizeWithFont:font constrainedToSize:CGSizeMake(contentWidth, 1000) lineBreakMode:UILineBreakModeWordWrap];
    
    [cell.textLabel setContentMode:UIViewContentModeRight] ;
    
    cell.attactment = nil ;
    cell.avatar = nil ;
    cell.toPersion = NO ;
    
    //NSURL *url = [NSURL URLWithString:msg.msgActor];
    
    NSArray *data = [NSArray arrayWithObjects:msg.msgActor, cell, nil];
    
    [NSThread detachNewThreadSelector:@selector(downloadImageShareActor:) toTarget:self withObject:data];
    
    if(msg.msgAttach != nil && ![@"" isEqualToString:msg.msgAttach]){
        NSArray *data = [NSArray arrayWithObjects:msg.msgAttach,cell, nil];
        [NSThread detachNewThreadSelector:@selector(downloadImageShareCell:) toTarget:self withObject:data];
    }
    
    CGRect rect = [cell.bodyLabel textRectForBounds:cell.bodyLabel.frame limitedToNumberOfLines:0];
    CGRect attachRect = cell.attachView.frame;
    attachRect.origin.x = rect.origin.x ;
    attachRect.origin.y = rect.origin.y + rect.size.height + 20;
    attachRect.size.width = 80 ;
    attachRect.size.height = 80 ;
    
    if(size.height > 80){
        size.height = 80 ;
    }
    
    // 設置顯示榘形大小
    rect.size = size;
    // 重置列文本區域
    cell.bodyLabel.frame = rect;
    //cell.bodyView.frame = rect;
    cell.attachView.frame = CGRectMake(rect.origin.x, rect.origin.y + rect.size.height + 20, 80, 80);
    cell.body = [NSString stringWithFormat:@"%@", msg.msgBody] ;
    cell.title = msg.msgTitle ;
    cell.time = msg.msgTime ;
    cell.userId = msg.msgUserId ;
    
    // 設置自動換行(重要)
    cell.bodyLabel.numberOfLines = 0;
    // 設置顯示字體(一定要和之前計算時使用字體一至)
    cell.bodyLabel.font = font;
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath
{
    //Message *msg = [listData objectAtIndex:indexPath.row] ;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //Message *msg = [listData objectAtIndex:indexPath.row] ;
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if (action == @selector(copy:)) {
		return YES;
	}
	
	return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if (action == @selector(copy:)) {
        Share *share = (Share *)[self.listData objectAtIndex:indexPath.row];
		[UIPasteboard generalPasteboard].string = share.msgBody;
	}
}

-(NSMutableArray *) getLists
{
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *urlString = [NSString stringWithFormat:@"/api/statuses/user_timeline.json?user_id=%@", appDelegate.currUserId] ;
    
    NSString *response = [HTTPTools sendAuthHttpUrl:urlString Method:@"GET" UserName:appDelegate.username Password:appDelegate.password] ;
    
    if(response == nil){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"网络异常，请检查网络！" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return result ;
    }
    
    NSArray *items = [response objectFromJSONString] ;
    
    for(int i = 0; i < items.count; i++){
        NSDictionary *item = [items objectAtIndex:i] ;
        Share *msg = [[Share alloc] init] ;
        msg.msgId = [item objectForKey: @"id"] ;
        msg.msgBody = [item objectForKey: @"text"];
        NSDictionary *user = [item objectForKey: @"user"];
        msg.msgActor = [user objectForKey: @"profile_image_url"];
        msg.msgTitle = [user objectForKey: @"name"];
        msg.msgUserId = [user objectForKey: @"id"];
        msg.msgTime = [item objectForKey: @"created_at"];
        msg.msgTime = [msg.msgTime substringToIndex:19] ;
        
        NSArray *attachments = [item objectForKey: @"attachments"];
        if(attachments != nil && [attachments count] > 0){
            NSDictionary *attach = [attachments objectAtIndex:0] ;
            msg.msgAttach = [attach objectForKey:@"url"] ;
        }
        [result addObject:msg];
    }
    
    return result ;
}

-(void) reloadLists
{
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;

    NSString *urlString = [NSString stringWithFormat:@"/api/statuses/user_timeline.json?user_id=%@", appDelegate.currUserId] ;
    
    NSString *response = [HTTPTools sendAuthHttpUrl:urlString Method:@"GET" UserName:appDelegate.username Password:appDelegate.password] ;
    
    if(response == nil){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"网络异常，请检查网络！" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return ;
    }
    
    NSArray *items = [response objectFromJSONString] ;
    
    for(int i = 0; i < items.count; i++){
        NSDictionary *item = [items objectAtIndex:i] ;
        Share *msg = [[Share alloc] init] ;
        msg.msgId = [item objectForKey: @"id"] ;
        msg.msgBody = [item objectForKey: @"text"];
        NSDictionary *user = [item objectForKey: @"user"];
        msg.msgActor = [user objectForKey: @"profile_image_url"];
        msg.msgTitle = [user objectForKey: @"name"];
        msg.msgUserId = [user objectForKey: @"id"];
        msg.msgTime = [item objectForKey: @"created_at"];
        msg.msgTime = [msg.msgTime substringToIndex:19] ;
        
        NSArray *attachments = [item objectForKey: @"attachments"];
        if(attachments != nil && [attachments count] > 0){
            NSDictionary *attach = [attachments objectAtIndex:0] ;
            msg.msgAttach = [attach objectForKey:@"url"] ;
        }
        if(self.listData.count > 0){
            Share *latestShare = [self.listData objectAtIndex:0] ;
            if([latestShare.msgId intValue] < [msg.msgId intValue]){
                [self.listData insertObject:msg atIndex:0];
            }
        }else{
            [self.listData insertObject:msg atIndex:0];
        }
    }
}

-(void) reloadOldLists
{
    if(listData.count == 0){
        [self reloadLists] ;
        return ;
    }
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    
    Share *oldestShare = [self.listData objectAtIndex:(self.listData.count - 1)] ;
    
    NSString *urlString = [NSString stringWithFormat:@"/api/statuses/user_timeline.json?max_id=%@&count=21&user_id=%@", oldestShare.msgId, appDelegate.currUserId] ;
    
    NSString *response = [HTTPTools sendAuthHttpUrl:urlString Method:@"GET" UserName:appDelegate.username Password:appDelegate.password] ;
    
    if(response == nil){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"网络异常，请检查网络！" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return ;
    }
    
    NSArray *items = [response objectFromJSONString] ;
    
    for(int i = 1; i < items.count; i++){
        NSDictionary *item = [items objectAtIndex:i] ;
        Share *msg = [[Share alloc] init] ;
        msg.msgId = [item objectForKey: @"id"] ;
        msg.msgBody = [item objectForKey: @"text"];
        NSDictionary *user = [item objectForKey: @"user"];
        msg.msgActor = [user objectForKey: @"profile_image_url"];
        msg.msgTitle = [user objectForKey: @"name"];
        msg.msgUserId = [user objectForKey: @"id"];
        msg.msgTime = [item objectForKey: @"created_at"];
        msg.msgTime = [msg.msgTime substringToIndex:19] ;
        
        NSArray *attachments = [item objectForKey: @"attachments"];
        if(attachments != nil && [attachments count] > 0){
            NSDictionary *attach = [attachments objectAtIndex:0] ;
            msg.msgAttach = [attach objectForKey:@"url"] ;
        }
        [self.listData addObject:msg];
    }
}

+ (void) describeDictionary: (NSDictionary *)dict
{
    NSArray *keys;
    int i, count;
    id key, value;
    
    keys = [dict allKeys];
    count = [keys count];
    for (i = 0; i < count; i++)
    {
        key = [keys objectAtIndex: i];
        value = [dict objectForKey: key];
        NSLog (@"Key: %@ for value: %@", key, value);
    }
}

- (void) changeActorButtonAction
{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = sourceType;
    [self presentModalViewController:picker animated:YES];
}

- (void) changeActorPhotoButtonAction
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentModalViewController:picker animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0){
        return ;
    }else if(buttonIndex == 1){
        [self changeActorButtonAction];
    }else if(buttonIndex == 2){
        [self changeActorPhotoButtonAction];
    }
}

- (IBAction) buttonPressed:(id)sender
{
    UIAlertView*alert = [[UIAlertView alloc]initWithTitle:@""
                                                  message:@"请选择上传方式："
                                                 delegate:self
                                        cancelButtonTitle:@"取消"
                                        otherButtonTitles:@"拍照", @"相册", nil];
    [alert show];
}

- (void)saveImage:(UIImage *)image {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    BOOL result = [HTTPTools updateProfileImage:appDelegate.username Password:appDelegate.password Image:image] ;
    if(result){
        //[self.actorButton setImage:image forState:UIControlStateNormal] ;
        [self viewDidLoad] ;
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"上传头像失败！" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}


- (void) downloadImageShareCell: (NSArray *)data
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    for(int i = 0; i < appDelegate.imageCacheList.count; i++){
        Cache *cache = [appDelegate.imageCacheList objectAtIndex:i];
        if([cache.imageUrl isEqualToString:[data objectAtIndex:0]]){
            ShareCell *cell = [data objectAtIndex:1];
            cell.attactment = cache.imageCache ;
            return ;
        }
    }
    ShareCell *cell = [data objectAtIndex:1];
    cell.attactment = [UIImage imageNamed:@"blank.png"] ;
    UIImage *loadImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[data objectAtIndex:0]]]];
    cell.attactment = loadImage ;
    Cache *newCache = [[Cache alloc] init] ;
    newCache.imageCache = [loadImage copy] ;
    newCache.imageUrl = [data objectAtIndex:0] ;
    [appDelegate.imageCacheList addObject:newCache];
}

- (void) downloadImageActor: (NSString *) url
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    for(int i = 0; i < appDelegate.imageCacheList.count; i++){
        Cache *cache = [appDelegate.imageCacheList objectAtIndex:i];
        if([cache.imageUrl isEqualToString:url]){
            self.profileImage = cache.imageCache ;
            return ;
        }
    }
    self.profileImage = [UIImage imageNamed:@"blank.png"] ;
    UIImage *loadImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    self.profileImage = loadImage ;
    Cache *newCache = [[Cache alloc] init] ;
    newCache.imageCache = [loadImage copy] ;
    newCache.imageUrl = url ;
    [appDelegate.imageCacheList addObject:newCache];
}

- (void) downloadImageShareActor: (NSArray *)data
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    for(int i = 0; i < appDelegate.imageCacheList.count; i++){
        Cache *cache = [appDelegate.imageCacheList objectAtIndex:i];
        if([cache.imageUrl isEqualToString:[data objectAtIndex:0]]){
            ShareCell *cell = [data objectAtIndex:1];
            cell.avatar = cache.imageCache ;
            return ;
        }
    }
    ShareCell *cell = [data objectAtIndex:1];
    cell.avatar = [UIImage imageNamed:@"blank.png"] ;
    UIImage *loadImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[data objectAtIndex:0]]]];
    cell.avatar = loadImage ;
    Cache *newCache = [[Cache alloc] init] ;
    newCache.imageCache = [loadImage copy] ;
    newCache.imageUrl = [data objectAtIndex:0] ;
    [appDelegate.imageCacheList addObject:newCache];
}

#pragma mark –
#pragma mark Camera View Delegate Methods
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissModalViewControllerAnimated:YES];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage] ;
    [self performSelector:@selector(saveImage:)
               withObject:image
               afterDelay:0.5];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
}

- (IBAction) gotoLastPageButtonAction:(id)sender
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate] ;
    [appDelegate gotoLastPage3] ;
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
    if(_reloadSite == 1){
        [self reloadLists];
    }else{
        [self reloadOldLists];
    }
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [_footerRefreshView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
	[self.tableView reloadData];
    [self loadHeader] ;
    _footerRefreshView.frame = CGRectMake(0, self.tableView.contentSize.height, 320, 65) ;
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y < -1) {
        [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
    else if (_footerRefreshView)
    {
        [_footerRefreshView egoRefreshScrollViewDidScroll:scrollView];
    }
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (scrollView.contentOffset.y < -1) {
        _reloadSite = 1 ;
        [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
    else if (_footerRefreshView)
    {
        _reloadSite = 2 ;
        [_footerRefreshView egoRefreshScrollViewDidEndDragging:scrollView];
    }
	
}


#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:1.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	
	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}

@end
