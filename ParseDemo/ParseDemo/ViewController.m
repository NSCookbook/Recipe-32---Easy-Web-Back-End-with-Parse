//
//  ViewController.m
//  ParseDemo
//
//  Created by joseph hoffman on 1/20/14.
//  Copyright (c) 2014 NSCookbook. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>
#import <MapKit/MapKit.h>


@interface ViewController () <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) PFLogInViewController *login;
@property (strong, nonatomic) PFUser *user;


@property (weak, nonatomic) IBOutlet UILabel *userFullNameLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *userFullNameInput;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if([PFUser currentUser])
    {
    self.user = [PFUser currentUser];
        
        [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
            NSLog(@"User is currently at %f, %f", geoPoint.latitude, geoPoint.longitude);
            

            [self.user setObject:geoPoint forKey:@"currentLocation"];
            [self.user saveInBackground];
            [self.mapView setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude),MKCoordinateSpanMake(0.01, 0.01))];
            
            [self refreshMap:nil];
        }];
        
        self.userFullNameLabel.text = [self.user objectForKey:@"userFullName"];
        
    }
    
    self.userFullNameInput.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self presentLoginViewController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - action methods
- (IBAction)refreshMap:(id)sender
{
    
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
    PFQuery *query = [PFUser query];
    
    //query parse database for user
    [query whereKey:@"currentLocation" nearGeoPoint:geoPoint withinMiles:10.0f];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if(error)
         {
             NSLog(@"%@",error);
         }
         for (id object in objects)
         {
             
             MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
             annotation.title = [object objectForKey:@"userFullName"];
             PFGeoPoint *geoPoint= [object objectForKey:@"currentLocation"];
             annotation.coordinate = CLLocationCoordinate2DMake(geoPoint.latitude,geoPoint.longitude);
             
             [self.mapView addAnnotation:annotation];
            
         }
         

         
     }];
    
}
- (IBAction)updateUserFullName:(id)sender
{
    if(self.user)
    {
        
        [self.user setObject:self.userFullNameInput.text forKey:@"userFullName"];
        
        self.userFullNameLabel.text = self.userFullNameInput.text;
        
        [self.user saveInBackground];
    
    }
}

- (IBAction)logout:(id)sender
{
    [PFUser logOut];
    [self presentLoginViewController];
}

# pragma mark - helper methods
- (void)presentLoginViewController
{
    //Present login view controller if user not logged in
    if(![PFUser currentUser])
    {
        self.login = [[PFLogInViewController alloc] init];
        self.login.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsSignUpButton | PFLogInFieldsLogInButton;
        
        self.login.delegate = self;
        self.login.signUpController.delegate = self;
        
        [self presentViewController:self.login animated:YES completion:nil];
        
    }
}

# pragma mark - delegate methods

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [textField resignFirstResponder];
    return NO;
}






@end
