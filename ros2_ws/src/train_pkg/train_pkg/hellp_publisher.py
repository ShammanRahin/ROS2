import rclpy
from rclpy.node import Node
from rclpy.executors import ExternalShutdownException
from std_msgs.msg import String
from std_srvs.srv import Trigger

class helloPublisher(Node):
    def __init__(self):
        super().__init__('hello_publisher')
        self.publisher_ = self.create_publisher(String, 'chatter', 10)
        timer_period = .660  # seconds
        self.timer = self.create_timer(timer_period, self.timer_callback)
        self.i = 0
        self.reset_service = self.create_service(Trigger, 'reset_counter', self.reset_counter_callback)

    def timer_callback(self):
        msg = String()
        msg.data = f'Boobies! {self.i}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.i += 1
    def reset_counter_callback(self, request, response):
        old_value = self.i
        self.i = 0
        response.success = True
        response.message = f'Counter reset from {old_value} to 0.'
        self.get_logger().info('Counter reset.')
        return response
    
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