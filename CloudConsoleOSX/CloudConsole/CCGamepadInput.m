//
//  CCGamepadInput.m
//  CloudConsole
//
//  Created by Will Cobb on 1/16/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  https://developer.apple.com/library/mac/referencelibrary/GettingStarted/GS_HardwareDrivers/_index.html
//  http://stackoverflow.com/questions/1326855/where-can-i-systematically-study-how-to-write-mac-os-x-device-drivers?rq=1
//  https://developer.apple.com/library/mac/documentation/DeviceDrivers/Conceptual/IOKitFundamentals/Families_Ref/Families_Ref.html
//  https://developer.apple.com/library/mac/documentation/IOKit/Reference/IOHIDManager_header_reference/#//apple_ref/c/tdef/IOHIDManagerRef
//  http://eleccelerator.com/tutorial-about-usb-hid-report-descriptors/
//  http://www.usb.org/developers/hidpage#HID Descriptor Tool
#import "CCGamepadInput.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/usb/IOUSBLib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import <QuartzCore/QuartzCore.h> //For CACurrentMediaTime

#define FOOHID_CREATE 0


unsigned char report_descriptor[] = {
    0x05, 0x01,                    // USAGE_PAGE (Generic Desktop)
    0x09, 0x05,                    // USAGE (Game Pad)
    0xa1, 0x01,                    // COLLECTION (Application)
    0xa1, 0x00,                    //   COLLECTION (Physical)
    0x05, 0x09,
    0x19, 0x01,
    0x29, 0x10,
    0x15, 0x00,
    0x25, 0x01,
    0x95, 0x10,
    0x75, 0x01,
    0x81, 0x02,
    0x05, 0x01,
    0x09, 0x30,
    0x09, 0x31,
    0x09, 0x32,
    0x09, 0x33,
    0x15, 0x81,
    0x25, 0x7f,
    0x75, 0x08,
    0x95, 0x04,
    0x81, 0x02,
    0xc0,
    0xc0
};

struct gamepad_report_t
{
    uint16_t buttons;
    int8_t left_x;
    int8_t left_y;
    int8_t right_x;
    int8_t right_y;
};

@interface CCGamepadInput () {
    io_iterator_t   iterator;
    io_service_t    service;
    
    io_connect_t connect;
    uint32_t output_count;
    uint64_t output;
    
    uint64_t input[4];
    struct gamepad_report_t gamepad;
}

@end

@implementation CCGamepadInput


- (id)init
{
    if (self = [super init]) {
        // get a reference to the IOService
        kern_return_t ret = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("it_unbit_foohid"), &iterator);
        
        if (ret != KERN_SUCCESS) {
            NSLog(@"unable to access IOService");
            return nil;
        }
        
        connect = 0;
        
        int found = 0;
        
        // Iterate till success
        while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
            ret = IOServiceOpen(service, mach_task_self(), 0, &connect);
            if (ret == KERN_SUCCESS) {
                found = 1;
                break;
            }
        }
        IOObjectRelease(iterator);
        
        if (!found) {
            NSLog(@"unable to open IOService\n");
            return nil;
        }
        
        output_count = 1;
        output = 0;
        
        // fill input args
        input[0] = (uint64_t) strdup("Cloud Console Gamecube Controller");
        input[1] = strlen( (char *)input[0]);
        input[2] = (uint64_t) report_descriptor;
        input[3] = sizeof(report_descriptor);
        
        //Need to a way to findout if the device has been created
        ret = 0;
        ret = IOConnectCallScalarMethod(connect, FOOHID_CREATE, input, 4, &output, &output_count);
        if (ret != KERN_SUCCESS) {
            printf("unable to create HID device: %d\n", ret);
            //exit(1);
        }
        
        input[2] = (uint64_t) &gamepad;
        input[3] = sizeof(struct gamepad_report_t);
        
        gamepad.buttons = 0;
        gamepad.left_y = 0;
        gamepad.right_y = 0;
        gamepad.left_x = 0;
        gamepad.right_x = 0;
        
        NSLog(@"Device Created");
    }
    return self;
}

- (void)setLeftJoyX:(int8_t) x Y:(int8_t)y
{
    gamepad.left_x = x;
    gamepad.left_y = y;
    kern_return_t ret = IOConnectCallScalarMethod(connect, 2, input, 4, &output, &output_count);
    if (ret != KERN_SUCCESS) {
        NSLog(@"Error sending left");
    }
}

- (void)setButtonState:(uint16_t)buttonState
{
    gamepad.buttons = buttonState;
    //gamepad.buttons = (uint16_t)rand();
    kern_return_t ret = IOConnectCallScalarMethod(connect, 2, input, 4, &output, &output_count);
    if (ret != KERN_SUCCESS) {
        NSLog(@"Error sending left");
    }
}

- (void)pressA
{
    gamepad.buttons = gamepad.buttons & 1;
    gamepad.buttons = gamepad.buttons & (1 << 2);
    //printf("Ret %d\n", IOConnectCallScalarMethod(connect, 2, input, 4, &output, &output_count));
    
}

//Fix later
- (int)devices
{
    CFMutableDictionaryRef matchingDict;
    io_iterator_t iter;
    kern_return_t kr;
    io_service_t device;
    
    /* set up a matching dictionary for the class */
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if (matchingDict == NULL)
    {
        return -1; // fail
    }
    
    /* Now we have a dictionary, get an iterator.*/
    kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iter);
    if (kr != KERN_SUCCESS)
    {
        return -1;
    }
    
    /* iterate */
    while ((device = IOIteratorNext(iter)))
    {
        /* do something with device, eg. check properties */
        /* ... */
        /* And free the reference taken before continuing to the next item */
        IOObjectRelease(device);
    }
    
    /* Done, release the iterator */
    IOObjectRelease(iter);
    return 0;
}

@end
