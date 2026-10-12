import rclpy
from rclpy.node import Node
from rclpy.executors import ExternalShutdownException
from example_interfaces.srv import AddTwoInts

class MyClient(Node):
    def __init__(self):
        super().__init__('my_client')
        self.cli = self.create_client(AddTwoInts, 'add_two_ints')
        while not self.cli.wait_for_service(timeout_sec=1.0):
            self.get_logger().info('Service not available, waiting again...')
        self.req = AddTwoInts.Request()

    def send_request(self, a, b):
        self.req.a = a
        self.req.b = b
        self.future = self.cli.call_async(self.req)
        self.future.add_done_callback(self.handle_response)
    def handle_response(self, future):
        try:
            response = future.result()
            self.get_logger().info(f'Result of add_two_ints: {self.req.a} + {self.req.b} = {response.sum}')
        except Exception as e:
            self.get_logger().info(f'Service call failed: {e}')

def main(args=None):
    rclpy.init(args=args)
    my_client = MyClient()

    a = 5
    b = 3
    my_client.send_request(a, b)

    while rclpy.ok():
        rclpy.spin_once(my_client)
        if my_client.future.done():
            try:
                response = my_client.future.result()
            except Exception as e:
                my_client.get_logger().info(f'Service call failed: {e}')
            else:
                my_client.get_logger().info(f'Result of add_two_ints: {a} + {b} = {response.sum}')
            break

    my_client.destroy_node()
    rclpy.shutdown()
if __name__ == '__main__':
    main()