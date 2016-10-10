//
//  main.m
//  AutoSendKey
//
//  Created by Bastien on 5/14/16.
//  Copyright © 2016 Bastien. All rights reserved.
//

#import <Foundation/Foundation.h>

// Function:    GetPIDForString
// Description: Finds the pid for a string. The process to search should be as precise as possible
//              in order to avoid duplicate/false return value.
pid_t GetPIDForString(NSString* process)
{
NSTask *task = [[NSTask alloc] init];
[task setLaunchPath:@"/bin/ps"];
[task setArguments:@[ @"-eo pid,comm"]];
    
NSPipe *outputPipe = [NSPipe pipe];
[task setStandardOutput:outputPipe];
[task launch];
    
NSString* pidList = [[NSString alloc] initWithData:[[outputPipe fileHandleForReading] readDataToEndOfFile]
                                          encoding:NSUTF8StringEncoding];
    
pid_t pid = -1;
for (NSString *str in [pidList componentsSeparatedByString:@"\n"])
    {
    if ([str rangeOfString:process].location != NSNotFound)
        {
        pid = [[[str componentsSeparatedByString:process] objectAtIndex:0] intValue];
        NSLog(@"PID for %@ is: %d", process, pid);
        }
    }
    
return (pid);
}

// Function:    SendKeyAfterTimeToPSN
// Description: Sends a key code to a process after a certain time. This function enters
//              an infinite loop and sends the key after each sleep duration.
void SendKeyAfterTimeToPSN(const CGKeyCode           keyCode,
                           const float               sleep,
                                 ProcessSerialNumber psn)
{
CGEventSourceRef eventSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
CGEventRef eventDown = CGEventCreateKeyboardEvent(eventSource, keyCode, YES);
CGEventRef eventUp = CGEventCreateKeyboardEvent(eventSource, keyCode, NO);
    
int Total = 0;
while (true)
    {
    Total ++;
    CGEventPostToPSN(&psn, eventDown);
    CGEventPostToPSN(&psn, eventUp);
        
    // Generate between 30 and 59
    // sleep = (arc4random() % 30) + 30;
        
    NSLog(@"Next in %f at %@. Total: %d", sleep, [[NSDate date] dateByAddingTimeInterval:sleep], Total);
        
    [NSThread sleepForTimeInterval:sleep];
    }

// This code is never reached.
// CFRelease(eventDown);
// CFRelease(eventUp);
// CFRelease(eventSource);
}

// Function: main
// Description:
int main(int   argc,
         char* argv[])
{
@autoreleasepool
    {
    // Parameters
    // CGKeyCode/key correspondance for some keys below.
    // 49 = space
    // 7 = x
    // 6 = z
    // 26 = seven
    NSString* StringToSearch = @"adventure";
    const CGKeyCode KeyToSend = 49;
    const float TimeToWait = 0.8;
        
    pid_t pid = GetPIDForString(StringToSearch);
        
    ProcessSerialNumber psn;
    OSStatus status = GetProcessForPID(pid, &psn);
    
    if (status == noErr)
        {
        SendKeyAfterTimeToPSN(KeyToSend, TimeToWait, psn);
        }
    else
        {
        NSLog(@"Error. No process for PID %i", pid);
        }
    } // @autoreleasepool
return 0;
}
