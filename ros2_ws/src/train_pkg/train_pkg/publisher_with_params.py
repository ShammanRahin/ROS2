import rclpy
from rclpy.node import Node
from rclpy.executors import ExternalShutdownException
from std_msgs.msg import String
from std_srvs.srv import Trigger

class publisherWithParams(Node):
    def __init__(self):
        super().__init__('publisher_with_params')
        self.declare_parameter('message_prefix', 'Hello')
        self.declare_parameter('publish_frequency', 1.0)
        self._message=self.get_parameter('message_prefix').get_parameter_value().string_value
        self._timer_period=1.0/self.get_parameter('publish_frequency').get_parameter_value().double_value

        self.publisher_ = self.create_publisher(String, 'chatter', 10)
        timer_period = self._timer_period  # seconds
        self.timer = self.create_timer(timer_period, self.timer_callback)
        self.i = 0
        self.reset_service = self.create_service(Trigger, 'reset_counter', self.reset_counter_callback)
        self.add_post_set_parameters_callback(self.on_params_changed) 

    def timer_callback(self):
        msg = String()
        msg.data = f'{self._message} {self.i}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.i += 1


    def on_params_changed(self, params):
        for p in params:
            if p.name == 'message_prefix':
                self._message = p.value
            elif p.name == 'publish_frequency':
                self._timer_period = 1.0 / p.value
                self.timer.cancel()                      # a timer can't change its period,
                self.timer = self.create_timer(          # so swap in a new one
                    self._timer_period, self.timer_callback)
            self.get_logger().info(f'Set {p.name} to {p.value}')


    def reset_counter_callback(self, request, response):
        old_value = self.i
        self.i = 0
        response.success = True
        response.message = f'Counter reset from {old_value} to 0.'
        self.get_logger().info('Counter reset.')
        return response
    
def main(args=None):
    rclpy.init(args=args)

    publisher_with_params = publisherWithParams()

    try:
        rclpy.spin(publisher_with_params)
    except (KeyboardInterrupt, ExternalShutdownException):
        pass
    finally:
        publisher_with_params.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()
if __name__ == '__main__':
    main()