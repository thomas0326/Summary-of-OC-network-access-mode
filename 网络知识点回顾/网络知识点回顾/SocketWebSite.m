//
//  SocketWebSite.m
//  网络知识点回顾
//
//  Created by Sariel's Mac on 15-5-6.
//  Copyright (c) 2015年 Sariel. All rights reserved.
//

#import "SocketWebSite.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface SocketWebSite ()

// 客户端 socket
@property (nonatomic, assign) int clientSocket;

@end

@implementation SocketWebSite

/**
 --- 请求头 ---
 1> 请求行
 GET / HTTP/1.1
 
 GET        表示从服务器"拿"数据
 /          访问服务器的根目录
 HTTP/1.1   HTTP的协议以及版本
 
 2> 请求头
 Host:              要访问的主机
 User-Agent:        用户代理，告诉服务器客户端的类型
 Accept:            告诉服务器客户端支持的数据格式
 Accept-Language:   告诉服务器客户端支持的语言
 Accept-Encoding:   告诉服务器客户端支持的解压缩类型
 
 HTTP请求本身的格式，是字符串格式的，最末一行，以 \n\n 结束，表示所有请求的内容发送完毕，服务器可以处理！
 
 提示：key 值是 HTTP 协议定义的，不能随意更改！
 
 --- 响应 ---
 1> 状态行
 
 HTTP/1.1 200 OK
 
 HTTP/1.1   HTTP的协议以及版本
 200        状态码(404)
 2XX     成功
 4XX     客户端错误
 5XX     服务器错误
 
 2> 响应头，服务器告诉客户端的一些信息
 提示：响应的信息，通常在开发“下载”功能时，才会使用，平时用不着
 
 Date:      响应日期
 Server:    服务器的信息
 
 // 文件长度
 Content-Length: 24
 
 3> 数据实体，从服务器返回的二进制数据！
 println("hello world!");
 
 */

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    // http 端口是 80
    if ([self connectToHost:@"127.0.0.1" port:80]) {
        NSLog(@"连接成功");
    }
    
    // 发送消息给 web 服务器
    // 建立请求字符串
    NSString *request = @"GET /ios.m HTTP/1.1\n"
    "Host: localhost\n"
    "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:36.0) Gecko/20100101 Firefox/36.0\n"
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n"
    "Accept-Language: zh-CN,zh;q=0.8,en-US;q=0.5,en;q=0.3\n"
    "Accept-Encoding: gzip, deflate\n\n";
    
    NSLog(@"%@", [self sendAndRecv:request]);
    
    return self;
}

#pragma mark - 通过webView展示百度返回的手机百度页面。
- (void)connectWithBaidu{
    // http 端口是 80
    if ([self connectToHost:@"61.135.169.125" port:80]) {
        NSLog(@"连接成功");
    }
    
    // 发送消息给 web 服务器
    // 建立请求字符串
    NSString *request = @"GET / HTTP/1.1\n"
    "Host: www.baidu.com\n"
    "User-Agent: iPhone AppleWebKit\n\n";
    
    // 对结果的处理
    NSString *result = [self sendAndRecv:request];
    // 找 \r\n 的出现的位置
    NSRange range = [result rangeOfString:@"\r\n\r\n"];
    
    // 判断是否找到
    if (range.location == NSNotFound) {
        NSLog(@"html 错误");
        return;
    }
    
    NSString *html = [result substringFromIndex:range.location];
    
    NSLog(@"%@", html);
    //使用webView显示手机百度页面。
//    [self.myWebView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://www.baidu.com"]];
}

#pragma mark - socket方法。
- (BOOL)connectToHost:(NSString *)host port:(int)port {
    // 1. socket
    /**
     参数
     
     domain:    协议域，AF_INET
     type:      Socket 类型，SOCK_STREAM(流 TCP)/SOCK_DGRAM(报文，提示：
     在有些公司的程序员给服务器发送数据，会说：发送报文)
     protocol:  IPPROTO_TCP，提示：如果输入0，会根据第二个参数，自动选择协议
     
     返回值
     socket     如果>0，就是正确的
     */
    self.clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    NSLog(@"%d", self.clientSocket);
    
    // 2. 连接到另外一台计算机
    /**
     参数
     1> 客户端socket
     2> 指向数据结构sockaddr的指针，其中包括目的端口和IP地址
     C 语言中没有对象，实现都是通过结构体来实现的
     3> 结构体数据长度
     返回值
     0 成功/其他 错误代号，很多C语言的程序都会如此设计，原因：成功只有一个，失败会有很多种！
     C 语言中，通常是非零即真
     */
    struct sockaddr_in serverAddress;
    // 1> 地址 inet_addr 可以将 ip 地址转换成整数
    // 提示：在网络上的使用的很多数据，需要做字节翻转
    serverAddress.sin_addr.s_addr = inet_addr(host.UTF8String);
    // 2> 端口 htons 可以将端口转换成整数
    // 端口号同样要做字节翻转
    serverAddress.sin_port = htons(port);
    // 3> 协议
    serverAddress.sin_family = AF_INET;
    
    // 在 C 语言中，通常传递结构体的指针同时，会传递结构体的尺寸
    int result = connect(self.clientSocket, (const struct sockaddr *)&serverAddress, sizeof(serverAddress));
    
    return (result == 0);
}

/**
 *  发送&接收消息
 */
- (NSString *)sendAndRecv:(NSString *)msg {
    // 3. 发送数据给服务器
    /**
     参数
     1> 客户端socket
     2> 发送内容地址
     3> 发送内容长度
     4> 发送方式标志，一般为0
     返回值
     如果成功，则返回发送的字节数，失败则返回SOCKET_ERROR
     
     提示：在很多C语言框架中，会将基本数据类型进行封装，使用的时候，便于后续框架的调整
     */
    // 在 UTF8 编码中，一个中文对应 3 个字节
    ssize_t sendLen = send(self.clientSocket, msg.UTF8String, strlen(msg.UTF8String), 0);
    NSLog(@"%ld %tu %ld", sendLen, msg.length, strlen(msg.UTF8String));
    
    // 4. 从服务器接收数据
    /**
     参数
     1. 客户端socket
     2. 接收内容的空间
     3. 接收内容空间的长度
     4. 标记，如果是0，表示阻塞式，一直等到服务器的响应
     返回值
     接收到数据的长度
     */
    // 定义一个空的数组，准备接收数据
    uint8_t buffer[1024];
    
    // 在 C 语言中，数组的名字，是指向数组第一个元素的指针
    ssize_t recvLen = recv(self.clientSocket, buffer, sizeof(buffer), 0);
    
    NSLog(@"接收到 %ld 字节", recvLen);
    
    // 1> 取二进制数据
    NSData *data = [NSData dataWithBytes:buffer length:recvLen];
    // 2> 转换成字符串
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return str;
}

/**
 *  断开连接
 */
- (void)disconnect {
    // 5. 关闭连接
    close(self.clientSocket);
}

@end
