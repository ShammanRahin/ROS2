#include "rclcpp/rclcpp.hpp"
#include "example_interfaces/msg/string.hpp"  

class HelloSubscriber : public rclcpp::Node
{
public:
    HelloSubscriber() : Node("hello_subscriber")
    {
        subscription_ = this->create_subscription<example_interfaces::msg::String>(
            "hello_topic", 10, std::bind(&HelloSubscriber::topic_callback, this, std::placeholders::_1));
    }
private:

    void topic_callback(const example_interfaces::msg::String::SharedPtr msg) const
    {
        RCLCPP_INFO(this->get_logger(), "I heard: '%s'", msg->data.c_str());
    }
    rclcpp::Subscription<example_interfaces::msg::String>::SharedPtr subscription_;
    rclcpp::TimerBase::SharedPtr timer_;
};
int main(int argc, char *argv[])
{
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<HelloSubscriber>());
    rclcpp::shutdown();
    return 0;
}