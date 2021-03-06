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


#import "MXKeyVerificationByDMRequest.h"

#import "MXKeyVerificationRequest_Private.h"
#import "MXKeyVerificationRequestJSONModel.h"

#import "MXEvent.h"


@implementation MXKeyVerificationByDMRequest

- (instancetype)initWithEvent:(MXEvent*)event andManager:(MXDeviceVerificationManager*)manager
{
    // Check verification by DM request format
    MXKeyVerificationRequestJSONModel *request;
    MXJSONModelSetMXJSONModel(request, MXKeyVerificationRequestJSONModel.class, event.content);

    if (!request)
    {
        return nil;
    }

    // Use the event id as identifier
    self = [self initWithRequestId:event.eventId
                                to:request.to
                            sender:event.sender
                        fromDevice:request.fromDevice
                        ageLocalTs:event.ageLocalTs
                           manager:manager];
    if (self)
    {
        _roomId = event.roomId;
        _eventId = event.eventId;
    }
    return self;
}

@end
