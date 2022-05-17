/**
 * Copyright 2017 Beijing DiDi Infinity Technology and Development Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "DKMultiControlProtocol.h"
#import <DoraemonKit/DKMultiControlStreamManager.h>

static NSString *const MULTI_CONTROL_PROTOCOL_KEY = @"MULTI_CONTROL_PROTOCOL_KEY";
NS_ASSUME_NONNULL_BEGIN

@interface DKMultiControlProtocol () <NSURLSessionDataDelegate>

//@property(nonatomic, nullable, weak) NSURLSessionDataTask *urlSessionDataTask;

@property(nonatomic, nullable, weak) NSURLSession *urlSession;

@property(nonatomic, nullable, copy) NSString *dataId;

@end

NS_ASSUME_NONNULL_END

@implementation DKMultiControlProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // +[NSURLProtocol canInitWithRequest:] may be called from any thread.
    BOOL returnValue = NO;
    switch (DKMultiControlStreamManager.sharedInstance.state) {
        case DKMultiControlStreamManagerStateMaster:
            if (![NSURLProtocol propertyForKey:MULTI_CONTROL_PROTOCOL_KEY inRequest:request]) {
                NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"];
                NSString *accept = [request valueForHTTPHeaderField:@"Accept"];
                if (![contentType hasPrefix:@"multipart/form-data"] && ![accept hasPrefix:@"image/"]) {
                    returnValue = YES;
                }
            }
            break;
        case DKMultiControlStreamManagerStateSlave:
            returnValue = YES;
            break;

        default:
            break;
    }

    return returnValue;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    // +[NSURLProtocol canonicalRequestForRequest:] may be called from any thread.
    NSURLRequest *result = request;
    switch (DKMultiControlStreamManager.sharedInstance.state) {
        case DKMultiControlStreamManagerStateMaster: {
            NSMutableURLRequest *mutableUrlRequest = result.mutableCopy;
            [NSURLProtocol setProperty:@(YES) forKey:MULTI_CONTROL_PROTOCOL_KEY inRequest:mutableUrlRequest];
            result = mutableUrlRequest.copy;
        }
            break;

        default:
            break;
    }

    return result;
}

- (void)startLoading {
    NSOperationQueue *clientOperationQueue = [[NSOperationQueue alloc] init];
    clientOperationQueue.maxConcurrentOperationCount = 1;
    if ([NSURLProtocol propertyForKey:MULTI_CONTROL_PROTOCOL_KEY inRequest:self.request]) {
        self.urlSession = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:self delegateQueue:clientOperationQueue];
        [[self.urlSession dataTaskWithRequest:self.request] resume];
        NSURLRequest *urlRequest = self.request.copy;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(weakSelf) self = weakSelf;
            self.dataId = [DKMultiControlStreamManager.sharedInstance recordWithUrlRequest:urlRequest];
        });
    } else {
        // TODO(ChasonTang): Slave device send request through websocket.
    }
}

- (void)stopLoading {
    [self.urlSession invalidateAndCancel];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    if ([dataTask.response isKindOfClass:NSHTTPURLResponse.class] && self.dataId) {
        NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSHTTPURLResponse *httpUrlResponse = (NSHTTPURLResponse *) dataTask.response.copy;
        NSString *dataId = self.dataId.copy;
        dispatch_async(dispatch_get_main_queue(), ^{
            [DKMultiControlStreamManager.sharedInstance recordWithHTTPUrlResponse:httpUrlResponse dataId:dataId responseBody:responseBody];
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        NSURLCredential *urlCredential = challenge.protectionSpace.serverTrust ? [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] : nil;
        completionHandler(NSURLSessionAuthChallengeUseCredential, urlCredential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
}

@end
