//
//  ViewController.m
//  QuhwaMqttSmartHome
//
//  Created by Tisoon on 2019/12/16.
//  Copyright © 2019 Tisoon. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) MQTTSessionManager *manager;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UITextField *message;
@property (weak, nonatomic) IBOutlet UIButton *connect;
@property (weak, nonatomic) IBOutlet UIButton *disconnect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
     * MQTTClient: create an instance of MQTTSessionManager once and connect
     * will is set to let the broker indicate to other subscribers if the connection is lost
     */
    if (!self.manager) {
        NSString *clientId = [UIDevice currentDevice].identifierForVendor.UUIDString;
        MQTTSessionManager *sessionManager = [[MQTTSessionManager alloc] init];
        [sessionManager connectTo:@"192.156.1.10"
                             port:1883
                              tls:false
                        keepalive:60  //心跳间隔不得大于120s
                            clean:false
                             auth:true
                             user:@"admin"
                             pass:@"123456"
                             will:false
                        willTopic:nil
                          willMsg: nil
                          willQos:MQTTQosLevelAtLeastOnce
                   willRetainFlag:false
                     withClientId:clientId];
        
        sessionManager.delegate = self;
        self.manager = sessionManager;
    } else {
        [self.manager connectToLast];
    }
    
    /*
     * MQTTCLient: observe the MQTTSessionManager's state to display the connection status
     */
    
    [self.manager addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:nil];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
#pragma mark - 监听连接状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    switch (self.manager.state) {
        case MQTTSessionManagerStateClosed:
            self.status.text = @"连接已经关闭";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            
            break;
        case MQTTSessionManagerStateClosing:
            self.status.text = @"连接正在关闭";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateConnected:
            self.status.text = [NSString stringWithFormat:@"connected as %@",
                                [UIDevice currentDevice].name];
            self.disconnect.enabled = true;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateConnecting:
            self.status.text = @"正在连接中";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateError:
            self.status.text = @"error";
            self.disconnect.enabled = false;
            self.connect.enabled = false;
            break;
        case MQTTSessionManagerStateStarting:
        default:
            self.status.text = @"开始连接";
            self.disconnect.enabled = false;
            self.connect.enabled = true;
            break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)connect:(id)sender {
    /*
     * MQTTClient: connect to same broker again
     */
    
    [self.manager connectToLast];
}

- (IBAction)disconnect:(id)sender {
    /*
     * MQTTClient: send goodby message and gracefully disconnect
     */
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [self.manager disconnect];
}
#pragma mark - 订阅主题
- (IBAction)dingyue:(id)sender {
    //   self.manager.subscriptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:MQTTQosLevelAtLeastOnce] forKey:@"quhwa"];
    self.manager.subscriptions = @{@"mqtt":[NSNumber numberWithInt:MQTTQosLevelAtLeastOnce],
                                   @"test1":[NSNumber numberWithInt:MQTTQosLevelAtLeastOnce],
                                   @"test2":[NSNumber numberWithInt:MQTTQosLevelAtLeastOnce],
                                   @"test3":[NSNumber numberWithInt:MQTTQosLevelAtLeastOnce],
                                   };
}
#pragma mark - 发送消息
- (IBAction)send:(id)sender {
    /*
     * MQTTClient: send data to broker
     */
    
    //发送消息 返回值msgid大于0代表发送成功
    UInt16 msgid = [self.manager sendData:[self.message.text dataUsingEncoding:NSUTF8StringEncoding]
                                    topic:@"clh"
                                      qos:MQTTQosLevelAtLeastOnce
                                   retain:FALSE];
    if (msgid > 0) {
        NSLog(@"================================消息发送成功");
    }
}
#pragma mark - MQTTSessionManagerDelegate
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    /*
     * MQTTClient: process received message
     */
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"============================%@",dataString);
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"接收消息" message:dataString preferredStyle:UIAlertControllerStyleActionSheet];
//    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
//    [alert addAction:action];
//    [self presentViewController:alert animated:YES completion:nil];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = dataString;
    [hud hide:YES afterDelay:2.0];
    
}


@end
