#include "rclcpp/rclcpp.hpp"
#include "example_interfaces/msg/string.hpp"  

class HelloPublisher : public rclcpp::Node
{
public:
    HelloPublisher() : Node("hello_publisher")
    {
        publisher_ = this->create_publisher<example_interfaces::msg::String>("hello_topic", 10);
        timer_ = this->create_wall_timer(
            std::chrono::milliseconds(200),
            std::bind(&HelloPublisher::publish_message, this));
            counter_ = 0;
    }
private:
    void publish_message()
    {
        auto message = example_interfaces::msg::String();
        message.data = "Boobies!"+ std::to_string(counter_);
        RCLCPP_INFO(this->get_logger(), "Publishing: '%s'", message.data.c_str());
        publisher_->publish(message);
        counter_++;
    }

    rclcpp::Publisher<example_interfaces::msg::String>::SharedPtr publisher_;
    rclcpp::TimerBase::SharedPtr timer_;
    size_t counter_;
};

int main(int argc, char *argv[])
{
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<HelloPublisher>());
    rclcpp::shutdown();
    return 0;
}