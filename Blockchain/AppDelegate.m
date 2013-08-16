//
//  AppDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 15/08/2013.
//  Copyright (c) 2013 Ben Reeves. All rights reserved.
//

#import "AppDelegate.h"
#import "GBWebViewExternalLinkHandler.h"

@implementation AppDelegate


-(id)getKey:(NSString*)dictionary {
   return [[NSUserDefaults standardUserDefaults] valueForKey:[dictionary valueForKey:@"key"]];
}

-(NSString*)getApplicationDocumentsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

-(void)saveKey:(NSString*)dictionary {
    
    NSString * key = [dictionary valueForKey:@"key"];
    NSString * value = [dictionary valueForKey:@"value"];
    
    //Hack for wallet data, also save in app documents
    if ([key isEqualToString:@"payload"]) {
        NSString * documentsDirectory = [self getApplicationDocumentsPath];
                
        NSError * error = nil;
        [value writeToFile:[documentsDirectory stringByAppendingPathComponent:@"wallet.aes.json"] atomically:FALSE encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            NSLog(@"%@", error);
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)removeKey:(NSString*)dictionary {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[dictionary valueForKey:@"key"]];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)clearKeys:(NSString*)dictionary {
    NSString * appDomain = [[NSBundle mainBundle] bundleIdentifier];
    
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*)webView:(WebView*) webview didReceiveJSNotificationWithDictionary:(NSDictionary*) dictionary
{
    NSString * function = (NSString*)[dictionary objectForKey:@"function"];
    if (function != nil) {
        return [self performSelector:NSSelectorFromString(function) withObject:dictionary];
    }
    
    return nil;
}

- (void)showNotification:(NSDictionary*) dictionary {
    [self showNotification:[dictionary valueForKey:@"title"] description:[dictionary valueForKey:@"description"]];
}

- (void)showNotification:(NSString *)title description:(NSString*)description {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText =description;
    notification.soundName = NSUserNotificationDefaultSoundName;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}


-(WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request {
    return [GBWebViewExternalLinkHandler riggedWebViewWithLoadHandler:^(NSURL *url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString * resources = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Data/"];
    
    NSString * indexPath = [resources stringByAppendingPathComponent:@"index.html"];

    WebPreferences* prefs = [self.webView preferences];
    
    NSString * documentsDirectory = [self getApplicationDocumentsPath];

    [prefs performSelector:@selector(_setLocalStorageDatabasePath:) withObject:documentsDirectory];
    [prefs performSelector:@selector(setLocalStorageEnabled:) withObject:[NSNumber numberWithBool:TRUE]];
    
    [prefs setJavaScriptEnabled:YES];
    [prefs setJavaScriptCanOpenWindowsAutomatically:YES];
    
    [self.webView setJSDelegate:self];
    
    [self.webView setUIDelegate:self];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:indexPath]]];
}

@end
