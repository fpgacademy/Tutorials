#include <ros/ros.h>
#include <std_msgs/UInt16.h>
extern "C" {
#include <intelfpgaup/LEDR.h>
}
void switchCallback(const std_msgs::UInt16::ConstPtr& msg){LEDR_set(msg->data);}
int main(int argc, char** argv){
ros::init(argc, argv, "subscriber");
ros::NodeHandle nh;
ros::Subscriber sub = nh.subscribe<std_msgs::UInt16>("published_data", 100, switchCallback);
ros::Rate loop_rate(10);
if(LEDR_open() != 1) return -1;
while(ros::ok()){
ros::spinOnce();
loop_rate.sleep();
}
LEDR_close();
}