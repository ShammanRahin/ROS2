import rclpy
from rclpy.node import Node
from rclpy.executors import ExternalShutdownException
from std_msgs.msg import String

class helloPublisher(Node):
    def __init__(self):
        super().__init__('hello_publisher')
        self.publisher_ = self.create_publisher(String, 'chatter', 10)
        timer_period = .660  # seconds
        self.timer = self.create_timer(timer_period, self.timer_callback)
        self.i = 0

    def timer_callback(self):
        msg = String()
        msg.data = f'Boobies! {self.i}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.i += 1
def main(args=None):
    rclpy.init(args=args)

    hello_publisher = helloPublisher()

    try:
        rclpy.spin(hello_publisher)
    except (KeyboardInterrupt, ExternalShutdownException):
        pass
    finally:
        hello_publisher.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()
if __name__ == '__main__':
    main()