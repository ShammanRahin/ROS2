import rclpy
from rclpy.node import Node
from rclpy.executors import ExternalShutdownException
from example_interfaces.srv import AddTwoInts

class MyService(Node):
    def __init__(self):
        super().__init__('my_service')
        self.srv = self.create_service(AddTwoInts, 'add_two_ints', self.add_two_ints_callback)
        self.get_logger().info('Service "add_two_ints" is ready.')

    def add_two_ints_callback(self, request, response):
        response.sum = request.a + request.b
        self.get_logger().info(f'Received request: a={request.a}, b={request.b}, sum={response.sum}')
        return response
def main(args=None):
    rclpy.init(args=args)
    my_service = MyService()

    try:
        rclpy.spin(my_service)
    except ExternalShutdownException:
        pass
    finally:
        my_service.destroy_node()
        rclpy.shutdown()
if __name__ == '__main__':  
    main()
    