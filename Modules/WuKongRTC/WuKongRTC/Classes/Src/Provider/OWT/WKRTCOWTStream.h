//
//  WKRTCOWTStream.h
//  WuKongRTC
//
//  Created by tt on 2022/9/17.
//

#import  "WKRTCStream.h"
#import  <OWT/OWT.h>
NS_ASSUME_NONNULL_BEGIN

@protocol WKRTCOWTStreamDelegate <OWTRemoteStreamDelegate,OWTConferenceSubscriptionDelegate,OWTP2PPublicationDelegate,OWTConferenceParticipantDelegate,OWTConferencePublicationDelegate>



@end

@interface WKRTCOWTStream : WKRTCStream

@property(nonatomic,strong,nullable) OWTConferenceSubscription *subscription;

@property(nonatomic,strong,nullable)  OWTP2PPublication *publication;
@property(nonatomic,strong,nullable)  OWTConferencePublication *conferencePublication;

@property(nonatomic,strong,nullable) OWTConferenceParticipant *participant;

@property(nonatomic,weak) id<WKRTCOWTStreamDelegate> delegate;



@end

NS_ASSUME_NONNULL_END
