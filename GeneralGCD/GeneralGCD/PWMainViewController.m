//
//  PWMainViewController.m
//  GeneralGCD
//
//  Created by WANG on 6/11/15.
//  Copyright (c) 2015 WANG. All rights reserved.
//

#import "PWMainViewController.h"

@interface PWMainViewController ()
{
    NSString* newString;
}

@end

@implementation PWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)gcdBtnClicked:(id)sender {
    __weak __typeof(self) weakSelf = self;
    
    double delayInSeconds = 0.32f;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, dispatch_walltime(DISPATCH_TIME_NOW, 0), (unsigned)(delayInSeconds* NSEC_PER_SEC), 0);
    
    dispatch_source_set_event_handler(timer, ^{
        [weakSelf handleEvent];
    });
    dispatch_resume(timer);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf handleEvent];
    });
}

- (void)handleEvent{
    NSLog(@"GCD处理");
    self.titleLabel.text = @"GCD处理";
    NSLog(@"reutn=%f",roundf(-3.5));//log 4
}
- (IBAction)onTransform:(id)sender {
    
    //启动一个新异步县城去下载图片，然后主线程更新图片
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL* url = [NSURL URLWithString:@"http://avatar.csdn.net/2/C/D/1_totogo2010.jpg"];
        NSData* data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:nil];
        UIImage* img = [UIImage imageWithData:data];
        
        if (img) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = img;
            });
        }
    });
}
- (IBAction)onAnimation:(id)sender {
    self.titleLabel.text = @"管道GCD";
    //管道下载，可以分多个任务下载，多个任务下载完成后进行回调方法调用
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, queue, ^{
        NSURL *url = [NSURL URLWithString:@"https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=38925315,2564619234&fm=116&gp=0.jpg"];
        NSData* data = [NSData dataWithContentsOfURL:url];
        UIImage* image = [UIImage imageWithData:data];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    });
    
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:2.0f];
        NSURL *url = [NSURL URLWithString:@"https://ss2.bdstatic.com/70cFvnSh_Q1YnxGkpoWK1HF6hhy/it/u=2199567350,2071237530&fm=116&gp=0.jpg"];
        NSData* data = [NSData dataWithContentsOfURL:url];
        UIImage* image = [UIImage imageWithData:data];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = image;
            });
        }
    });
    
    dispatch_group_async(group, queue, ^{
        
        NSURL* url = [NSURL URLWithString:@"http://bcs.91.com/rbreszy/msoft/91assistant_v3.2.8_2.ipa"];
        NSData* data = [NSData dataWithContentsOfURL:url];
        NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSError* error;
        NSString* title = @"错误";
        [data writeToFile:[path stringByAppendingPathComponent:@"91.ipa"]options:NSDataWritingAtomic error:&error];
        if (error) {
            NSLog(@"错误=%@",error);
            return ;
        }else if(data){
            title = @"下载完成";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.titleLabel.text = title;
        });
        
    });
    
    dispatch_group_notify(group, queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            self.titleLabel.text = @"所有更新完成";
        });
    });
    
}
- (IBAction)onBarrier:(id)sender {
    self.titleLabel.text = @"GCD Barrier";
    //dispatch_barrier_async()在它前面的任务结束后它才会执行，它后面的任务也得等他结束后才会执行虽然他们的执行时间已经过去了
    dispatch_queue_t mueue = dispatch_get_main_queue();
    dispatch_queue_t gqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    __block __typeof(self) weakSelf = self;
    dispatch_async(mueue, ^{
        [NSThread sleepForTimeInterval:1.0f];
        [weakSelf modifyTitle:@"第一个mqueue"];
    });
    
    dispatch_async(gqueue, ^{
        [NSThread sleepForTimeInterval:1.0f];
        [weakSelf modifyTitle:@"第一个gqueue"];
    });
    dispatch_barrier_async(mueue, ^{
        [NSThread sleepForTimeInterval:3.0f];
        [self modifyTitle:@"第一个mainQueue===barrier"];
    });
    
    self.titleLabel.text = @"第一个正常改title";
    
    dispatch_barrier_async(mueue, ^{
        [NSThread sleepForTimeInterval:2];
        [self modifyTitle:@"第二个mainQueue===barrier"];
    });
    
    dispatch_barrier_async(gqueue, ^{
        [NSThread sleepForTimeInterval:2];
        [self modifyTitle:@"第一个GQueue++++barrier"];
    });
    
    dispatch_async(gqueue, ^{
        [NSThread sleepForTimeInterval:3.0f];
        [weakSelf modifyTitle:@"第二个gqueue"];
    });
    
    dispatch_async(mueue, ^{
        [NSThread sleepForTimeInterval:2.0f];
        [weakSelf modifyTitle:@"第二个mqueue"];
    });
    
    //结果如下，同样的sleep时间下可见global queue 优先级高于main queue，同样queue就严格按照顺序走
    //main_queue不能跳过barrier的执行顺序等待，而global_queue可以跳过main_queue的
    //结论，同级queue不能跳过自身的，缺可以优先于比之优先级低的queue,前提是执行整个代码片段的时间也一定要等于或短于低等级的
    /**
     2015-06-12 17:27:08.385 GeneralGCD[3685:1606539] 标题=第一个gqueue
     2015-06-12 17:27:08.386 GeneralGCD[3685:1606539] 标题=第一个mqueue
     2015-06-12 17:27:08.386 GeneralGCD[3685:1606539] 标题=第一个GQueue++++barrier
     2015-06-12 17:27:08.386 GeneralGCD[3685:1606539] 标题=第二个gqueue
     2015-06-12 17:27:08.386 GeneralGCD[3685:1606539] 标题=第一个mainQueue===barrier
     2015-06-12 17:27:08.387 GeneralGCD[3685:1606539] 标题=第二个mainQueue===barrier
     2015-06-12 17:27:08.387 GeneralGCD[3685:1606539] 标题=第二个mqueue

     
     */
}
- (IBAction)onApply:(id)sender {
    //执行某个代码片段n次 apply在main_queue会卡死, apply 输出的index不一样 ，global_queue依然高于main_queue,global循环问了才到main
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"after --main");
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"after --global");
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_apply(4, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
            NSLog(@"main =%zu",index);
        });
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_apply(4, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
            NSLog(@"global--main =%zu",index);
        });
    });
    
    
    dispatch_apply(4, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
        NSLog(@"global=%zu",index);
    });
    
}

- (void)modifyTitle:(NSString*)title{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.titleLabel.text = title;
        NSLog(@"标题=%@",title);
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
