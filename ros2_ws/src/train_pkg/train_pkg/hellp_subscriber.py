import rclpy
from rclpy.node import Node
from rclpy.executors import ExternalShutdownException
from example_interfaces.msg import String

class helloSubscriber(Node):
    def __init__(self):
        super().__init__('hello_subscriber')
        self.subscription = self.create_subscription(
            String,
            'chatter',
            self.listener_callback,
            10)
        self.subscription  # prevent unused variable warning

    def listener_callback(self, msg):
        self.get_logger().info(f'I heard: "{msg.data}"')
def main(args=None):
    rclpy.init(args=args)

    hello_subscriber = helloSubscriber()

    try:
        rclpy.spin(hello_subscriber)
    except (KeyboardInterrupt, ExternalShutdownException):
        pass
    finally:
        hello_subscriber.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()
if __name__ == '__main__':
    main()  