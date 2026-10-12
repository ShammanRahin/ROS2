from setuptools import find_packages, setup

package_name = 'train_pkg'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='rahin',
    maintainer_email='darkindred456123@gmail.com',
    description='TODO: Package description',
    license='TODO: License declaration',
    extras_require={
        'test': [
            'pytest',
        ],
    },
    entry_points={
        'console_scripts': [
            'hello_publisher = train_pkg.hellp_publisher:main',
            'hello_subscriber = train_pkg.hellp_subscriber:main',
            'my_service = train_pkg.my_service:main',
            'my_client = train_pkg.my_client:main',

        ],
    },
)
