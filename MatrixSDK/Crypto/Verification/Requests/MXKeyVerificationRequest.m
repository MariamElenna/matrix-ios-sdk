/*
 Copyright 2019 The Matrix.org Foundation C.I.C

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKeyVerificationRequest_Private.h"

#import "MXDeviceVerificationManager_Private.h"


#pragma mark - Constants
NSString * const MXKeyVerificationRequestDidChangeNotification = @"MXKeyVerificationRequestDidChangeNotification";

@interface MXKeyVerificationRequest()

@property (nonatomic, readwrite) MXKeyVerificationRequestState state;

@end

@implementation MXKeyVerificationRequest

- (NSUInteger)age
{
    return [[NSDate date] timeIntervalSince1970] * 1000 - _ageLocalTs;
}


#pragma mark - SDK-Private methods -

- (instancetype)initWithRequestId:(NSString*)requestId
                               to:(NSString*)to
                           sender:(NSString*)sender
                       fromDevice:(NSString*)fromDevice
                       ageLocalTs:(uint64_t)ageLocalTs
                          manager:(MXDeviceVerificationManager*)manager
{
    self = [super init];
    if (self)
    {
        _state = MXKeyVerificationRequestStatePending;
        _requestId = requestId;
        _to = to;
        _sender = sender;
        _fromDevice = fromDevice;
        _ageLocalTs = ageLocalTs;
        _manager = manager;
    }
    return self;
}

- (void)acceptWithMethod:(NSString *)method success:(void (^)(MXDeviceVerificationTransaction * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure
{
    [self.manager acceptVerificationRequest:self method:method success:^(MXDeviceVerificationTransaction * _Nonnull transaction) {
        self.state = MXKeyVerificationRequestStateAccepted;
        [self updateState:MXKeyVerificationRequestStateAccepted notifiy:YES];
        [self.manager removePendingRequestWithRequestId:self.requestId];

        success(transaction);
    }  failure:failure];
}

- (void)cancelWithCancelCode:(MXTransactionCancelCode*)code success:(void(^)(void))success failure:(void(^)(NSError *error))failure
{
    [self.manager cancelVerificationRequest:self success:^{
        self.reasonCancelCode = code;
        
        [self updateState:MXKeyVerificationRequestStateCancelledByMe notifiy:YES];
        [self.manager removePendingRequestWithRequestId:self.requestId];
        
        if (success)
        {
            success();
        }
        
    } failure:failure];
}

- (void)updateState:(MXKeyVerificationRequestState)state notifiy:(BOOL)notify
{
    if (state == self.state)
    {
        return;
    }
    
    self.state = state;
    
    if (notify)
    {
        [self didUpdateState];
    }
}

- (void)didUpdateState
{
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MXKeyVerificationRequestDidChangeNotification object:self userInfo:nil];
    });
}

- (void)handleStart:(MXKeyVerificationStart*)startContent
{
    [self updateState:MXKeyVerificationRequestStateAccepted notifiy:YES];
    [self.manager removePendingRequestWithRequestId:self.requestId];
}

- (void)handleCancel:(MXKeyVerificationCancel *)cancelContent
{
    self.reasonCancelCode = [[MXTransactionCancelCode alloc] initWithValue:cancelContent.code
                                                             humanReadable:cancelContent.reason];
    
    [self updateState:MXKeyVerificationRequestStateCancelled notifiy:YES];
    [self.manager removePendingRequestWithRequestId:self.requestId];
}

@end
