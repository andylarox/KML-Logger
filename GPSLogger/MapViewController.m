//
//  MapViewController.m
//  GPSLogger
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "KML.h"
#import "MapViewController.h"
#import "TrackPoint.h"
// Inngerband
#import "IBCoreDataStore.h"
#import "IBFunctions.h"
#import "NSManagedObject+InnerBand.h"


@interface MapViewController ()
@property (weak) IBOutlet MKMapView *mapView;
@property (strong) UIDocumentInteractionController *interactionController;
@property (strong) CLLocationManager *locationManager;
@end

@interface MapViewController (CLLocationManagerDelegate) <CLLocationManagerDelegate>
@end

@interface MapViewController (MKMapViewDelegate) <MKMapViewDelegate>
- (void)updateOverlay;
@end

@interface MapViewController (UIActionSheetDelegate) <UIActionSheetDelegate>
- (NSString *)kmlFilePath;
- (NSString *)createKML;
- (KMLPlacemark *)placemarkWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate;
- (KMLPlacemark *)lineWithTrakPoints:(NSArray *)trackPoints;
- (void)openFile:(NSString *)filePath;
- (void)mailFile:(NSString *)filePath;
@end

@interface MapViewController (MFMailComposeViewControllerDelegate) <MFMailComposeViewControllerDelegate>
@end

@implementation MapViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (!self.track) {
        [self startLogging];
    } else {
        [self showLog];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Actions

- (IBAction)close:(id)sender
{    
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)action:(id)sender
{
    UIActionSheet *actionSheet = [UIActionSheet new];
    actionSheet.delegate = self;

    // setup actions
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open In ...", nil)];
    if ([MFMailComposeViewController canSendMail]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Mail this Log", nil)];
    }
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];

    // set cancel action position
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons -1;
    
    [actionSheet showInView:self.view];
}


#pragma mark - Private methods

- (void)startLogging
{
    // initialize map position
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.332408, -122.030490);
    MKCoordinateSpan span = MKCoordinateSpanMake(0.05f, 0.05f);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
    [self.mapView setRegion:region];

    // initialize location manager
    if (![CLLocationManager locationServicesEnabled]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:NSLocalizedString(@"Location Service not enabeld.", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
        
    } else {
        self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"Stop Logging", nil);
        
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
        
        self.track = [Track create];
        self.track.created = [NSDate date];
        [[IBCoreDataStore mainStore] save];
    }
}

- (void)showLog
{
    [self updateOverlay];
    
    //
    // Thanks for elegant code!
    // https://gist.github.com/915374
    //
    __block MKMapRect zoomRect = MKMapRectNull;
    [self.track.trackpoints enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
    {
        TrackPoint *trackPoint = (TrackPoint *)obj;
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(trackPoint.latitude.floatValue, trackPoint.longitude.floatValue);
        MKMapPoint annotationPoint = MKMapPointForCoordinate(coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }];
    [self.mapView setVisibleMapRect:zoomRect animated:NO];
}

@end


#pragma mark -
@implementation MapViewController (CLLocationManagerDelegate)

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (newLocation) {
        TrackPoint *trackpoint = [TrackPoint create];
        trackpoint.latitude = @(newLocation.coordinate.latitude);
        trackpoint.longitude = @(newLocation.coordinate.longitude);
        trackpoint.altitude = @(newLocation.altitude);
        trackpoint.created = [NSDate date];
        [self.track addTrackpointsObject:trackpoint];

        [[IBCoreDataStore mainStore] save];

        // update annotation and overlay
        [self updateOverlay];

        // set new location as center
        [self.mapView setCenterCoordinate:newLocation.coordinate animated:YES];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    
    [self.locationManager stopUpdatingLocation];
}

@end


#pragma mark -
@implementation MapViewController (MKMapViewDelegate)

- (void)updateOverlay
{
    if (!self.track) {
        return;
    }

    NSArray *trackPoints = self.track.sotredTrackPoints;

    CLLocationCoordinate2D coors[trackPoints.count];
    
    int i = 0;
    for (TrackPoint *trackPoint in trackPoints) {
        coors[i] = trackPoint.coordinate;
        i++;
    }
    
    MKPolyline *line = [MKPolyline polylineWithCoordinates:coors count:trackPoints.count];
    
    // replace overlay
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView addOverlay:line];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineView *overlayView = [[MKPolylineView alloc] initWithOverlay:overlay];
    overlayView.strokeColor = [UIColor blueColor];
    overlayView.lineWidth = 5.f;
    
    return overlayView;
}

@end


#pragma mark -
@implementation MapViewController (UIActionSheetDelegate)

- (NSString *)kmlFilePath
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.timeStyle = NSDateFormatterFullStyle;
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    
    NSString *fileName = [NSString stringWithFormat:@"log_%@.kml", dateString];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

- (NSString *)createKML
{
    // kml
    KMLRoot *kml = [KMLRoot new];
    
    // kml > document
    KMLDocument *document = [KMLDocument new];
    kml.feature = document;
    
    NSArray *sortedTrackPoints = self.track.sotredTrackPoints;
    
    // kml > document > placemark#strat
    TrackPoint *startPoint = sortedTrackPoints[0];
    KMLPlacemark *startPlacemark = [self placemarkWithName:@"Start" coordinate:startPoint.coordinate];
    [document addFeature:startPlacemark];
    
    // kml > document > placemark#line
    KMLPlacemark *line = [self lineWithTrakPoints:sortedTrackPoints];
    [document addFeature:line];
    
    // kml > document > placemark#end
    TrackPoint *endPoint = [sortedTrackPoints lastObject];
    KMLPlacemark *endPlacemark = [self placemarkWithName:@"End" coordinate:endPoint.coordinate];
    [document addFeature:endPlacemark];
    
    NSString *kmlString = kml.kml;
    
    // write kml to file
    NSError *error;
    NSString *filePath = [self kmlFilePath];
    if (![kmlString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        if (error) {
            NSLog(@"error, %@", error);
        }
        
        return nil;
    }
    
    return filePath;
}

- (KMLPlacemark *)placemarkWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate
{
    KMLPlacemark *placemarkElement = [KMLPlacemark new];
    placemarkElement.name = name;
    
    KMLPoint *pointElement = [KMLPoint new];
    placemarkElement.geometry = pointElement;
    
    KMLCoordinate *coordinateElement = [KMLCoordinate new];
    coordinateElement.latitude = coordinate.latitude;
    coordinateElement.longitude = coordinate.longitude;
    pointElement.coordinate = coordinateElement;

    return placemarkElement;
}

- (KMLPlacemark *)lineWithTrakPoints:(NSArray *)trackPoints
{
    KMLPlacemark *placemark = [KMLPlacemark new];
    placemark.name = @"Line";
    
    __block KMLLineString *lineString = [KMLLineString new];
    placemark.geometry = lineString;
    
    [trackPoints enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        TrackPoint *trackPoint = (TrackPoint *)obj;
        KMLCoordinate *coordinate = [KMLCoordinate new];
        coordinate.latitude = trackPoint.coordinate.latitude;
        coordinate.longitude = trackPoint.coordinate.longitude;
        [lineString addCoordinate:coordinate];
    }];
    
    KMLStyle *style = [KMLStyle new];
    [placemark addStyleSelector:style];

    KMLLineStyle *lineStyle = [KMLLineStyle new];
    style.lineStyle = lineStyle;
    lineStyle.width = 5;
    lineStyle.UIColor = [UIColor blueColor];
    
    return placemark;
}

- (void)openFile:(NSString *)filePath
{
    NSURL *url = [NSURL fileURLWithPath:filePath];
    self.interactionController = [UIDocumentInteractionController interactionControllerWithURL:url];

    if (![self.interactionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"No application can be found to open the file.", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)mailFile:(NSString *)filePath
{
    MFMailComposeViewController *controller = [MFMailComposeViewController new];
    controller.mailComposeDelegate = self;
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    [controller addAttachmentData:data mimeType:@"application/vnd.google-earth.kml+xml" fileName:[filePath lastPathComponent]];
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {

        NSString *filePath = [self createKML];
        
        if (filePath) {
            if (buttonIndex == 0) {
                [self openFile:filePath];
            }
            if (buttonIndex == 1) {
                [self mailFile:filePath];
            }
        }
    }
}

@end


#pragma mark -
@implementation MapViewController (MFMailComposeViewControllerDelegate)

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

