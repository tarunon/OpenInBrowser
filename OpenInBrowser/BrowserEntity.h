//
//  BrowserEntity.h
//  OpenInBrowser
//
//  Created by tarunon on 2014/09/15.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BrowserEntity : NSManagedObject

@property (nonatomic, retain) NSString * appName;
@property (nonatomic, retain) NSString * appstoreURL;
@property (nonatomic, retain) NSNumber * enable;
@property (nonatomic, retain) NSString * iconURL;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * schemeHTTP;
@property (nonatomic, retain) NSString * schemeHTTPS;

@end

//var addApp = function(n,s,i,h,l) {
//    var x = new XMLHttpRequest();
//    x.open('POST', 'https://openinbrowser.appspot.com/admin/addbrowser?appName='+encodeURIComponent(n)
//           +'&appstoreURL='+encodeURIComponent(s)
//           +'&iconURL='+encodeURIComponent(i)
//           +'&schemeHTTP='+encodeURIComponent(h)
//           +'&schemeHTTPS='+encodeURIComponent(l));
//    x.send(null);
//};
//
//addApp('Dolphin', 'https://itunes.apple.com/jp/app/dorufinburauza/id482508913', 'http://a1.mzstatic.com/us/r30/Purple4/v4/43/ff/25/43ff25a6-a581-81a7-196b-f27964e59ea6/mzl.efqynosh.175x175-75.jpg', 'dolphin', 'dolphins')