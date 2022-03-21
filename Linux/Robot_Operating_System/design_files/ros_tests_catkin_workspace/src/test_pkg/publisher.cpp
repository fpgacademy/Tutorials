#include <ros/ros.h>
#include <std_msgs/UInt16.h>
extern "C" {
#include <intelfpgaup/SW.h>
}
void publishData(ros::Publisher pub){
std_msgs::UInt16 msg;
int data;
if(SW_read(&data)){
msg.data=data;
pub.publish(msg);
}}
int main(int argc, char** argv){
ros::init(argc, argv, "publisher");
ros::NodeHandle nh;
ros::Publisher pub = nh.advertise<std_msgs::UInt16>("published_data", 100);
ros::Rate loop_rate(10);
if(SW_open() != 1) return -1;
while(ros::ok()){
publishData(pub);
loop_rate.sleep();
}
SW_close();
}