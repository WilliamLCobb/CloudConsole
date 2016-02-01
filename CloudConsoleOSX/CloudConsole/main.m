//
//  main.m
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}

//
////http://eleccelerator.com/tutorial-about-usb-hid-report-descriptors/
//// http://www.usb.org/developers/hidpage#HID Descriptor Tool
//#include <IOKit/IOKitLib.h>
//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
//
//#define FOOHID_CREATE 0
////
////unsigned char report_descriptor[] = {
////    0x05, 0x01,                    // USAGE_PAGE (Generic Desktop)
////    0x09, 0x02,                    // USAGE (Mouse)
////    0xa1, 0x01,                    // COLLECTION (Application)
////    0x09, 0x01,                    //   USAGE (Pointer)
////    0xa1, 0x00,                    //   COLLECTION (Physical)
////    0x05, 0x09,                    //     USAGE_PAGE (Button)
////    0x19, 0x01,                    //     USAGE_MINIMUM (Button 1)
////    0x29, 0x03,                    //     USAGE_MAXIMUM (Button 3)
////    0x15, 0x00,                    //     LOGICAL_MINIMUM (0)
////    0x25, 0x01,                    //     LOGICAL_MAXIMUM (1)
////    0x95, 0x03,                    //     REPORT_COUNT (3)
////    0x75, 0x01,                    //     REPORT_SIZE (1)
////    0x81, 0x02,                    //     INPUT (Data,Var,Abs)
////    0x95, 0x01,                    //     REPORT_COUNT (1)
////    0x75, 0x05,                    //     REPORT_SIZE (5)
////    0x81, 0x03,                    //     INPUT (Cnst,Var,Abs)
////    0x05, 0x01,                    //     USAGE_PAGE (Generic Desktop)
////    0x09, 0x30,                    //     USAGE (X)
////    0x09, 0x31,                    //     USAGE (Y)
////    0x15, 0x81,                    //     LOGICAL_MINIMUM (-127)
////    0x25, 0x7f,                    //     LOGICAL_MAXIMUM (127)
////    0x75, 0x08,                    //     REPORT_SIZE (8)
////    0x95, 0x02,                    //     REPORT_COUNT (2)
////    0x81, 0x06,                    //     INPUT (Data,Var,Rel)
////    0xc0,                          //   END_COLLECTION
////    0xc0                           // END_COLLECTION
////};
////
////struct mouse_report_t {
////    uint8_t buttons;
////    int8_t x;
////    int8_t y;
////};
//
//
//
//
////USAGE_PAGE (Generic Desktop)
////USAGE (Game Pad)
////COLLECTION (Application)
////COLLECTION (Physical)
////USAGE_PAGE (Button)
////USAGE_MINIMUM (Button 1)
////USAGE_MAXIMUM (Button 16)
////LOGICAL_MINIMUM (0)
////LOGICAL_MAXIMUM (1)
////REPORT_COUNT (16)
////REPORT_SIZE (1)
////INPUT (Data,Var,Abs)
////USAGE_PAGE (Generic Desktop)
////USAGE (X)
////USAGE (Y)
////USAGE (Z)
////USAGE (Rx)
////LOGICAL_MINIMUM (-127)
////LOGICAL_MAXIMUM (127)
////REPORT_SIZE (8)
////REPORT_COUNT (4)
////INPUT (Data,Var,Abs)
////END COLLECTION
////END COLLECTION
//
//unsigned char report_descriptor[] = {
//    0x05, 0x01,                    // USAGE_PAGE (Generic Desktop)
//    0x09, 0x05,                    // USAGE (Game Pad) originally 0x09, 0x05
//    0xa1, 0x01,                    // COLLECTION (Application)
//    0xa1, 0x00,                    //   COLLECTION (Physical)
//    0x05, 0x09,
//    0x19, 0x01,
//    0x29, 0x10,
//    0x15, 0x00,
//    0x25, 0x01,
//    0x95, 0x10,
//    0x75, 0x01,
//    0x91, 0x02,
//    0x05, 0x01,
//    0x09, 0x30,
//    0x09, 0x31,
//    0x09, 0x32,
//    0x09, 0x33,
//    0x15, 0x81,
//    0x25, 0x7f,
//    0x75, 0x08,
//    0x95, 0x04,
//    0x81, 0x02,
//    0xc0,
//    0xc0
//};
//
//struct multiplayer_gamepad_report_t
//{
//    uint8_t report_id;
//    uint16_t buttons;
//    int8_t left_x;
//    int8_t left_y;
//    int8_t right_x;
//    int8_t right_y;
//};
//
//int main() {
//    
//    io_iterator_t   iterator;
//    io_service_t    service;
//    
//    // get a reference to the IOService
//    kern_return_t ret = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("it_unbit_foohid"), &iterator);
//    
//    if (ret != KERN_SUCCESS) {
//        printf("unable to access IOService\n");
//        exit(1);
//    }
//    
//    io_connect_t connect = 0;
//    
//    int found = 0;
//    
//    // Iterate till success
//    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
//        ret = IOServiceOpen(service, mach_task_self(), 0, &connect);
//        if (ret == KERN_SUCCESS) {
//            found = 1;
//            break;
//        }
//    }
//    IOObjectRelease(iterator);
//    
//    if (!found) {
//        printf("unable to open IOService\n");
//        exit(1);
//    }
//    
//    uint32_t output_count = 1;
//    uint64_t output = 0;
//    
//    // fill input args
//    uint64_t input[4];
//    input[0] = (uint64_t) strdup("Cloud Console GamePaddp");
//    input[1] = strlen( (char *)input[0]);
//    input[2] = (uint64_t) report_descriptor;
//    input[3] = sizeof(report_descriptor);
//    
//    //Need to a way to findout if the device has been created
//    ret = 0;
//    //ret = IOConnectCallScalarMethod(connect, FOOHID_CREATE, input, 4, &output, &output_count);
//    if (ret != KERN_SUCCESS) {
//        printf("unable to create HID device: %d\n", ret);
//        exit(1);
//    }
//    
//    // update input args to pass hid message
////    struct mouse_report_t mouse;
////    input[2] = (uint64_t) &mouse;
////    input[3] = sizeof(struct mouse_report_t);
//    struct multiplayer_gamepad_report_t gamepad;
//    input[2] = (uint64_t) &gamepad;
//    input[3] = sizeof(struct multiplayer_gamepad_report_t);
//    printf("Device Created");
//    for(;;) {
//        //mouse.buttons = 0;
//        //mouse.x = rand();
//        //mouse.y = rand();
//        gamepad.report_id = 1;
//        gamepad.left_x = rand();
//        gamepad.right_x = 1;
//        gamepad.buttons = rand();
//        
//        // ignore return value, just for testing
//        printf("%d\n", IOConnectCallScalarMethod(connect, 2, input, 4, &output, &output_count));
//        usleep(2000000);
//    }
//}